from __future__ import annotations

from baha_companion.embeddings.models import EmbeddingJob, EmbeddingModel, EmbeddingVersion
from baha_companion.embeddings.repository import EmbeddingRepository


class EmbeddingJobQueue:
    def __init__(self, repository: EmbeddingRepository) -> None:
        self.repository = repository

    async def enqueue(
        self,
        *,
        knowledge_object_ids,
        model: EmbeddingModel,
        version: EmbeddingVersion,
        job_type: str,
        scope_key: str,
        scope_value: str | None,
        force: bool,
        max_attempts: int,
    ) -> int:
        return await self.repository.enqueue_jobs(
            knowledge_object_ids=list(knowledge_object_ids),
            model=model,
            version=version,
            job_type=job_type,
            scope_key=scope_key,
            scope_value=scope_value,
            force=force,
            max_attempts=max_attempts,
        )

    async def lease(self, *, worker_name: str, limit: int, lease_seconds: int, model: EmbeddingModel, version: EmbeddingVersion) -> list[EmbeddingJob]:
        return await self.repository.lease_jobs(
            worker_name=worker_name,
            limit=limit,
            lease_seconds=lease_seconds,
            model_id=model.id,
            version_id=version.id,
        )
