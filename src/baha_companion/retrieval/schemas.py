from __future__ import annotations

from datetime import date

from pydantic import Field, model_validator

from baha_companion.common.schemas import APIModel


class RetrievalFiltersInput(APIModel):
    topic: str | None = Field(default=None, max_length=128)
    subtopic: str | None = Field(default=None, max_length=128)
    age_group: str | None = Field(default=None, max_length=64)
    audience: str | None = Field(default=None, max_length=64)
    gender: str | None = Field(default=None, max_length=32)
    organisation: str | None = Field(default=None, max_length=255)
    priority: str | None = Field(default=None, max_length=32)
    evidence_level: str | None = Field(default=None, max_length=64)
    language: str | None = Field(default=None, max_length=64)
    publication_date_from: date | None = None
    publication_date_to: date | None = None
    country: str | None = Field(default=None, max_length=128)
    keywords: list[str] = Field(default_factory=list, max_length=20)


class RetrieveRequest(APIModel):
    query: str = Field(default="", max_length=1000)
    filters: RetrievalFiltersInput = Field(default_factory=RetrievalFiltersInput)
    top_k: int | None = Field(default=None, ge=1, le=20)

    model_config = {
        "json_schema_extra": {
            "example": {
                "query": "student anxiety coping strategies",
                "filters": {"audience": "student", "topic": "anxiety"},
                "top_k": 5,
            }
        }
    }

    @model_validator(mode="after")
    def validate_input(self) -> "RetrieveRequest":
        scoped_fields = [
            getattr(self, "topic", None),
            getattr(self, "audience", None),
            getattr(self, "organisation", None),
        ]
        if not self.query.strip() and not any(self.filters.model_dump().values()) and not any(scoped_fields):
            raise ValueError("Either query text or at least one filter is required.")
        return self


class RetrieveTopicRequest(RetrieveRequest):
    topic: str = Field(max_length=128)

    model_config = {
        "json_schema_extra": {"example": {"query": "student support", "topic": "anxiety", "top_k": 5}}
    }


class RetrieveAudienceRequest(RetrieveRequest):
    audience: str = Field(max_length=64)

    model_config = {
        "json_schema_extra": {"example": {"query": "coping skills", "audience": "student", "top_k": 5}}
    }


class RetrieveOrganisationRequest(RetrieveRequest):
    organisation: str = Field(max_length=255)

    model_config = {
        "json_schema_extra": {
            "example": {"query": "school stress program", "organisation": "UNICEF", "top_k": 5}
        }
    }


class QueryUnderstandingRead(APIModel):
    topic: str | None = None
    subtopic: str | None = None
    audience: str | None = None
    age_group: str | None = None
    gender: str | None = None
    organisation: str | None = None
    country: str | None = None
    evidence_level: str | None = None
    language: str | None = None
    keywords: list[str]
    intent: str | None = None


class RetrievalResultRead(APIModel):
    knowledge_object_id: str
    title: str
    summary: str
    body: str
    topic: str | None = None
    subtopic: str | None = None
    audience: str
    age_group: str
    organisation: str | None = None
    priority: str
    evidence_level: str
    publication_date: date | None = None
    country: str | None = None
    language: str | None = None
    final_score: float
    similarity_score: float
    metadata_score: float
    bm25_score: float
    vector_score: float
    priority_score: float
    reranker_score: float
    recency_bonus: float
    evidence_bonus: float


class RetrievalTimingRead(APIModel):
    query_understanding_ms: float
    bm25_ms: float
    vector_ms: float
    merge_ms: float
    rerank_ms: float
    total_ms: float


class RetrieveResponse(APIModel):
    query: str
    understanding: QueryUnderstandingRead
    filters: RetrievalFiltersInput
    items: list[RetrievalResultRead]
    top_k: int


class RetrieveDebugResponse(RetrieveResponse):
    bm25_results: list[RetrievalResultRead]
    vector_results: list[RetrievalResultRead]
    merged_results: list[RetrievalResultRead]
    reranker_results: list[RetrievalResultRead]
    timing: RetrievalTimingRead


class RetrievalStatisticsResponse(APIModel):
    total_knowledge_objects: int
    current_embedded_objects: int
    active_embedding_model_key: str
    active_reranker_model_key: str
    priority_distribution: dict[str, int]
    organisation_distribution: dict[str, int]
    topic_distribution: dict[str, int]


class BenchmarkCaseInput(APIModel):
    name: str
    query: str
    expected_ids: list[str] = Field(default_factory=list)
    expected_titles: list[str] = Field(default_factory=list)
    filters: RetrievalFiltersInput = Field(default_factory=RetrievalFiltersInput)
    top_k: int = Field(default=5, ge=1, le=20)


class BenchmarkRequest(APIModel):
    cases: list[BenchmarkCaseInput]


class BenchmarkMetricsRead(APIModel):
    precision_at_5: float
    recall_at_5: float
    mrr: float
    ndcg: float
    average_latency_ms: float
    average_similarity: float


class BenchmarkCaseRead(APIModel):
    name: str
    matched_titles: list[str]
    precision_at_5: float
    recall_at_5: float
    reciprocal_rank: float
    ndcg: float


class BenchmarkResponse(APIModel):
    metrics: BenchmarkMetricsRead
    cases: list[BenchmarkCaseRead]
