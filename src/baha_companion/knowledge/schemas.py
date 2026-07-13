from __future__ import annotations

from datetime import date, datetime
from pathlib import Path
from uuid import UUID

from pydantic import Field, field_validator

from baha_companion.common.pagination import PaginationParams
from baha_companion.common.schemas import APIModel, PaginatedResponse


class ProcessDocumentRequest(APIModel):
    path: str = Field(description="Path to a raw document inside storage/raw.")
    organization: str | None = Field(default=None, max_length=255)
    document_url: str | None = Field(default=None, max_length=2048)
    publication_date: date | None = None
    country: str | None = Field(default=None, max_length=128)
    language: str | None = Field(default=None, max_length=64)
    overwrite: bool = False

    model_config = {
        "json_schema_extra": {
            "example": {
                "path": "storage/raw/who/sample-guideline.html",
                "organization": "WHO",
                "document_url": "https://www.who.int/example",
                "publication_date": "2025-01-01",
                "country": "Global",
                "language": "English",
                "overwrite": False,
            }
        }
    }


class ProcessBatchRequest(APIModel):
    root_path: str = Field(default="storage/raw")
    limit: int | None = Field(default=None, ge=1, le=10000)
    organization: str | None = Field(default=None, max_length=255)
    overwrite: bool = False

    model_config = {
        "json_schema_extra": {
            "example": {
                "root_path": "storage/raw",
                "limit": 100,
                "organization": "WHO",
                "overwrite": False,
            }
        }
    }


class CitationRead(APIModel):
    id: UUID
    text: str = Field(alias="citation_text")
    url: str | None = Field(default=None, alias="citation_url")
    source_title: str | None = None
    sort_order: int


class FaqRead(APIModel):
    id: UUID
    question: str
    answer: str
    sort_order: int


class ActivityRead(APIModel):
    id: UUID
    title: str
    body: str
    activity_type: str
    sort_order: int


class TopicRead(APIModel):
    id: UUID
    topic: str
    subtopic: str | None = None
    confidence: float
    is_primary: bool


class QualityRead(APIModel):
    quality_score: float
    completeness_score: float
    readability_score: float
    metadata_completeness_score: float
    duplicate_likelihood_score: float
    extraction_confidence_score: float
    reference_quality_score: float
    language_quality_score: float
    warnings: list[str]


class KnowledgeObjectRead(APIModel):
    id: UUID
    title: str
    topic: str
    subtopic: str | None = None
    summary: str
    body: str
    organization: str | None = None
    source_document: str
    document_url: str | None = None
    publication_date: date | None = None
    country: str | None = None
    language: str | None = None
    audience: str
    age_group: str
    gender: str
    evidence_level: str
    evidence_confidence: float
    clinical_review_status: str
    priority_level: str
    citations: list[CitationRead]
    activities: list[ActivityRead]
    faqs: list[FaqRead]
    keywords: list[str]
    reading_level: str
    tags: list[str]
    metadata: dict
    quality: QualityRead
    created_at: datetime
    updated_at: datetime


class KnowledgeListResponse(PaginatedResponse[KnowledgeObjectRead]):
    pass


class TopicSummary(APIModel):
    topic: str
    total: int


class KnowledgeTopicsResponse(APIModel):
    items: list[TopicSummary]


class QualityListItem(APIModel):
    id: UUID
    title: str
    topic: str
    quality_score: float
    warnings: list[str]
    source_document: str


class KnowledgeQualityResponse(APIModel):
    items: list[QualityListItem]
    average_quality_score: float
    below_threshold_count: int


class KnowledgeStatisticsResponse(APIModel):
    total_knowledge_objects: int
    topic_distribution: dict[str, int]
    audience_distribution: dict[str, int]
    age_distribution: dict[str, int]
    priority_distribution: dict[str, int]
    quality_distribution: dict[str, int]


class ProcessedObjectResult(APIModel):
    id: UUID | None = None
    title: str
    topic: str
    source_document: str
    duplicate_of: UUID | None = None
    quality_score: float | None = None


class ProcessDocumentResponse(APIModel):
    document_path: str
    processed: bool
    duplicates_removed: int
    knowledge_objects_created: int
    objects: list[ProcessedObjectResult]


class ProcessBatchResponse(APIModel):
    documents_processed: int
    knowledge_objects_created: int
    duplicates_removed: int
    topics_discovered: list[str]
    audience_distribution: dict[str, int]
    age_distribution: dict[str, int]
    priority_distribution: dict[str, int]
    quality_distribution: dict[str, int]


class KnowledgeQueryFilters(APIModel):
    topic: str | None = None
    audience: str | None = None
    age_group: str | None = None
    organization: str | None = None
    priority_level: str | None = None
    evidence_level: str | None = None
    min_quality_score: float | None = Field(default=None, ge=0, le=100)
    sort_by: str = Field(default="updated_at", pattern="^(updated_at|publication_date|quality_score|title)$")
    sort_direction: str = Field(default="desc", pattern="^(asc|desc)$")

    @field_validator("topic", "audience", "age_group", "organization", "priority_level", "evidence_level", mode="before")
    @classmethod
    def normalize_filter(cls, value: str | None) -> str | None:
        return value.strip().lower() if isinstance(value, str) and value.strip() else None


def pagination_to_schema(pagination: PaginationParams, filters: KnowledgeQueryFilters) -> dict:
    return {"pagination": pagination.model_dump(), "filters": filters.model_dump()}


def path_example(path: Path) -> str:
    return str(path)

