from __future__ import annotations

import json
from functools import lru_cache
from typing import Literal

from pydantic import BaseModel, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


VectorMetric = Literal["cosine", "inner_product", "l2"]
RerankerProviderType = Literal["local_heuristic"]


class RerankerModelSpec(BaseModel):
    key: str
    provider_name: str
    provider_type: RerankerProviderType
    model_name: str
    enabled: bool = True
    metadata: dict = Field(default_factory=dict)


DEFAULT_RERANKER_SPECS: list[RerankerModelSpec] = [
    RerankerModelSpec(
        key="local_cross_encoder_heuristic_v1",
        provider_name="local",
        provider_type="local_heuristic",
        model_name="heuristic-cross-encoder-v1",
        metadata={"family": "heuristic"},
    )
]


class RetrievalSettings(BaseSettings):
    retrieval_top_k: int = Field(default=5, ge=1, le=20)
    retrieval_candidate_pool_size: int = Field(default=20, ge=5, le=100)
    retrieval_bm25_candidate_limit: int = Field(default=20, ge=5, le=100)
    retrieval_vector_candidate_limit: int = Field(default=20, ge=5, le=100)
    retrieval_similarity_threshold: float = Field(default=0.0, ge=-1.0, le=1.0)
    retrieval_vector_metric: VectorMetric = "cosine"
    retrieval_bm25_weight: float = Field(default=0.35, ge=0.0, le=2.0)
    retrieval_vector_weight: float = Field(default=0.35, ge=0.0, le=2.0)
    retrieval_metadata_weight: float = Field(default=0.15, ge=0.0, le=2.0)
    retrieval_priority_weight: float = Field(default=0.08, ge=0.0, le=2.0)
    retrieval_reranker_weight: float = Field(default=0.25, ge=0.0, le=2.0)
    retrieval_recency_weight: float = Field(default=0.04, ge=0.0, le=1.0)
    retrieval_evidence_weight: float = Field(default=0.03, ge=0.0, le=1.0)
    retrieval_priority1_sufficiency_min_results: int = Field(default=1, ge=1, le=10)
    retrieval_priority1_sufficiency_score: float = Field(default=0.55, ge=0.0, le=2.0)
    retrieval_min_query_length: int = Field(default=2, ge=1, le=10)
    retrieval_embedding_model_key: str | None = None
    retrieval_reranker_model_key: str = "local_cross_encoder_heuristic_v1"
    retrieval_reranker_catalog_json: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def reranker_catalog(self) -> list[RerankerModelSpec]:
        if self.retrieval_reranker_catalog_json:
            payload = json.loads(self.retrieval_reranker_catalog_json)
            return [RerankerModelSpec.model_validate(item) for item in payload]
        return DEFAULT_RERANKER_SPECS

    @property
    def active_reranker(self) -> RerankerModelSpec:
        for spec in self.reranker_catalog:
            if spec.key == self.retrieval_reranker_model_key:
                return spec
        raise ValueError(f"Unknown reranker model key: {self.retrieval_reranker_model_key}")

    @model_validator(mode="after")
    def validate_weights(self) -> "RetrievalSettings":
        if self.retrieval_bm25_weight + self.retrieval_vector_weight + self.retrieval_metadata_weight <= 0:
            raise ValueError("At least one retrieval signal weight must be positive.")
        self.active_reranker
        return self


@lru_cache
def get_retrieval_settings() -> RetrievalSettings:
    return RetrievalSettings()
