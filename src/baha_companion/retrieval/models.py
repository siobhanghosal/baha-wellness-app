from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from typing import Any
from uuid import UUID


@dataclass(slots=True)
class QueryUnderstanding:
    topic: str | None = None
    subtopic: str | None = None
    audience: str | None = None
    age_group: str | None = None
    gender: str | None = None
    organisation: str | None = None
    country: str | None = None
    evidence_level: str | None = None
    language: str | None = None
    keywords: list[str] = field(default_factory=list)
    intent: str | None = None


@dataclass(slots=True)
class RetrievalFilters:
    topic: str | None = None
    subtopic: str | None = None
    age_group: str | None = None
    audience: str | None = None
    gender: str | None = None
    organisation: str | None = None
    priority: str | None = None
    evidence_level: str | None = None
    language: str | None = None
    publication_date_from: date | None = None
    publication_date_to: date | None = None
    country: str | None = None
    keywords: list[str] = field(default_factory=list)

    def has_any(self) -> bool:
        return any(
            value
            for value in (
                self.topic,
                self.subtopic,
                self.age_group,
                self.audience,
                self.gender,
                self.organisation,
                self.priority,
                self.evidence_level,
                self.language,
                self.publication_date_from,
                self.publication_date_to,
                self.country,
                self.keywords,
            )
        )


@dataclass(slots=True)
class RetrievalCandidate:
    knowledge_object_id: UUID
    title: str
    summary: str
    body: str
    topic: str | None
    subtopic: str | None
    audience: str
    age_group: str
    gender: str
    organisation: str | None
    priority: str
    evidence_level: str
    publication_date: date | None
    country: str | None
    language: str | None
    keywords: list[str]
    retrieval_summary: str
    retrieval_document: str
    similarity_score: float = 0.0
    metadata_score: float = 0.0
    bm25_score: float = 0.0
    vector_score: float = 0.0
    priority_score: float = 0.0
    recency_bonus: float = 0.0
    evidence_bonus: float = 0.0
    reranker_score: float = 0.0
    final_score: float = 0.0
    embedding_vector: list[float] | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class BenchmarkCase:
    name: str
    query: str
    expected_ids: list[str] = field(default_factory=list)
    expected_titles: list[str] = field(default_factory=list)
    filters: RetrievalFilters = field(default_factory=RetrievalFilters)
    top_k: int = 5
