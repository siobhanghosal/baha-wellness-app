from __future__ import annotations

from datetime import date, datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl


Audience = Literal[
    "adolescent", "parent", "teacher", "counselor", "administrator",
    "school", "general", "research", "clinical",
]
Severity = Literal["low", "moderate", "high", "emergency", "unknown"]
EvidenceLevel = Literal["guideline", "government", "systematic_review", "peer_reviewed", "educational", "unknown"]
Perspective = Literal["parent", "teacher", "counselor", "adolescent"]


class ChunkMetadata(BaseModel):
    condition: str | None = None
    topic: str | None = None
    subtopic: str | None = None
    age_group: str = "adolescent"
    gender_group: str = "all"
    audience: Audience = "general"
    severity: Severity = "unknown"
    source: str
    country: str | None = None
    publication_date: date | None = None
    evidence_level: EvidenceLevel = "unknown"
    organization: str
    language: str = "en"


class Citation(BaseModel):
    title: str
    organization: str
    url: str | None = None
    publication_date: date | None = None
    chunk_id: UUID | None = None


class SearchRequest(BaseModel):
    query: str = Field(min_length=3, max_length=1000)
    top_k: int = Field(default=8, ge=1, le=30)
    filters: dict[str, Any] = Field(default_factory=dict)


class SearchResult(BaseModel):
    chunk_id: UUID
    document_id: UUID
    text: str
    metadata: ChunkMetadata
    citations: list[Citation]
    dense_score: float = 0.0
    lexical_score: float = 0.0
    confidence: float = 0.0


class SearchResponse(BaseModel):
    query: str
    top_k: int
    results: list[SearchResult]


class ViewRequest(BaseModel):
    condition: str = Field(min_length=2, max_length=120)
    audience: Perspective = "parent"
    age_group: str = "adolescent"
    gender_group: str = "all"
    top_k: int = Field(default=8, ge=4, le=20)


class EvidenceAnswer(BaseModel):
    perspective: Perspective
    condition: str
    what_it_is: str
    how_to_identify_it: str
    what_to_do: str
    when_to_seek_help: str
    safety_note: str
    evidence_sources: list[Citation]
    confidence: float


class ChatRequest(BaseModel):
    message: str = Field(min_length=3, max_length=1600)
    audience: Perspective = "adolescent"
    top_k: int = Field(default=8, ge=4, le=20)
    filters: dict[str, Any] = Field(default_factory=dict)


class ChatResponse(BaseModel):
    answer: EvidenceAnswer
    retrieved: list[SearchResult]


class ConditionSummary(BaseModel):
    condition: str
    category: str
    topics: list[str]


class ConditionKnowledge(BaseModel):
    condition: str
    definition: str
    symptoms: list[str] = Field(default_factory=list)
    risk_factors: list[str] = Field(default_factory=list)
    protective_factors: list[str] = Field(default_factory=list)
    parent_signs: list[str] = Field(default_factory=list)
    teacher_signs: list[str] = Field(default_factory=list)
    assessment_methods: list[str] = Field(default_factory=list)
    recommended_interventions: list[str] = Field(default_factory=list)
    classroom_support: list[str] = Field(default_factory=list)
    family_support: list[str] = Field(default_factory=list)
    escalation_indicators: list[str] = Field(default_factory=list)
    emergency_indicators: list[str] = Field(default_factory=list)
    approved_resources: list[str] = Field(default_factory=list)
    evidence_sources: list[Citation] = Field(default_factory=list)


class IngestUrlRequest(BaseModel):
    url: HttpUrl
    organization: str
    audience: Audience = "general"
    country: str | None = None
    evidence_level: EvidenceLevel = "unknown"


class IngestResponse(BaseModel):
    document_id: UUID
    url: str
    chunks_created: int
    content_hash: str
    ingested_at: datetime


class AcquisitionDiscoverRequest(BaseModel):
    organization: str | None = None
    include_research: bool = True
    limit_per_topic: int = Field(default=25, ge=1, le=100)


class AcquisitionDownloadRequest(BaseModel):
    limit: int = Field(default=100, ge=1, le=1000)


class ReviewDecisionRequest(BaseModel):
    status: Literal["approved", "rejected", "needs_changes"]
    reviewer: str = Field(min_length=2, max_length=120)
    notes: str | None = None


class AcquisitionJobResponse(BaseModel):
    status: str
    detail: dict[str, Any] = Field(default_factory=dict)
