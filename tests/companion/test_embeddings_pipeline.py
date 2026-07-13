from __future__ import annotations

import argparse
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select

from baha_companion.embeddings.cli import embed_object, embed_scope, embedding_report, embedding_status
from baha_companion.embeddings.config import EmbeddingSettings
from baha_companion.embeddings.models import EmbeddingJob, EmbeddingVersion, JobState, KnowledgeEmbedding
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.service import EmbeddingService
from baha_companion.embeddings.utils import (
    build_retrieval_document,
    build_retrieval_summary,
    compute_content_hash,
    deterministic_embedding,
)
from baha_companion.knowledge.classifiers import (
    AudienceClassifier,
    AgeClassifier,
    DemographicClassifier,
    EvidenceClassifier,
    PriorityAssigner,
    ReadingLevelClassifier,
    TopicClassifier,
)
from baha_companion.knowledge.duplicates import DuplicateDetectionService
from baha_companion.knowledge.models import KnowledgeObject
from baha_companion.knowledge.normalization import KnowledgeNormalizationService
from baha_companion.knowledge.quality import QualityService
from baha_companion.knowledge.repository import KnowledgeRepository
from baha_companion.knowledge.schemas import ProcessDocumentRequest
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.service import KnowledgeProcessingService


FIXTURE_ROOT = Path("tests/fixtures/knowledge")


def build_knowledge_service(db_session) -> KnowledgeProcessingService:
    return KnowledgeProcessingService(
        KnowledgeRepository(db_session),
        workspace_root=Path.cwd(),
        normalization_service=KnowledgeNormalizationService(),
        segmentation_service=DocumentSegmentationService(),
        topic_classifier=TopicClassifier(),
        audience_classifier=AudienceClassifier(),
        age_classifier=AgeClassifier(),
        evidence_classifier=EvidenceClassifier(),
        demographic_classifier=DemographicClassifier(),
        priority_assigner=PriorityAssigner(),
        reading_level_classifier=ReadingLevelClassifier(),
        quality_service=QualityService(),
        duplicate_detection_service=DuplicateDetectionService(),
    )


def build_embedding_service(db_session, *, version: str = "v1") -> EmbeddingService:
    return EmbeddingService(
        EmbeddingRepository(db_session),
        settings=EmbeddingSettings(
            embedding_active_model_key="future_local_default",
            embedding_active_version=version,
            embedding_job_batch_size=2,
        ),
    )


async def seed_processed_knowledge(db_session) -> list[KnowledgeObject]:
    service = build_knowledge_service(db_session)
    await service.process_document(ProcessDocumentRequest(path=str(FIXTURE_ROOT / "sample.html")))
    await service.process_document(ProcessDocumentRequest(path=str(FIXTURE_ROOT / "sample.json")))
    await db_session.commit()
    result = await db_session.execute(select(KnowledgeObject).order_by(KnowledgeObject.created_at.asc()))
    return list(result.scalars().all())


async def test_embedding_utils_and_model_listing(db_session):
    knowledge_objects = await seed_processed_knowledge(db_session)
    knowledge_object = knowledge_objects[0]

    retrieval_summary = build_retrieval_summary(knowledge_object)
    retrieval_document = build_retrieval_document(knowledge_object, retrieval_summary)
    assert "Title:" in retrieval_document
    assert "Retrieval Summary:" in retrieval_document
    assert knowledge_object.title in retrieval_document

    digest = compute_content_hash(retrieval_document)
    assert digest == compute_content_hash(retrieval_document)

    vector = deterministic_embedding(retrieval_document, dimensions=16)
    assert len(vector) == 16
    assert vector == deterministic_embedding(retrieval_document, dimensions=16)

    service = build_embedding_service(db_session)
    models = await service.models()
    assert any(item["model_key"] == "future_local_default" for item in models)
    assert any(item["provider_name"] == "openai" for item in models)


