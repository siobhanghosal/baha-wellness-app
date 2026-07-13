from __future__ import annotations

import json
import os
from functools import lru_cache
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


ProviderType = Literal["openai", "openai_compatible", "local_http", "local_deterministic"]


class EmbeddingModelSpec(BaseModel):
    key: str
    provider_name: str
    provider_type: ProviderType
    model_name: str
    dimensions: int = Field(gt=0)
    api_base: str | None = None
    api_key_env: str | None = None
    enabled: bool = True
    metadata: dict = Field(default_factory=dict)

    @field_validator("key", "provider_name", "model_name")
    @classmethod
    def strip_fields(cls, value: str) -> str:
        return value.strip()


DEFAULT_MODEL_SPECS: list[EmbeddingModelSpec] = [
    EmbeddingModelSpec(
        key="openai_text_embedding_3_small",
        provider_name="openai",
        provider_type="openai",
        model_name="text-embedding-3-small",
        dimensions=1536,
        api_base="https://api.openai.com/v1",
        api_key_env="OPENAI_API_KEY",
        metadata={"family": "text-embedding-3"},
    ),
    EmbeddingModelSpec(
        key="openai_text_embedding_3_large",
        provider_name="openai",
        provider_type="openai",
        model_name="text-embedding-3-large",
        dimensions=3072,
        api_base="https://api.openai.com/v1",
        api_key_env="OPENAI_API_KEY",
        metadata={"family": "text-embedding-3"},
    ),
    EmbeddingModelSpec(
        key="baai_bge_large",
        provider_name="baai",
        provider_type="local_http",
        model_name="BAAI/bge-large-en-v1.5",
        dimensions=1024,
        api_key_env="LOCAL_EMBEDDING_API_KEY",
        metadata={"family": "bge"},
    ),
    EmbeddingModelSpec(
        key="baai_bge_base",
        provider_name="baai",
        provider_type="local_http",
        model_name="BAAI/bge-base-en-v1.5",
        dimensions=768,
        api_key_env="LOCAL_EMBEDDING_API_KEY",
        metadata={"family": "bge"},
    ),
    EmbeddingModelSpec(
        key="nomic_embed",
        provider_name="nomic",
        provider_type="openai_compatible",
        model_name="nomic-embed-text-v1.5",
        dimensions=768,
        api_key_env="NOMIC_API_KEY",
        metadata={"family": "nomic"},
    ),
    EmbeddingModelSpec(
        key="jina_embeddings",
        provider_name="jina",
        provider_type="openai_compatible",
        model_name="jina-embeddings-v3",
        dimensions=1024,
        api_key_env="JINA_API_KEY",
        metadata={"family": "jina"},
    ),
    EmbeddingModelSpec(
        key="future_local_default",
        provider_name="local",
        provider_type="local_deterministic",
        model_name="future-local-default",
        dimensions=256,
        metadata={"family": "future_local"},
    ),
]


class EmbeddingSettings(BaseSettings):
    embedding_active_model_key: str = "future_local_default"
    embedding_active_version: str = "v1"
    embedding_content_schema_version: str = "knowledge_v1"
    embedding_job_max_attempts: int = Field(default=3, ge=1, le=10)
    embedding_job_batch_size: int = Field(default=32, ge=1, le=512)
    embedding_worker_lease_seconds: int = Field(default=120, ge=15)
    embedding_duplicate_likelihood_threshold: float = Field(default=0.8, ge=0, le=1)
    embedding_min_completeness_score: float = Field(default=0.6, ge=0, le=1)
    embedding_min_quality_score: float = Field(default=60.0, ge=0, le=100)
    embedding_model_catalog_json: str | None = None
    openai_api_key: str | None = None
    openai_api_base: str = "https://api.openai.com/v1"
    local_embedding_api_base: str | None = None
    local_embedding_api_key: str | None = None
    nomic_api_key: str | None = None
    nomic_api_base: str | None = None
    jina_api_key: str | None = None
    jina_api_base: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def model_catalog(self) -> list[EmbeddingModelSpec]:
        if self.embedding_model_catalog_json:
            payload = json.loads(self.embedding_model_catalog_json)
            return [EmbeddingModelSpec.model_validate(item) for item in payload]
        return DEFAULT_MODEL_SPECS

    @property
    def active_model(self) -> EmbeddingModelSpec:
        for spec in self.model_catalog:
            if spec.key == self.embedding_active_model_key:
                return self._hydrate_model_spec(spec)
        raise ValueError(f"Unknown embedding model key: {self.embedding_active_model_key}")

    def api_key_for(self, spec: EmbeddingModelSpec) -> str | None:
        if spec.provider_type == "openai":
            return self.openai_api_key
        if spec.provider_name == "nomic":
            return self.nomic_api_key
        if spec.provider_name == "jina":
            return self.jina_api_key
        if spec.provider_type == "local_http":
            return self.local_embedding_api_key
        if spec.api_key_env:
            return os.getenv(spec.api_key_env)
        return None

    def api_base_for(self, spec: EmbeddingModelSpec) -> str | None:
        if spec.provider_type == "openai":
            return self.openai_api_base or spec.api_base
        if spec.provider_name == "nomic":
            return self.nomic_api_base or spec.api_base
        if spec.provider_name == "jina":
            return self.jina_api_base or spec.api_base
        if spec.provider_type == "local_http":
            return self.local_embedding_api_base or spec.api_base
        return spec.api_base

    def _hydrate_model_spec(self, spec: EmbeddingModelSpec) -> EmbeddingModelSpec:
        return spec.model_copy(
            update={
                "api_base": self.api_base_for(spec),
                "metadata": {
                    **spec.metadata,
                    "api_key_configured": bool(self.api_key_for(spec)),
                },
            }
        )

    @model_validator(mode="after")
    def validate_active_model(self) -> "EmbeddingSettings":
        self.active_model
        return self


@lru_cache
def get_embedding_settings() -> EmbeddingSettings:
    return EmbeddingSettings()

