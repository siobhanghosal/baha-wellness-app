from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from baha_companion.retrieval.config import RerankerModelSpec
from baha_companion.retrieval.models import RetrievalCandidate
from baha_companion.retrieval.utils import jaccard_similarity, significant_terms, title_case_match, tokenize


class RerankerProvider(Protocol):
    async def rerank(self, query: str, candidates: list[RetrievalCandidate]) -> dict[str, float]: ...


@dataclass(slots=True)
class HeuristicCrossEncoderProvider:
    spec: RerankerModelSpec

    async def rerank(self, query: str, candidates: list[RetrievalCandidate]) -> dict[str, float]:
        query_terms = significant_terms(query, limit=16)
        query_token_set = tokenize(query)
        scores: dict[str, float] = {}
        for candidate in candidates:
            candidate_terms = significant_terms(
                " ".join(
                    [
                        candidate.title,
                        candidate.retrieval_summary,
                        " ".join(candidate.keywords),
                        candidate.body[:600],
                    ]
                ),
                limit=40,
            )
            lexical = jaccard_similarity(query_terms, candidate_terms)
            title_overlap = title_case_match(query_terms, candidate.title)
            summary_overlap = jaccard_similarity(query_token_set, tokenize(candidate.retrieval_summary))
            scores[str(candidate.knowledge_object_id)] = round(
                (lexical * 0.45) + (title_overlap * 0.35) + (summary_overlap * 0.20),
                6,
            )
        return scores