async def test_embedding_queue_run_incremental_versioning_and_retry(db_session):
    knowledge_objects = await seed_processed_knowledge(db_session)
    service = build_embedding_service(db_session, version="v1")
    embeddable_object = next(
        item
        for item in knowledge_objects
        if item.quality.completeness_score >= service.settings.embedding_min_completeness_score
    )
    first_object_id = embeddable_object.id

    queue_response = await service.queue_object(knowledge_object_id=first_object_id, force=False)
    assert queue_response["queued_jobs"] == 1

    run_response = await service.run(limit=10, worker_name="unit-worker")
    assert run_response["completed_jobs"] == 1

    current_embeddings = (
        await db_session.execute(
            select(KnowledgeEmbedding).where(KnowledgeEmbedding.knowledge_object_id == first_object_id)
        )
    ).scalars().all()
    assert len(current_embeddings) == 1
    assert current_embeddings[0].is_current is True
    assert current_embeddings[0].embedding_dimension == 256

    await service.queue_object(knowledge_object_id=first_object_id, force=True)
    skipped_response = await service.run(limit=10, worker_name="unit-worker")
    assert skipped_response["skipped_jobs"] == 1

    stored_object = await service.repository.get_knowledge_object(first_object_id)
    assert stored_object is not None
    stored_object.body = f"{stored_object.body} Additional support plan for classroom follow-up."
    await db_session.flush()

    await service.queue_object(knowledge_object_id=first_object_id, force=True)
    rerun_response = await service.run(limit=10, worker_name="unit-worker")
    assert rerun_response["completed_jobs"] == 1

    updated_embeddings = (
        await db_session.execute(
            select(KnowledgeEmbedding).where(KnowledgeEmbedding.knowledge_object_id == first_object_id)
        )
    ).scalars().all()
    assert len(updated_embeddings) >= 2
    assert sum(1 for item in updated_embeddings if item.is_current) == 1

    rebuild_response = await service.rebuild(version_label="v2", topic="stress", force=True)
    assert rebuild_response["queued_jobs"] >= 1
    rebuild_run = await service.run(limit=50, worker_name="v2-worker", version_label="v2")
    assert rebuild_run["completed_jobs"] >= 1

    versions = (await db_session.execute(select(EmbeddingVersion))).scalars().all()
    assert {"v1", "v2"}.issubset({item.version_label for item in versions})

    failure_service = build_embedding_service(db_session, version="v3")
    await failure_service.queue_object(knowledge_object_id=first_object_id, force=True)

    v3_version = (
        await db_session.execute(
            select(EmbeddingVersion).where(EmbeddingVersion.version_label == "v3")
        )
    ).scalar_one()
    failed_job = (
        await db_session.execute(select(EmbeddingJob).where(EmbeddingJob.version_id == v3_version.id))
    ).scalar_one()
    failed_job.max_attempts = 1
    failed_job.scheduled_at = datetime.now(UTC)
    await db_session.flush()

    original_provider_factory = failure_service._provider_for

    class FailingProvider:
        async def embed_texts(self, texts: list[str]) -> list[list[float]]:
            raise RuntimeError(f"forced failure for {len(texts)} texts")

    failure_service._provider_for = lambda spec: FailingProvider()
    failed_run = await failure_service.run(limit=10, worker_name="fail-worker", version_label="v3")
    assert failed_run["failed_jobs"] == 1

    retried_count = await failure_service.retry_failed(limit=10)
    assert retried_count == 1

    retry_job = (
        await db_session.execute(select(EmbeddingJob).where(EmbeddingJob.state == JobState.RETRY.value))
    ).scalar_one()
    retry_job.scheduled_at = datetime.now(UTC) - timedelta(seconds=1)
    await db_session.flush()

    failure_service._provider_for = original_provider_factory
    recovered_run = await failure_service.run(limit=10, worker_name="recover-worker", version_label="v3")
    assert recovered_run["completed_jobs"] == 1


