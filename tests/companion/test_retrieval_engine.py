from __future__ import annotations

import argparse
import json
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

from baha_companion.embeddings.config import EmbeddingSettings
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.service import EmbeddingService
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
from baha_companion.knowledge.normalization import KnowledgeNormalizationService
from baha_companion.knowledge.quality import QualityService
from baha_companion.knowledge.repository import KnowledgeRepository
from baha_companion.knowledge.schemas import ProcessDocumentRequest
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.service import KnowledgeProcessingService
from baha_companion.retrieval.cli import (
    build_parser,
    run_benchmark,
    run_retrieve,
    run_retrieve_organisation,
    run_retrieve_topic,
)
from baha_companion.retrieval.config import RetrievalSettings
from baha_companion.retrieval.models import BenchmarkCase, RetrievalFilters
from baha_companion.retrieval.repository import RetrievalRepository
from baha_companion.retrieval.statistics import ndcg_at_k, precision_at_k, recall_at_k, reciprocal_rank
from baha_companion.retrieval import utils as retrieval_utils
from baha_companion.retrieval.service import RetrievalService


WORKSPACE_ROOT = Path.cwd()
SEED_ROOT = WORKSPACE_ROOT / "storage" / "test_retrieval"


def build_knowledge_service(db_session) -> KnowledgeProcessingService:
    return KnowledgeProcessingService(
        KnowledgeRepository(db_session),
        workspace_root=WORKSPACE_ROOT,
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


def build_embedding_service(db_session) -> EmbeddingService:
    return EmbeddingService(
        EmbeddingRepository(db_session),
        settings=EmbeddingSettings(
            embedding_active_model_key="future_local_default",
            embedding_active_version="v1",
            embedding_job_batch_size=4,
        ),
    )


def build_retrieval_service(db_session) -> RetrievalService:
    return RetrievalService(
        RetrievalRepository(db_session),
        retrieval_settings=RetrievalSettings(
            retrieval_top_k=5,
            retrieval_candidate_pool_size=20,
            retrieval_embedding_model_key="future_local_default",
        ),
        embedding_settings=EmbeddingSettings(
            embedding_active_model_key="future_local_default",
            embedding_active_version="v1",
        ),
    )


def write_seed_file(relative_path: str, content: str) -> str:
    path = SEED_ROOT / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return str(path.relative_to(WORKSPACE_ROOT))


async def seed_retrieval_corpus(db_session) -> None:
    service = build_knowledge_service(db_session)
    nimhans_html = write_seed_file(
        "nimhans_anxiety.html",
        (
            "<html><head><title>Student Anxiety Support Guidance</title></head><body>"
            "<h1>Student Anxiety Support Guidance</h1>"
            "<p>Anxiety in students can affect concentration and sleep.</p>"
            "<h2>Activities</h2><p>Practice breathing and journaling after school.</p>"
            "<p>NIMHANS guidance for Indian students includes school-based support plans.</p>"
            "</body></html>"
        ),
    )
    who_html = write_seed_file(
        "who_anxiety.html",
        (
            "<html><head><title>Student Anxiety Support Guidance</title></head><body>"
            "<h1>Student Anxiety Support Guidance</h1>"
            "<p>Anxiety in students can affect concentration and sleep.</p>"
            "<h2>Activities</h2><p>Practice breathing and journaling after school.</p>"
            "<p>WHO global guidance summarises adolescent anxiety support across countries.</p>"
            "</body></html>"
        ),
    )
    unicef_json = write_seed_file(
        "unicef_stress.json",
        json.dumps(
            {
                "title": "School Stress Support Program",
                "organization": "UNICEF",
                "publication_date": "2025-02-01",
                "url": "https://www.unicef.org/stress-program",
                "topic": "stress",
                "subtopic": "academic stress",
                "abstract": (
                    "<p>Students can learn stress management through breathing, peer support, and routines.</p>"
                ),
                "methods": "Educational guidance for students and teachers.",
                "conclusion": "Structured routines improve emotional regulation.",
                "language": "English",
                "country": "India",
            }
        ),
    )

    await service.process_document(
        ProcessDocumentRequest(
            path=nimhans_html,
            organization="NIMHANS",
            country="India",
            language="English",
        )
    )
    await service.process_document(
        ProcessDocumentRequest(
            path=who_html,
            organization="WHO",
            country="Global",
            language="English",
        )
    )
    await service.process_document(
        ProcessDocumentRequest(
            path=unicef_json,
            organization="UNICEF",
            country="India",
            language="English",
        )
    )
    await db_session.commit()

    embedding_service = build_embedding_service(db_session)
    await embedding_service.queue_all(force=True)
    await embedding_service.run(limit=100, worker_name="retrieval-seed-worker")
    await db_session.commit()


async def test_retrieval_service_hybrid_priority_filters_debug_and_benchmark(db_session):
    await seed_retrieval_corpus(db_session)
    service = build_retrieval_service(db_session)

    response = await service.retrieve(
        query="student anxiety support in india",
        filters=RetrievalFilters(topic="anxiety"),
        top_k=5,
        debug=True,
    )
    assert response["items"]
    assert response["items"][0]["organisation"] == "NIMHANS"
    assert response["items"][0]["topic"] == "anxiety"
    assert response["bm25_results"]
    assert response["vector_results"]
    assert response["reranker_results"]
    assert response["timing"]["total_ms"] >= 0

    filtered = await service.retrieve(
        query="",
        filters=RetrievalFilters(organisation="UNICEF"),
        top_k=5,
    )
    assert filtered["items"]
    assert all(item["organisation"] == "UNICEF" for item in filtered["items"])

    benchmark = await service.benchmark(
        cases=[
            BenchmarkCase(
                name="anxiety_priority",
                query="student anxiety support",
                expected_titles=["Student Anxiety Support Guidance"],
                filters=RetrievalFilters(topic="anxiety"),
            ),
            BenchmarkCase(
                name="stress_topic",
                query="school stress support",
                expected_titles=["School Stress Support Program"],
                filters=RetrievalFilters(topic="stress"),
            ),
        ]
    )
    assert benchmark["metrics"]["precision_at_5"] > 0
    assert len(benchmark["cases"]) == 2


async def test_retrieval_api_endpoints(client, registered_user_tokens, db_session):
    await seed_retrieval_corpus(db_session)
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    retrieve_response = await client.post(
        "/api/v1/retrieve",
        headers=headers,
        json={"query": "student anxiety support in india", "filters": {"topic": "anxiety"}, "top_k": 5},
    )
    assert retrieve_response.status_code == 200
    assert retrieve_response.json()["items"][0]["organisation"] == "NIMHANS"

    debug_response = await client.post(
        "/api/v1/retrieve/debug",
        headers=headers,
        json={"query": "student anxiety support", "filters": {"topic": "anxiety"}, "top_k": 5},
    )
    assert debug_response.status_code == 200
    assert debug_response.json()["bm25_results"]

    topic_response = await client.post(
        "/api/v1/retrieve/topic",
        headers=headers,
        json={"topic": "stress", "query": "school support", "top_k": 5},
    )
    assert topic_response.status_code == 200
    assert all(item["topic"] == "stress" for item in topic_response.json()["items"])

    audience_response = await client.post(
        "/api/v1/retrieve/audience",
        headers=headers,
        json={"audience": "student", "query": "breathing routine", "top_k": 5},
    )
    assert audience_response.status_code == 200
    assert audience_response.json()["items"]

    organisation_response = await client.post(
        "/api/v1/retrieve/organisation",
        headers=headers,
        json={"organisation": "UNICEF", "query": "stress program", "top_k": 5},
    )
    assert organisation_response.status_code == 200
    assert all(item["organisation"] == "UNICEF" for item in organisation_response.json()["items"])

    statistics_response = await client.get("/api/v1/retrieve/statistics", headers=headers)
    assert statistics_response.status_code == 200
    assert statistics_response.json()["current_embedded_objects"] >= 1


async def test_retrieval_cli_commands(session_factory, db_session, monkeypatch, tmp_path, capsys):
    import baha_companion.retrieval.cli as retrieval_cli

    await seed_retrieval_corpus(db_session)

    monkeypatch.setattr(retrieval_cli, "get_session_factory", lambda: session_factory)
    monkeypatch.setattr(
        retrieval_cli,
        "get_retrieval_settings",
        lambda: RetrievalSettings(
            retrieval_top_k=5,
            retrieval_candidate_pool_size=20,
            retrieval_embedding_model_key="future_local_default",
        ),
    )
    monkeypatch.setattr(
        retrieval_cli,
        "get_embedding_settings",
        lambda: EmbeddingSettings(
            embedding_active_model_key="future_local_default",
            embedding_active_version="v1",
        ),
    )

    await run_retrieve(
        argparse.Namespace(
            query="student anxiety support",
            top_k=5,
            topic="anxiety",
            audience=None,
            organisation=None,
        )
    )
    retrieve_output = capsys.readouterr().out
    assert "NIMHANS" in retrieve_output

    await run_retrieve(
        argparse.Namespace(
            query="student anxiety support",
            top_k=5,
            topic="anxiety",
            audience=None,
            organisation=None,
        ),
        debug=True,
    )
    debug_output = capsys.readouterr().out
    assert "bm25_results" in debug_output

    await run_retrieve_topic(argparse.Namespace(topic="stress", query="school support", top_k=5))
    topic_output = capsys.readouterr().out
    assert "School Stress Support Program" in topic_output

    await run_retrieve_organisation(
        argparse.Namespace(organisation="UNICEF", query="stress program", top_k=5)
    )
    organisation_output = capsys.readouterr().out
    assert "UNICEF" in organisation_output

    benchmark_file = tmp_path / "retrieval_benchmark.json"
    benchmark_file.write_text(
        json.dumps(
            {
                "cases": [
                    {
                        "name": "anxiety_priority",
                        "query": "student anxiety support",
                        "expected_titles": ["Student Anxiety Support Guidance"],
                        "filters": {"topic": "anxiety"},
                        "top_k": 5,
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    await run_benchmark(argparse.Namespace(case_file=str(benchmark_file)))
    benchmark_output = capsys.readouterr().out
    assert "precision_at_5" in benchmark_output


async def test_retrieval_repository_utilities_and_benchmark_route(client, registered_user_tokens, db_session, monkeypatch):
    import baha_companion.retrieval.cli as retrieval_cli

    await seed_retrieval_corpus(db_session)
    repository = RetrievalRepository(db_session)

    stress_candidates = await repository.list_candidates(
        filters=RetrievalFilters(topic="stress"),
        model_key=None,
    )
    assert len(stress_candidates) == 1
    stress_candidate = stress_candidates[0]

    filtered_candidates = await repository.list_candidates(
        filters=RetrievalFilters(
            topic=stress_candidate.topic,
            subtopic=stress_candidate.subtopic,
            audience=stress_candidate.audience,
            age_group=stress_candidate.age_group,
            gender=stress_candidate.gender,
            organisation=stress_candidate.organisation,
            priority=stress_candidate.priority,
            evidence_level=stress_candidate.evidence_level,
            language=stress_candidate.language,
            country=stress_candidate.country,
            publication_date_from=stress_candidate.publication_date - timedelta(days=1),
            publication_date_to=stress_candidate.publication_date + timedelta(days=1),
        ),
        model_key="future_local_default",
    )
    assert len(filtered_candidates) == 1

    repository_stats = await repository.statistics(model_key=None)
    assert repository_stats["total_knowledge_objects"] >= 1
    assert repository_stats["current_embedded_objects"] >= 1

    assert precision_at_k([True, False, True], k=0) == 0.0
    assert recall_at_k([True, False], k=2, total_relevant=0) == 0.0
    assert reciprocal_rank([False, False]) == 0.0
    assert ndcg_at_k([False, False], k=2) == 0.0

    assert retrieval_utils.normalize_text("  Hello World  ") == "hello world"
    assert retrieval_utils.normalize_score_map({"a": 0.0, "b": 0.0}) == {"a": 0.0, "b": 0.0}
    assert retrieval_utils.normalize_score_map({"a": 1.0, "b": 1.0}) == {"a": 1.0, "b": 1.0}
    assert retrieval_utils.cosine_similarity([0.0], [1.0]) == 0.0
    assert retrieval_utils.inner_product([1.0, 2.0], [3.0, 4.0]) == 11.0
    assert retrieval_utils.l2_similarity([0.0], [0.0]) == 1.0
    assert retrieval_utils.similarity("inner_product", [1.0], [2.0]) == 2.0
    assert retrieval_utils.similarity("l2", [0.0], [1.0]) == 0.5
    assert retrieval_utils.organization_priority(None, "priority_2") == "priority_2"
    assert retrieval_utils.organization_priority("Unknown Org", None) == "unknown"
    assert retrieval_utils.priority_score("NIMHANS", None) == 1.0
    assert retrieval_utils.evidence_score("not_real") == 0.3
    assert retrieval_utils.recency_score(None) == 0.0
    assert retrieval_utils.recency_score(date.today(), now=datetime.now(UTC)) == 1.0
    assert retrieval_utils.recency_score(date.today() - timedelta(days=370), now=datetime.now(UTC)) == 0.8
    assert retrieval_utils.recency_score(date.today() - timedelta(days=900), now=datetime.now(UTC)) == 0.5
    assert retrieval_utils.recency_score(date.today() - timedelta(days=3000), now=datetime.now(UTC)) == 0.2
    assert retrieval_utils.jaccard_similarity([], ["a"]) == 0.0
    assert retrieval_utils.title_case_match([], "Title") == 0.0

    parser = build_parser()
    assert parser.parse_args(["retrieve", "anxiety help"]).command == "retrieve"
    assert parser.parse_args(["retrieve-debug", "anxiety help"]).command == "retrieve-debug"
    assert parser.parse_args(["retrieve-topic", "anxiety"]).command == "retrieve-topic"
    assert parser.parse_args(["retrieve-organisation", "WHO"]).command == "retrieve-organisation"
    assert parser.parse_args(["retrieve-benchmark", "cases.json"]).command == "retrieve-benchmark"

    recorded: list[str] = []

    def fake_run_retrieve(args, *, debug=False):
        return f"retrieve:{debug}:{args.command}"

    def fake_run_retrieve_topic(args):
        return f"topic:{args.command}"

    def fake_run_retrieve_organisation(args):
        return f"organisation:{args.command}"

    def fake_run_benchmark(args):
        return f"benchmark:{args.command}"

    class DummyParser:
        def __init__(self, namespace):
            self._namespace = namespace

        def parse_args(self):
            return self._namespace

    def fake_asyncio_run(coro):
        recorded.append(coro)

    monkeypatch.setattr(retrieval_cli, "run_retrieve", fake_run_retrieve)
    monkeypatch.setattr(retrieval_cli, "run_retrieve_topic", fake_run_retrieve_topic)
    monkeypatch.setattr(retrieval_cli, "run_retrieve_organisation", fake_run_retrieve_organisation)
    monkeypatch.setattr(retrieval_cli, "run_benchmark", fake_run_benchmark)
    monkeypatch.setattr(retrieval_cli.asyncio, "run", fake_asyncio_run)

    for command in (
        argparse.Namespace(command="retrieve"),
        argparse.Namespace(command="retrieve-debug"),
        argparse.Namespace(command="retrieve-topic"),
        argparse.Namespace(command="retrieve-organisation"),
        argparse.Namespace(command="retrieve-benchmark"),
    ):
        monkeypatch.setattr(retrieval_cli, "build_parser", lambda command=command: DummyParser(command))
        retrieval_cli.main()

    assert recorded == [
        "retrieve:False:retrieve",
        "retrieve:True:retrieve-debug",
        "topic:retrieve-topic",
        "organisation:retrieve-organisation",
        "benchmark:retrieve-benchmark",
    ]

    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}
    benchmark_response = await client.post(
        "/api/v1/retrieve/benchmark",
        headers=headers,
        json={
            "cases": [
                {
                    "name": "anxiety_priority",
                    "query": "student anxiety support",
                    "expected_titles": ["Student Anxiety Support Guidance"],
                    "filters": {"topic": "anxiety"},
                    "top_k": 5,
                }
            ]
        },
    )
    assert benchmark_response.status_code == 200
    assert benchmark_response.json()["metrics"]["precision_at_5"] > 0
