from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import UTC, datetime
from time import perf_counter

from baha_companion.embeddings.config import EmbeddingSettings
from baha_companion.embeddings.models import EmbeddingJob, EmbeddingModel, EmbeddingVersion
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.utils import build_retrieval_document, build_retrieval_summary, compute_content_hash

logger = logging.getLogger("baha_companion.embeddings.jobs")


@dataclass(slots=True)
class JobRunReport:
    leased_jobs: int = 0
    completed_jobs: int = 0
    failed_jobs: int = 0
    retried_jobs: int = 0
    skipped_jobs: int = 0


@dataclass(slots=True)
class PreparedEmbeddingJob:
    job: EmbeddingJob
    retrieval_summary: str
    retrieval_document: str
    content_hash: str
    source_priority: str | None
    topic: str | None
    organisation: str | None
    audience: str | None
    age_group: str | None


class EmbeddingJobRunner:
    def __init__(self, repository: EmbeddingRepository, provider, *, settings: EmbeddingSettings) -> None:
        self.repository = repository
        self.provider = provider
        self.settings = settings

    async def process_jobs(self, jobs: list[EmbeddingJob], *, model: EmbeddingModel, version: EmbeddingVersion) -> JobRunReport:
        report = JobRunReport(leased_jobs=len(jobs))
        pending_embeddings: list[PreparedEmbeddingJob] = []

        for job in jobs:
            try:
                prepared_job, outcome = await self._prepare_job(job, model=model, version=version)
            except Exception as exc:  # pragma: no cover - defensive logging path
                await self.repository.mark_job_failed(job, error_message=str(exc), retryable=True)
                report.failed_jobs += 1
                logger.exception("embedding_job_failed", extra={"details": {"job_id": str(job.id)}})
                continue
            report.skipped_jobs += int(outcome == "skipped")
            report.retried_jobs += int(outcome == "retried")
            report.failed_jobs += int(outcome == "failed")
            if prepared_job is not None:
                pending_embeddings.append(prepared_job)

        for batch_start in range(0, len(pending_embeddings), self.settings.embedding_job_batch_size):
            batch = pending_embeddings[batch_start : batch_start + self.settings.embedding_job_batch_size]
            try:
                started = perf_counter()
                vectors = await self.provider.embed_texts([item.retrieval_document for item in batch])
                embedding_time_ms = int((perf_counter() - started) * 1000)
                if len(vectors) != len(batch):
                    raise RuntimeError("Embedding provider returned an unexpected number of vectors.")
            except Exception as exc:
                for item in batch:
                    await self.repository.mark_job_failed(item.job, error_message=str(exc), retryable=True)
                    report.failed_jobs += 1
                logger.exception(
                    "embedding_batch_failed",
                    extra={"details": {"job_ids": [str(item.job.id) for item in batch]}},
                )
                continue

            for prepared_job, vector in zip(batch, vectors, strict=True):
                await self.repository.save_embedding(
                    knowledge_object_id=prepared_job.job.knowledge_object_id,
                    model=model,
                    version=version,
                    vector=vector,
                    model_name=model.model_name,
                    content_hash=prepared_job.content_hash,
                    retrieval_summary=prepared_job.retrieval_summary,
                    retrieval_document=prepared_job.retrieval_document,
                    source_priority=prepared_job.source_priority,
                    topic=prepared_job.topic,
                    organisation=prepared_job.organisation,
                    audience=prepared_job.audience,
                    age_group=prepared_job.age_group,
                    metadata={"content_schema_version": version.content_schema_version},
                )
                await self.repository.mark_job_completed(
                    prepared_job.job,
                    queue_time_ms=self._queue_time_ms(prepared_job.job),
                    embedding_time_ms=embedding_time_ms,
                    metadata={"skipped": False, "content_hash": prepared_job.content_hash},
                )
                report.completed_jobs += 1

        if report.completed_jobs:
            version.status = "active"
            version.is_current = True
        return report

    async def _prepare_job(
        self,
        job: EmbeddingJob,
        *,
        model: EmbeddingModel,
        version: EmbeddingVersion,
    ) -> tuple[PreparedEmbeddingJob | None, str]:
        if job.knowledge_object_id is None:
            await self.repository.mark_job_failed(job, error_message="Knowledge object missing from job.", retryable=False)
            return None, "failed"

        knowledge_object = await self.repository.get_knowledge_object(job.knowledge_object_id)
        if knowledge_object is None:
            await self.repository.mark_job_failed(job, error_message="Knowledge object not found.", retryable=False)
            return None, "failed"

        if not self._is_embeddable(knowledge_object):
            await self.repository.mark_job_failed(job, error_message="Knowledge object failed embedding quality checks.", retryable=False)
            return None, "failed"

        retrieval_summary = build_retrieval_summary(knowledge_object)
        retrieval_document = build_retrieval_document(knowledge_object, retrieval_summary)
        content_hash = compute_content_hash(retrieval_document)
        current_embedding = await self.repository.get_current_embedding(
            knowledge_object_id=knowledge_object.id,
            model_id=model.id,
            version_id=version.id,
        )
        if current_embedding is not None and current_embedding.content_hash == content_hash:
            await self.repository.mark_job_completed(
                job,
                queue_time_ms=self._queue_time_ms(job),
                embedding_time_ms=0,
                metadata={"skipped": True, "reason": "unchanged"},
            )
            return None, "skipped"

        primary_topic = next((item for item in knowledge_object.topics if item.is_primary), None)
        return (
            PreparedEmbeddingJob(
                job=job,
                retrieval_summary=retrieval_summary,
                retrieval_document=retrieval_document,
                content_hash=content_hash,
                source_priority=knowledge_object.details.priority_level,
                topic=primary_topic.topic if primary_topic else None,
                organisation=knowledge_object.details.organization,
                audience=knowledge_object.details.audience,
                age_group=knowledge_object.details.age_group,
            ),
            "prepared",
        )

    def _is_embeddable(self, knowledge_object) -> bool:
        if not knowledge_object.body.strip():
            return False
        if knowledge_object.quality.completeness_score < self.settings.embedding_min_completeness_score:
            return False
        if knowledge_object.quality.quality_score < self.settings.embedding_min_quality_score:
            return False
        if knowledge_object.details.duplicate_likelihood >= self.settings.embedding_duplicate_likelihood_threshold:
            return False
        return True

    def _queue_time_ms(self, job: EmbeddingJob) -> int:
        scheduled = job.scheduled_at
        if scheduled.tzinfo is None:
            scheduled = scheduled.replace(tzinfo=UTC)
        now = datetime.now(UTC)
        return max(0, int((now - scheduled).total_seconds() * 1000))