async def test_embedding_api_endpoints(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    process_response = await client.post(
        "/api/v1/process/document",
        headers=headers,
        json={"path": "tests/fixtures/knowledge/sample.html"},
    )
    assert process_response.status_code == 202

    process_json_response = await client.post(
        "/api/v1/process/document",
        headers=headers,
        json={"path": "tests/fixtures/knowledge/sample.json"},
    )
    assert process_json_response.status_code == 202

    knowledge_response = await client.get("/api/v1/knowledge?page=1&page_size=20", headers=headers)
    assert knowledge_response.status_code == 200
    items = knowledge_response.json()["items"]
    assert items
    first_item = items[0]
    knowledge_object_id = first_item["id"]

    models_response = await client.get("/api/v1/embeddings/models", headers=headers)
    assert models_response.status_code == 200
    assert models_response.json()

    queue_object_response = await client.post(
        f"/api/v1/embeddings/object/{knowledge_object_id}",
        headers=headers,
        json={},
    )
    assert queue_object_response.status_code == 202
    assert queue_object_response.json()["queued_jobs"] >= 1

    queue_topic_response = await client.post(
        "/api/v1/embeddings/topic/anxiety",
        headers=headers,
        json={"force": True},
    )
    assert queue_topic_response.status_code == 202

    queue_org_response = await client.post(
        "/api/v1/embeddings/organisation/UNICEF",
        headers=headers,
        json={"force": True},
    )
    assert queue_org_response.status_code == 202

    queue_audience_response = await client.post(
        f"/api/v1/embeddings/audience/{first_item['audience']}",
        headers=headers,
        json={"force": True},
    )
    assert queue_audience_response.status_code == 202

    queue_age_group_response = await client.post(
        f"/api/v1/embeddings/age-group/{first_item['age_group']}",
        headers=headers,
        json={"force": True},
    )
    assert queue_age_group_response.status_code == 202

    queue_all_response = await client.post(
        "/api/v1/embeddings/all",
        headers=headers,
        json={"force": True},
    )
    assert queue_all_response.status_code == 202

    run_response = await client.post(
        "/api/v1/embeddings/run",
        headers=headers,
        json={"limit": 100, "worker_name": "api-worker"},
    )
    assert run_response.status_code == 202
    run_payload = run_response.json()
    assert run_payload["completed_jobs"] + run_payload["skipped_jobs"] >= 1

    rebuild_response = await client.post(
        "/api/v1/embeddings/rebuild",
        headers=headers,
        json={"version_label": "v2", "topic": "anxiety", "force": True},
    )
    assert rebuild_response.status_code == 202

    retry_response = await client.post(
        "/api/v1/embeddings/retry",
        headers=headers,
        json={"limit": 50},
    )
    assert retry_response.status_code == 202

    status_response = await client.get("/api/v1/embeddings/status", headers=headers)
    assert status_response.status_code == 200
    assert "active_model_key" in status_response.json()

    statistics_response = await client.get("/api/v1/embeddings/statistics", headers=headers)
    assert statistics_response.status_code == 200
    assert statistics_response.json()["knowledge_objects"] >= 1


async def test_embedding_cli_commands(session_factory, db_session, monkeypatch, capsys):
    import baha_companion.embeddings.cli as embeddings_cli

    knowledge_objects = await seed_processed_knowledge(db_session)
    knowledge_object_id = knowledge_objects[0].id

    monkeypatch.setattr(embeddings_cli, "get_session_factory", lambda: session_factory)
    monkeypatch.setattr(
        embeddings_cli,
        "get_embedding_settings",
        lambda: EmbeddingSettings(
            embedding_active_model_key="future_local_default",
            embedding_active_version="v1",
            embedding_job_batch_size=2,
        ),
    )

    await embed_object(
        argparse.Namespace(
            knowledge_object_id=str(knowledge_object_id),
            version_label="v1",
            model_key="future_local_default",
            force=True,
            run=True,
            run_limit=50,
        )
    )
    object_output = capsys.readouterr().out
    assert "completed_jobs" in object_output or "queued_jobs" in object_output

    await embed_scope(
        "embed-topic",
        "anxiety",
        argparse.Namespace(
            version_label="v1",
            model_key="future_local_default",
            force=True,
            run=False,
            run_limit=50,
        ),
    )
    scope_output = capsys.readouterr().out
    assert "queued_jobs" in scope_output

    await embedding_status()
    status_output = capsys.readouterr().out
    assert "active_model_key" in status_output

    await embedding_report()
    report_output = capsys.readouterr().out
    assert "knowledge_objects" in report_output
