from __future__ import annotations

from typing import Any

from baha_rag.db.repository import KnowledgeRepository


class DashboardService:
    def __init__(self, repository: KnowledgeRepository) -> None:
        self.repository = repository

    async def summary(self) -> dict[str, Any]:
        metrics = await self.repository.dashboard_metrics()
        return {
            "knowledge_analytics": {
                "documents": metrics["documents"],
                "chunks": metrics["chunks"],
            },
            "source_analytics": {
                "approved_sources_only": True,
            },
            "condition_coverage": {
                "tracked_conditions": 26,
            },
            "retrieval_quality": {
                "hybrid_enabled": True,
                "dense_retrieval": "pgvector cosine distance",
                "lexical_retrieval": "PostgreSQL full-text search",
            },
            "document_freshness": {
                "stale_documents_180_days": metrics["stale_documents"],
            },
            "embedding_statistics": {
                "embeddings": metrics["embeddings"],
            },
        }
