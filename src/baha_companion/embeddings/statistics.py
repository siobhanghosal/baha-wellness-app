from __future__ import annotations

from baha_companion.embeddings.repository import EmbeddingRepository


class EmbeddingStatisticsService:
    def __init__(self, repository: EmbeddingRepository) -> None:
        self.repository = repository

    async def snapshot(self, *, model_id=None, version_id=None) -> dict:
        payload = await self.repository.build_statistics_payload()
        await self.repository.record_statistics(model_id=model_id, version_id=version_id, payload=payload)
        return payload

