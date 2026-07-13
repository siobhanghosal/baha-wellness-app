from __future__ import annotations

from dataclasses import asdict
from time import perf_counter
from uuid import UUID

from baha_companion.common.exceptions import ValidationError
from baha_companion.embeddings.config import EmbeddingSettings
from baha_companion.embeddings.service import DeterministicEmbeddingProvider, OpenAICompatibleProvider
from baha_companion.retrieval.bm25 import BM25Document, BM25Scorer
from baha_companion.retrieval.config import RetrievalSettings
from baha_companion.retrieval.models import BenchmarkCase, QueryUnderstanding, RetrievalCandidate, RetrievalFilters
from baha_companion.retrieval.query_understanding import QueryUnderstandingService
from baha_companion.retrieval.reranker import HeuristicCrossEncoderProvider
from baha_companion.retrieval.repository import RetrievalRepository
from baha_companion.retrieval.statistics import ndcg_at_k, precision_at_k, recall_at_k, reciprocal_rank
from baha_companion.retrieval.utils import (
    evidence_score,
    normalize_score_map,
    priority_score,
    recency_score,
    similarity,
)


class RetrievalService:
    def __init__(
        self,
        repository: RetrievalRepository,
        *,
        retrieval_settings: RetrievalSettings,
        embedding_settings: EmbeddingSettings,
    ) -> None:
        self.repository = repository
        self.retrieval_settings = retrieval_settings
        self.embedding_settings = embedding_settings
        self.query_understanding = QueryUnderstandingService()
        self.bm25 = BM25Scorer()

    async def retrieve(
        self,
        *,
        query: str,
        filters: RetrievalFilters,
        top_k: int | None = None,
        debug: bool = False,
    ) -> dict:
        started = perf_counter()
        effective_query = query.strip()
        if not effective_query and not filters.has_any():
            raise ValidationError("Query text or at least one filter is required.")

        understanding_started = perf_counter()
        understanding = self.query_understanding.analyze(effective_query)
        merged_filters = self._merge_filters(filters, understanding)
        understanding_ms = round((perf_counter() - understanding_started) * 1000, 2)

        model_key = self.retrieval_settings.retrieval_embedding_model_key or self.embedding_settings.active_model.key
        candidates = await self.repository.list_candidates(filters=merged_filters, model_key=model_key)

        bm25_started = perf_counter()
        bm25_results = self._score_bm25(effective_query, candidates)
        bm25_ms = round((perf_counter() - bm25_started) * 1000, 2)

        vector_started = perf_counter()
        vector_results = await self._score_vector(effective_query, candidates, model_key=model_key)
        vector_ms = round((perf_counter() - vector_started) * 1000, 2)

        merge_started = perf_counter()
        merged_results = self._merge_candidates(
            candidates=candidates,
            understanding=understanding,
            bm25_results=bm25_results,
            vector_results=vector_results,
        )
        merge_ms = round((perf_counter() - merge_started) * 1000, 2)

        rerank_started = perf_counter()
        reranked_results = await self._rerank(effective_query, merged_results)
        rerank_ms = round((perf_counter() - rerank_started) * 1000, 2)

        top_results = self._finalize_results(reranked_results, top_k=top_k or self.retrieval_settings.retrieval_top_k)
        total_ms = round((perf_counter() - started) * 1000, 2)

        response = {
            "query": effective_query,
            "understanding": asdict(understanding),
            "filters": self._serialize_filters(merged_filters),
            "items": [self._serialize_candidate(item) for item in top_results],
            "top_k": top_k or self.retrieval_settings.retrieval_top_k,
        }
        if debug:
            response.update(
                {
                    "bm25_results": [self._serialize_candidate(item) for item in bm25_results],
                    "vector_results": [self._serialize_candidate(item) for item in vector_results],
                    "merged_results": [self._serialize_candidate(item) for item in merged_results],
                    "reranker_results": [self._serialize_candidate(item) for item in reranked_results],
                    "timing": {
                        "query_understanding_ms": understanding_ms,
                        "bm25_ms": bm25_ms,
                        "vector_ms": vector_ms,
                        "merge_ms": merge_ms,
                        "rerank_ms": rerank_ms,
                        "total_ms": total_ms,
                    },
                }
            )
        return response

    async def retrieve_by_topic(self, *, topic: str, query: str, top_k: int | None = None) -> dict:
        return await self.retrieve(query=query, filters=RetrievalFilters(topic=topic), top_k=top_k)

    async def retrieve_by_audience(self, *, audience: str, query: str, top_k: int | None = None) -> dict:
        return await self.retrieve(query=query, filters=RetrievalFilters(audience=audience), top_k=top_k)

    async def retrieve_by_organisation(
        self,
        *,
        organisation: str,
        query: str,
        top_k: int | None = None,
    ) -> dict:
        return await self.retrieve(query=query, filters=RetrievalFilters(organisation=organisation), top_k=top_k)

    async def statistics(self) -> dict:
        model_key = self.retrieval_settings.retrieval_embedding_model_key or self.embedding_settings.active_model.key
        payload = await self.repository.statistics(model_key=model_key)
        payload["active_embedding_model_key"] = model_key
        payload["active_reranker_model_key"] = self.retrieval_settings.active_reranker.key
        return payload

    async def benchmark(self, *, cases: list[BenchmarkCase]) -> dict:
        case_results: list[dict] = []
        precision_values: list[float] = []
        recall_values: list[float] = []
        mrr_values: list[float] = []
        ndcg_values: list[float] = []
        latency_values: list[float] = []
        similarity_values: list[float] = []

        for case in cases:
            started = perf_counter()
            response = await self.retrieve(
                query=case.query,
                filters=case.filters,
                top_k=case.top_k,
            )
            latency_values.append(round((perf_counter() - started) * 1000, 2))

            returned_items = response["items"]
            expected_ids = set(case.expected_ids)
            expected_titles = {item.lower() for item in case.expected_titles}
            relevant = [
                item["knowledge_object_id"] in expected_ids or item["title"].lower() in expected_titles
                for item in returned_items
            ]
            total_relevant = max(1, len(expected_ids) or len(expected_titles))
            precision = precision_at_k(relevant, k=min(5, len(returned_items) or 5))
            recall = recall_at_k(relevant, k=min(5, len(returned_items) or 5), total_relevant=total_relevant)
            rr = reciprocal_rank(relevant)
            ndcg = ndcg_at_k(relevant, k=min(5, len(returned_items) or 5))
            average_similarity = round(
                sum(item["similarity_score"] for item in returned_items) / len(returned_items),
                4,
            ) if returned_items else 0.0

            precision_values.append(precision)
            recall_values.append(recall)
            mrr_values.append(rr)
            ndcg_values.append(ndcg)
            similarity_values.append(average_similarity)
            case_results.append(
                {
                    "name": case.name,
                    "matched_titles": [item["title"] for item, is_relevant in zip(returned_items, relevant) if is_relevant],
                    "precision_at_5": precision,
                    "recall_at_5": recall,
                    "reciprocal_rank": rr,
                    "ndcg": ndcg,
                }
            )

        return {
            "metrics": {
                "precision_at_5": round(sum(precision_values) / len(precision_values), 4) if precision_values else 0.0,
                "recall_at_5": round(sum(recall_values) / len(recall_values), 4) if recall_values else 0.0,
                "mrr": round(sum(mrr_values) / len(mrr_values), 4) if mrr_values else 0.0,
                "ndcg": round(sum(ndcg_values) / len(ndcg_values), 4) if ndcg_values else 0.0,
                "average_latency_ms": round(sum(latency_values) / len(latency_values), 2) if latency_values else 0.0,
                "average_similarity": round(sum(similarity_values) / len(similarity_values), 4)
                if similarity_values
                else 0.0,
            },
            "cases": case_results,
        }

    def _merge_filters(self, filters: RetrievalFilters, understanding: QueryUnderstanding) -> RetrievalFilters:
        if filters.has_any():
            return RetrievalFilters(
                topic=filters.topic,
                subtopic=filters.subtopic,
                age_group=filters.age_group,
                audience=filters.audience,
                gender=filters.gender,
                organisation=filters.organisation,
                priority=filters.priority,
                evidence_level=filters.evidence_level,
                language=filters.language,
                publication_date_from=filters.publication_date_from,
                publication_date_to=filters.publication_date_to,
                country=filters.country,
                keywords=list(dict.fromkeys(filters.keywords)),
            )
        return RetrievalFilters(
            topic=filters.topic or understanding.topic,
            subtopic=filters.subtopic or understanding.subtopic,
            age_group=filters.age_group or understanding.age_group,
            audience=filters.audience or understanding.audience,
            gender=filters.gender or understanding.gender,
            organisation=filters.organisation or understanding.organisation,
            priority=filters.priority,
            evidence_level=filters.evidence_level or understanding.evidence_level,
            language=filters.language or understanding.language,
            publication_date_from=filters.publication_date_from,
            publication_date_to=filters.publication_date_to,
            country=filters.country or understanding.country,
            keywords=list(dict.fromkeys([*filters.keywords, *understanding.keywords])),
        )

    def _score_bm25(self, query: str, candidates: list[RetrievalCandidate]) -> list[RetrievalCandidate]:
        documents = [
            BM25Document(
                knowledge_object_id=item.knowledge_object_id,
                title=item.title,
                topic=item.topic,
                keywords=item.keywords,
                retrieval_summary=item.retrieval_summary,
                body=item.body,
            )
            for item in candidates
        ]
        raw_scores = self.bm25.score_documents(query, documents)
        normalized = normalize_score_map(raw_scores)
        bm25_results = []
        for item in candidates:
            score = normalized.get(str(item.knowledge_object_id), 0.0)
            if score <= 0:
                continue
            clone = self._clone_candidate(item)
            clone.bm25_score = score
            bm25_results.append(clone)
        return sorted(bm25_results, key=lambda candidate: candidate.bm25_score, reverse=True)[
            : self.retrieval_settings.retrieval_bm25_candidate_limit
        ]

    async def _score_vector(
        self,
        query: str,
        candidates: list[RetrievalCandidate],
        *,
        model_key: str,
    ) -> list[RetrievalCandidate]:
        if len(query.strip()) < self.retrieval_settings.retrieval_min_query_length:
            return []

        vector_candidates = [item for item in candidates if item.embedding_vector]
        if not vector_candidates:
            return []

        provider = self._embedding_provider(model_key)
        query_vector = (await provider.embed_texts([query]))[0]
        raw_scores = {
            str(item.knowledge_object_id): similarity(
                self.retrieval_settings.retrieval_vector_metric,
                query_vector,
                item.embedding_vector or [],
            )
            for item in vector_candidates
        }
        normalized = normalize_score_map(raw_scores)
        results = []
        for item in vector_candidates:
            score = normalized.get(str(item.knowledge_object_id), 0.0)
            if score < self.retrieval_settings.retrieval_similarity_threshold:
                continue
            clone = self._clone_candidate(item)
            clone.vector_score = score
            clone.similarity_score = score
            results.append(clone)
        return sorted(results, key=lambda candidate: candidate.vector_score, reverse=True)[
            : self.retrieval_settings.retrieval_vector_candidate_limit
        ]

    def _merge_candidates(
        self,
        *,
        candidates: list[RetrievalCandidate],
        understanding: QueryUnderstanding,
        bm25_results: list[RetrievalCandidate],
        vector_results: list[RetrievalCandidate],
    ) -> list[RetrievalCandidate]:
        score_map: dict[UUID, RetrievalCandidate] = {}
        bm25_map = {item.knowledge_object_id: item.bm25_score for item in bm25_results}
        vector_map = {item.knowledge_object_id: item.vector_score for item in vector_results}

        for candidate in candidates:
            clone = self._clone_candidate(candidate)
            clone.metadata_score = self._metadata_score(candidate, understanding)
            clone.bm25_score = bm25_map.get(candidate.knowledge_object_id, 0.0)
            clone.vector_score = vector_map.get(candidate.knowledge_object_id, 0.0)
            clone.similarity_score = clone.vector_score
            clone.priority_score = priority_score(candidate.organisation, candidate.priority)
            clone.recency_bonus = recency_score(candidate.publication_date)
            clone.evidence_bonus = evidence_score(candidate.evidence_level)
            clone.final_score = round(
                (clone.metadata_score * self.retrieval_settings.retrieval_metadata_weight)
                + (clone.bm25_score * self.retrieval_settings.retrieval_bm25_weight)
                + (clone.vector_score * self.retrieval_settings.retrieval_vector_weight)
                + (clone.priority_score * self.retrieval_settings.retrieval_priority_weight)
                + (clone.recency_bonus * self.retrieval_settings.retrieval_recency_weight)
                + (clone.evidence_bonus * self.retrieval_settings.retrieval_evidence_weight),
                6,
            )
            if clone.final_score > 0:
                score_map[candidate.knowledge_object_id] = clone

        return sorted(score_map.values(), key=lambda candidate: candidate.final_score, reverse=True)[
            : self.retrieval_settings.retrieval_candidate_pool_size
        ]

    async def _rerank(self, query: str, candidates: list[RetrievalCandidate]) -> list[RetrievalCandidate]:
        provider = HeuristicCrossEncoderProvider(self.retrieval_settings.active_reranker)
        reranker_query = query or " ".join(filter(None, [candidates[0].topic if candidates else None]))
        reranker_scores = normalize_score_map(await provider.rerank(reranker_query, candidates))
        reranked = []
        for candidate in candidates:
            clone = self._clone_candidate(candidate)
            clone.reranker_score = reranker_scores.get(str(candidate.knowledge_object_id), 0.0)
            clone.final_score = round(
                candidate.final_score
                + (clone.reranker_score * self.retrieval_settings.retrieval_reranker_weight),
                6,
            )
            reranked.append(clone)
        return sorted(reranked, key=lambda candidate: candidate.final_score, reverse=True)

    def _finalize_results(self, candidates: list[RetrievalCandidate], *, top_k: int) -> list[RetrievalCandidate]:
        priority_1 = [
            candidate
            for candidate in candidates
            if candidate.priority_score >= 1.0
        ]
        strong_priority_1 = [
            candidate
            for candidate in priority_1
            if candidate.final_score >= self.retrieval_settings.retrieval_priority1_sufficiency_score
        ]
        if len(strong_priority_1) >= self.retrieval_settings.retrieval_priority1_sufficiency_min_results:
            ordered_candidates = sorted(priority_1, key=lambda candidate: candidate.final_score, reverse=True) + [
                candidate for candidate in candidates if candidate.priority_score < 1.0
            ]
        else:
            ordered_candidates = candidates

        final: list[RetrievalCandidate] = []
        seen: set[UUID] = set()
        for candidate in ordered_candidates:
            if candidate.knowledge_object_id in seen:
                continue
            final.append(candidate)
            seen.add(candidate.knowledge_object_id)
            if len(final) == top_k:
                break
        return final

    def _metadata_score(self, candidate: RetrievalCandidate, understanding: QueryUnderstanding) -> float:
        checks = [
            (understanding.topic, candidate.topic),
            (understanding.audience, candidate.audience),
            (understanding.age_group, candidate.age_group),
            (understanding.gender, candidate.gender),
            (understanding.organisation, candidate.organisation),
            (understanding.country, candidate.country),
            (understanding.evidence_level, candidate.evidence_level),
            (understanding.language, candidate.language),
        ]
        requested = sum(1 for expected, _actual in checks if expected)
        if requested == 0:
            return 0.0
        matched = sum(
            1
            for expected, actual in checks
            if expected and actual and expected.lower() == actual.lower()
        )
        return round(matched / requested, 6)

    def _embedding_provider(self, model_key: str):
        spec = next(
            (
                item
                for item in self.embedding_settings.model_catalog
                if item.key == model_key
            ),
            self.embedding_settings.active_model,
        )
        spec = self.embedding_settings._hydrate_model_spec(spec)
        if spec.provider_type == "local_deterministic":
            return DeterministicEmbeddingProvider(dimensions=spec.dimensions)
        return OpenAICompatibleProvider(spec=spec, settings=self.embedding_settings)

    def _serialize_candidate(self, candidate: RetrievalCandidate) -> dict:
        return {
            "knowledge_object_id": str(candidate.knowledge_object_id),
            "title": candidate.title,
            "summary": candidate.summary,
            "body": candidate.body,
            "topic": candidate.topic,
            "subtopic": candidate.subtopic,
            "audience": candidate.audience,
            "age_group": candidate.age_group,
            "organisation": candidate.organisation,
            "priority": candidate.priority,
            "evidence_level": candidate.evidence_level,
            "publication_date": candidate.publication_date,
            "country": candidate.country,
            "language": candidate.language,
            "final_score": round(candidate.final_score, 6),
            "similarity_score": round(candidate.similarity_score, 6),
            "metadata_score": round(candidate.metadata_score, 6),
            "bm25_score": round(candidate.bm25_score, 6),
            "vector_score": round(candidate.vector_score, 6),
            "priority_score": round(candidate.priority_score, 6),
            "reranker_score": round(candidate.reranker_score, 6),
            "recency_bonus": round(candidate.recency_bonus, 6),
            "evidence_bonus": round(candidate.evidence_bonus, 6),
        }

    def _serialize_filters(self, filters: RetrievalFilters) -> dict:
        return {
            "topic": filters.topic,
            "subtopic": filters.subtopic,
            "age_group": filters.age_group,
            "audience": filters.audience,
            "gender": filters.gender,
            "organisation": filters.organisation,
            "priority": filters.priority,
            "evidence_level": filters.evidence_level,
            "language": filters.language,
            "publication_date_from": filters.publication_date_from,
            "publication_date_to": filters.publication_date_to,
            "country": filters.country,
            "keywords": filters.keywords,
        }

    def _clone_candidate(self, candidate: RetrievalCandidate) -> RetrievalCandidate:
        return RetrievalCandidate(
            knowledge_object_id=candidate.knowledge_object_id,
            title=candidate.title,
            summary=candidate.summary,
            body=candidate.body,
            topic=candidate.topic,
            subtopic=candidate.subtopic,
            audience=candidate.audience,
            age_group=candidate.age_group,
            gender=candidate.gender,
            organisation=candidate.organisation,
            priority=candidate.priority,
            evidence_level=candidate.evidence_level,
            publication_date=candidate.publication_date,
            country=candidate.country,
            language=candidate.language,
            keywords=list(candidate.keywords),
            retrieval_summary=candidate.retrieval_summary,
            retrieval_document=candidate.retrieval_document,
            similarity_score=candidate.similarity_score,
            metadata_score=candidate.metadata_score,
            bm25_score=candidate.bm25_score,
            vector_score=candidate.vector_score,
            priority_score=candidate.priority_score,
            recency_bonus=candidate.recency_bonus,
            evidence_bonus=candidate.evidence_bonus,
            reranker_score=candidate.reranker_score,
            final_score=candidate.final_score,
            embedding_vector=list(candidate.embedding_vector) if candidate.embedding_vector else None,
            metadata=dict(candidate.metadata),
        )
