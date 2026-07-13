from __future__ import annotations

from collections import Counter
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import Select, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from baha_companion.embeddings.config import EmbeddingModelSpec
from baha_companion.embeddings.models import (
    EmbeddingJob,
    EmbeddingModel,
    EmbeddingStatistics,
    EmbeddingVersion,
    JobState,
    KnowledgeEmbedding,
    VersionStatus,
)
from baha_companion.knowledge.models import KnowledgeMetadata, KnowledgeObject, KnowledgeQuality, KnowledgeTopic


class EmbeddingRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def ensure_model(self, spec: EmbeddingModelSpec, *, active: bool) -> EmbeddingModel:
        if active:
            active_models = await self.session.execute(select(EmbeddingModel).where(EmbeddingModel.is_active.is_(True)))
            for active_model in active_models.scalars().all():
                active_model.is_active = active_model.model_key == spec.key
        result = await self.session.execute(select(EmbeddingModel).where(EmbeddingModel.model_key == spec.key))
        model = result.scalar_one_or_none()
        if model is None:
            model = EmbeddingModel(
                model_key=spec.key,
                provider_name=spec.provider_name,
                provider_type=spec.provider_type,
                model_name=spec.model_name,
                dimensions=spec.dimensions,
                is_active=active,
                config={"api_base": spec.api_base, **spec.metadata},
            )
            self.session.add(model)
            await self.session.flush()
            await self.session.refresh(model)
        else:
            model.provider_name = spec.provider_name
            model.provider_type = spec.provider_type
            model.model_name = spec.model_name
            model.dimensions = spec.dimensions
            model.is_active = active
            model.config = {"api_base": spec.api_base, **spec.metadata}
            await self.session.flush()
            await self.session.refresh(model)
        return model

    async def ensure_version(
        self,
        *,
        model: EmbeddingModel,
        version_label: str,
        content_schema_version: str,
        activate: bool,
    ) -> EmbeddingVersion:
        if activate:
            versions = await self.session.execute(
                select(EmbeddingVersion).where(EmbeddingVersion.model_id == model.id, EmbeddingVersion.is_current.is_(True))
            )
            for item in versions.scalars().all():
                item.is_current = item.version_label == version_label
        result = await self.session.execute(
            select(EmbeddingVersion).where(
                EmbeddingVersion.model_id == model.id,
                EmbeddingVersion.version_label == version_label,
            )
        )
        version = result.scalar_one_or_none()
        if version is None:
            version = EmbeddingVersion(
                model_id=model.id,
                version_label=version_label,
                content_schema_version=content_schema_version,
                status=VersionStatus.BUILDING.value,
                is_current=activate,
                metadata_={},
            )
            self.session.add(version)
            await self.session.flush()
            await self.session.refresh(version)
        else:
            version.content_schema_version = content_schema_version
            version.is_current = activate
            await self.session.flush()
            await self.session.refresh(version)
        return version

    async def list_models_with_usage(self) -> list[dict]:
        usage_rows = await self.session.execute(
            select(EmbeddingModel.model_key, func.count(KnowledgeEmbedding.id))
            .join(KnowledgeEmbedding, KnowledgeEmbedding.model_id == EmbeddingModel.id, isouter=True)
            .group_by(EmbeddingModel.model_key)
        )
        return [{"model_key": model_key, "usage_count": total} for model_key, total in usage_rows]

    async def list_recent_jobs(self, *, limit: int = 20) -> list[EmbeddingJob]:
        result = await self.session.execute(
            select(EmbeddingJob).order_by(EmbeddingJob.created_at.desc()).limit(limit)
        )
        return list(result.scalars().all())

    async def enqueue_jobs(
        self,
        *,
        knowledge_object_ids: list[UUID],
        model: EmbeddingModel,
        version: EmbeddingVersion,
        job_type: str,
        scope_key: str,
        scope_value: str | None,
        force: bool,
        max_attempts: int,
    ) -> int:
        queued = 0
        for knowledge_object_id in knowledge_object_ids:
            if not force:
                existing = await self.session.execute(
                    select(EmbeddingJob).where(
                        EmbeddingJob.knowledge_object_id == knowledge_object_id,
                        EmbeddingJob.model_id == model.id,
                        EmbeddingJob.version_id == version.id,
                        EmbeddingJob.state.in_(
                            [
                                JobState.PENDING.value,
                                JobState.PROCESSING.value,
                                JobState.RETRY.value,
                            ]
                        ),
                    )
                )
                if existing.scalar_one_or_none() is not None:
                    continue
            job = EmbeddingJob(
                knowledge_object_id=knowledge_object_id,
                model_id=model.id,
                version_id=version.id,
                job_type=job_type,
                state=JobState.PENDING.value,
                scope_key=scope_key,
                scope_value=scope_value,
                attempts=0,
                max_attempts=max_attempts,
                priority=100,
                scheduled_at=datetime.now(UTC),
                metadata_={},
            )
            self.session.add(job)
            queued += 1
        await self.session.flush()
        return queued

    async def lease_jobs(
        self,
        *,
        worker_name: str,
        limit: int,
        lease_seconds: int,
        model_id: UUID,
        version_id: UUID,
    ) -> list[EmbeddingJob]:
        now = datetime.now(UTC)
        stmt: Select[tuple[EmbeddingJob]] = (
            select(EmbeddingJob)
            .where(
                EmbeddingJob.model_id == model_id,
                EmbeddingJob.version_id == version_id,
                or_(EmbeddingJob.state == JobState.PENDING.value, EmbeddingJob.state == JobState.RETRY.value),
                or_(EmbeddingJob.lease_expires_at.is_(None), EmbeddingJob.lease_expires_at < now),
                EmbeddingJob.scheduled_at <= now,
            )
            .order_by(EmbeddingJob.priority.asc(), EmbeddingJob.created_at.asc())
            .limit(limit)
        )
        result = await self.session.execute(stmt)
        jobs = list(result.scalars().all())
        for job in jobs:
            job.state = JobState.PROCESSING.value
            job.started_at = now
            job.lease_expires_at = now + timedelta(seconds=lease_seconds)
            job.leased_by = worker_name
            job.attempts += 1
        await self.session.flush()
        return jobs

    async def mark_job_completed(
        self,
        job: EmbeddingJob,
        *,
        queue_time_ms: int,
        embedding_time_ms: int,
        metadata: dict,
    ) -> EmbeddingJob:
        job.state = JobState.COMPLETED.value
        job.completed_at = datetime.now(UTC)
        job.queue_time_ms = queue_time_ms
        job.embedding_time_ms = embedding_time_ms
        job.error_message = None
        job.metadata_ = metadata
        job.lease_expires_at = None
        await self.session.flush()
        return job

    async def mark_job_failed(self, job: EmbeddingJob, *, error_message: str, retryable: bool) -> EmbeddingJob:
        now = datetime.now(UTC)
        if retryable and job.attempts < job.max_attempts:
            job.state = JobState.RETRY.value
            job.scheduled_at = now + timedelta(seconds=min(60, job.attempts * 5))
        else:
            job.state = JobState.FAILED.value
            job.failed_at = now
        job.error_message = error_message[:2000]
        job.lease_expires_at = None
        await self.session.flush()
        return job

    async def retry_failed_jobs(self, *, limit: int) -> int:
        result = await self.session.execute(
            select(EmbeddingJob)
            .where(EmbeddingJob.state == JobState.FAILED.value)
            .order_by(EmbeddingJob.failed_at.asc())
            .limit(limit)
        )
        jobs = list(result.scalars().all())
        now = datetime.now(UTC)
        for job in jobs:
            job.state = JobState.RETRY.value
            job.failed_at = None
            job.scheduled_at = now
            job.error_message = None
        await self.session.flush()
        return len(jobs)

    async def get_knowledge_object(self, knowledge_object_id: UUID) -> KnowledgeObject | None:
        stmt = (
            select(KnowledgeObject)
            .where(KnowledgeObject.id == knowledge_object_id)
            .options(
                selectinload(KnowledgeObject.topics),
                selectinload(KnowledgeObject.keywords),
                selectinload(KnowledgeObject.citations),
                selectinload(KnowledgeObject.faqs),
                selectinload(KnowledgeObject.activities),
                selectinload(KnowledgeObject.details),
                selectinload(KnowledgeObject.quality),
            )
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_current_embedding(
        self,
        *,
        knowledge_object_id: UUID,
        model_id: UUID,
        version_id: UUID,
    ) -> KnowledgeEmbedding | None:
        result = await self.session.execute(
            select(KnowledgeEmbedding).where(
                KnowledgeEmbedding.knowledge_object_id == knowledge_object_id,
                KnowledgeEmbedding.model_id == model_id,
                KnowledgeEmbedding.version_id == version_id,
                KnowledgeEmbedding.is_current.is_(True),
            )
        )
        return result.scalar_one_or_none()

    async def get_any_current_embedding(self, *, knowledge_object_id: UUID, model_id: UUID) -> KnowledgeEmbedding | None:
        result = await self.session.execute(
            select(KnowledgeEmbedding).where(
                KnowledgeEmbedding.knowledge_object_id == knowledge_object_id,
                KnowledgeEmbedding.model_id == model_id,
                KnowledgeEmbedding.is_current.is_(True),
            )
        )
        return result.scalar_one_or_none()

    async def save_embedding(
        self,
        *,
        knowledge_object_id: UUID,
        model: EmbeddingModel,
        version: EmbeddingVersion,
        vector: list[float],
        model_name: str,
        content_hash: str,
        retrieval_summary: str,
        retrieval_document: str,
        source_priority: str | None,
        topic: str | None,
        organisation: str | None,
        audience: str | None,
        age_group: str | None,
        metadata: dict,
    ) -> KnowledgeEmbedding:
        current = await self.get_any_current_embedding(knowledge_object_id=knowledge_object_id, model_id=model.id)
        if current is not None:
            current.is_current = False
            current.status = "superseded"

        embedding = KnowledgeEmbedding(
            knowledge_object_id=knowledge_object_id,
            model_id=model.id,
            version_id=version.id,
            embedding_vector=vector,
            model_name=model_name,
            embedding_dimension=len(vector),
            status="active",
            retrieval_summary=retrieval_summary,
            retrieval_document=retrieval_document,
            content_hash=content_hash,
            source_priority=source_priority,
            topic=topic,
            organisation=organisation,
            audience=audience,
            age_group=age_group,
            is_current=True,
            metadata_=metadata,
        )
        self.session.add(embedding)
        await self.session.flush()
        await self.session.refresh(embedding)
        return embedding

    async def list_knowledge_object_ids(
        self,
        *,
        topic: str | None = None,
        organisation: str | None = None,
        audience: str | None = None,
        age_group: str | None = None,
    ) -> list[UUID]:
        stmt = (
            select(KnowledgeObject.id)
            .join(KnowledgeMetadata, KnowledgeMetadata.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeQuality, KnowledgeQuality.knowledge_object_id == KnowledgeObject.id)
        )
        if topic:
            stmt = stmt.join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id).where(
                func.lower(KnowledgeTopic.topic) == topic.lower(),
                KnowledgeTopic.is_primary.is_(True),
            )
        if organisation:
            stmt = stmt.where(func.lower(KnowledgeMetadata.organization) == organisation.lower())
        if audience:
            stmt = stmt.where(func.lower(KnowledgeMetadata.audience) == audience.lower())
        if age_group:
            stmt = stmt.where(func.lower(KnowledgeMetadata.age_group) == age_group.lower())
        result = await self.session.execute(stmt)
        return [row[0] for row in result.all()]

    async def status_counts(self) -> dict[str, int]:
        result = await self.session.execute(
            select(EmbeddingJob.state, func.count(EmbeddingJob.id)).group_by(EmbeddingJob.state)
        )
        counts = {state: count for state, count in result}
        return {
            JobState.PENDING.value: counts.get(JobState.PENDING.value, 0),
            JobState.PROCESSING.value: counts.get(JobState.PROCESSING.value, 0),
            JobState.COMPLETED.value: counts.get(JobState.COMPLETED.value, 0),
            JobState.FAILED.value: counts.get(JobState.FAILED.value, 0),
            JobState.CANCELLED.value: counts.get(JobState.CANCELLED.value, 0),
            JobState.RETRY.value: counts.get(JobState.RETRY.value, 0),
        }

    async def build_statistics_payload(self) -> dict:
        knowledge_objects = int((await self.session.execute(select(func.count(KnowledgeObject.id)))).scalar_one())
        embedded_objects = int(
            (
                await self.session.execute(
                    select(func.count(func.distinct(KnowledgeEmbedding.knowledge_object_id))).where(
                        KnowledgeEmbedding.is_current.is_(True)
                    )
                )
            ).scalar_one()
        )
        status_counts = await self.status_counts()
        time_rows = await self.session.execute(
            select(EmbeddingJob.queue_time_ms, EmbeddingJob.embedding_time_ms).where(
                EmbeddingJob.state == JobState.COMPLETED.value
            )
        )
        queue_times: list[int] = []
        embedding_times: list[int] = []
        for queue_time_ms, embedding_time_ms in time_rows:
            if queue_time_ms is not None:
                queue_times.append(queue_time_ms)
            if embedding_time_ms is not None:
                embedding_times.append(embedding_time_ms)

        model_usage_rows = await self.session.execute(
            select(EmbeddingModel.model_key, func.count(KnowledgeEmbedding.id))
            .join(KnowledgeEmbedding, KnowledgeEmbedding.model_id == EmbeddingModel.id, isouter=True)
            .group_by(EmbeddingModel.model_key)
        )
        version_rows = await self.session.execute(
            select(EmbeddingVersion.version_label, func.count(KnowledgeEmbedding.id))
            .join(KnowledgeEmbedding, KnowledgeEmbedding.version_id == EmbeddingVersion.id, isouter=True)
            .group_by(EmbeddingVersion.version_label)
        )
        distribution_rows = await self.session.execute(
            select(
                KnowledgeEmbedding.organisation,
                KnowledgeEmbedding.topic,
                KnowledgeEmbedding.source_priority,
            ).where(KnowledgeEmbedding.is_current.is_(True))
        )
        organisation_counter: Counter[str] = Counter()
        topic_counter: Counter[str] = Counter()
        priority_counter: Counter[str] = Counter()
        for organisation, topic, source_priority in distribution_rows:
            organisation_counter[organisation or "unknown"] += 1
            topic_counter[topic or "unknown"] += 1
            priority_counter[source_priority or "unknown"] += 1

        return {
            "knowledge_objects": knowledge_objects,
            "embedded_objects": embedded_objects,
            "pending": status_counts[JobState.PENDING.value],
            "processing": status_counts[JobState.PROCESSING.value],
            "failed": status_counts[JobState.FAILED.value],
            "average_queue_time_ms": round(sum(queue_times) / len(queue_times), 2) if queue_times else 0.0,
            "average_embedding_time_ms": round(sum(embedding_times) / len(embedding_times), 2) if embedding_times else 0.0,
            "embedding_model_usage": {key: total for key, total in model_usage_rows},
            "embedding_versions": {key: total for key, total in version_rows},
            "organisation_distribution": dict(organisation_counter),
            "topic_distribution": dict(topic_counter),
            "priority_distribution": dict(priority_counter),
        }

    async def record_statistics(self, *, model_id: UUID | None, version_id: UUID | None, payload: dict) -> EmbeddingStatistics:
        statistic = EmbeddingStatistics(
            model_id=model_id,
            version_id=version_id,
            knowledge_objects=payload["knowledge_objects"],
            embedded_objects=payload["embedded_objects"],
            pending_jobs=payload["pending"],
            processing_jobs=payload["processing"],
            failed_jobs=payload["failed"],
            average_embedding_time_ms=payload["average_embedding_time_ms"],
            average_queue_time_ms=payload["average_queue_time_ms"],
            model_usage=payload["embedding_model_usage"],
            embedding_versions=payload["embedding_versions"],
            organisation_distribution=payload["organisation_distribution"],
            topic_distribution=payload["topic_distribution"],
            priority_distribution=payload["priority_distribution"],
            metadata_={},
        )
        self.session.add(statistic)
        await self.session.flush()
        return statistic
