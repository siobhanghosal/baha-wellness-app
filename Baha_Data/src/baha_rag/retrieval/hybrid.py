from __future__ import annotations

from collections import defaultdict
from datetime import date
import re
from typing import Any

from baha_rag.acquisition.campaign import source_weight
from baha_rag.db.repository import KnowledgeRepository
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.retrieval.bm25 import BM25Scorer
from baha_rag.schemas import SearchResult


class HybridRetriever:
    def __init__(self, repository: KnowledgeRepository, embeddings: EmbeddingService) -> None:
        self.repository = repository
        self.embeddings = embeddings

    async def search(self, query: str, *, top_k: int, filters: dict[str, Any]) -> list[SearchResult]:
        query_embedding = self.embeddings.embed_query(query)
        graph = await self.repository.graph_context(
            query_embedding=query_embedding,
            top_k=max(12, top_k),
        )
        dense = await self.repository.dense_search(
            query_embedding=query_embedding,
            top_k=top_k * 2,
            filters=filters,
        )
        lexical_candidates = await self.repository.lexical_search(
            query=query,
            top_k=top_k * 4,
            filters=filters,
        )
        lexical = BM25Scorer().rank(query, lexical_candidates)[: top_k * 2]
        fused = self._weighted_rerank(
            query=query,
            dense=dense,
            lexical=lexical,
            graph_context=graph,
        )
        return self._unique_documents(fused)[:top_k]

    def _weighted_rerank(
        self,
        *,
        query: str,
        dense: list[SearchResult],
        lexical: list[SearchResult],
        graph_context: dict[str, Any],
    ) -> list[SearchResult]:
        by_id: dict[str, SearchResult] = {}
        for result in dense + lexical:
            key = str(result.chunk_id)
            if key not in by_id:
                by_id[key] = result
            else:
                by_id[key].dense_score = max(by_id[key].dense_score, result.dense_score)
                by_id[key].lexical_score = max(by_id[key].lexical_score, result.lexical_score)
        if not by_id:
            return []
        max_lexical = max((result.lexical_score for result in by_id.values()), default=0.0)
        query_terms = self._terms(query)
        graph_terms = self._terms(" ".join(graph_context.get("terms", [])))
        today = date.today()
        for result in by_id.values():
            semantic = max(0.0, min(1.0, result.dense_score))
            authority = source_weight(result.metadata.organization)
            metadata_terms = self._terms(
                " ".join(
                    value
                    for value in (
                        result.metadata.condition,
                        result.metadata.topic,
                        result.metadata.subtopic,
                    )
                    if value
                )
            )
            direct = len(query_terms & metadata_terms) / max(len(query_terms), 1)
            graph_match = len(metadata_terms & graph_terms) / max(len(metadata_terms), 1)
            lexical = (
                result.lexical_score / max_lexical if max_lexical > 0 else 0.0
            )
            condition_relevance = min(1.0, direct * 0.5 + graph_match * 0.25 + lexical * 0.25)
            publication_date = result.citations[0].publication_date if result.citations else None
            if publication_date:
                age_years = max((today - publication_date).days / 365.25, 0)
                recency = max(0.2, 1.0 - age_years / 20.0)
            else:
                recency = 0.5
            result.confidence = round(
                0.40 * semantic
                + 0.30 * authority
                + 0.20 * condition_relevance
                + 0.10 * recency,
                4,
            )
        return sorted(by_id.values(), key=lambda item: item.confidence, reverse=True)

    def _terms(self, value: str) -> set[str]:
        return {
            token
            for token in re.findall(r"[a-z0-9]+", value.lower())
            if len(token) > 2
        }

    def _unique_documents(self, results: list[SearchResult]) -> list[SearchResult]:
        unique: list[SearchResult] = []
        seen: set[str] = set()
        for result in results:
            document_id = str(result.document_id)
            if document_id in seen:
                continue
            seen.add(document_id)
            unique.append(result)
        return unique

    def _reciprocal_rank_fusion(
        self,
        *,
        dense: list[SearchResult],
        lexical: list[SearchResult],
        rank_constant: int = 60,
    ) -> list[SearchResult]:
        by_id: dict[str, SearchResult] = {}
        fused_scores: defaultdict[str, float] = defaultdict(float)

        for rank, result in enumerate(dense, start=1):
            key = str(result.chunk_id)
            by_id[key] = result
            fused_scores[key] += (
                1.0 / (rank_constant + rank)
            ) * source_weight(result.metadata.organization)

        for rank, result in enumerate(lexical, start=1):
            key = str(result.chunk_id)
            if key in by_id:
                by_id[key].lexical_score = max(by_id[key].lexical_score, result.lexical_score)
            else:
                by_id[key] = result
            fused_scores[key] += (
                1.0 / (rank_constant + rank)
            ) * source_weight(result.metadata.organization)

        if not fused_scores:
            return []

        max_score = max(fused_scores.values())
        results = []
        for key, result in by_id.items():
            result.confidence = round(fused_scores[key] / max_score, 4)
            results.append(result)
        return sorted(results, key=lambda item: item.confidence, reverse=True)
