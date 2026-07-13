from __future__ import annotations

import json
from functools import lru_cache

from pydantic import BaseModel, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class LLMModelSpec(BaseModel):
    key: str
    provider: str = "openai"
    model_name: str
    input_token_price_per_million: float = Field(ge=0)
    output_token_price_per_million: float = Field(ge=0)
    max_context_tokens: int = Field(default=128_000, ge=1)
    max_output_tokens: int = Field(default=16_384, ge=1)
    supports_streaming: bool = True


class LLMSettings(BaseSettings):
    openai_api_key: str | None = None
    openai_base_url: str | None = None
    openai_organization: str | None = None
    openai_project: str | None = None

    llm_active_model_key: str = "gpt_4o_mini"
    llm_model_catalog_json: str | None = None

    llm_temperature: float = Field(default=0.2, ge=0, le=2)
    llm_top_p: float = Field(default=0.9, ge=0, le=1)
    llm_max_output_tokens: int = Field(default=1200, ge=64, le=16_384)
    llm_frequency_penalty: float = Field(default=0.0, ge=-2, le=2)
    llm_presence_penalty: float = Field(default=0.0, ge=-2, le=2)
    llm_timeout_seconds: int = Field(default=45, ge=5, le=300)
    llm_max_retries: int = Field(default=2, ge=0, le=10)
    llm_retry_backoff_seconds: float = Field(default=0.25, ge=0, le=5)
    llm_streaming_enabled: bool = True

    llm_max_context_tokens: int = Field(default=5000, ge=256, le=64_000)
    llm_context_candidate_limit: int = Field(default=6, ge=1, le=20)
    llm_max_recent_messages: int = Field(default=8, ge=0, le=30)
    llm_min_context_score: float = Field(default=0.15, ge=0, le=1)
    llm_require_citations: bool = True
    llm_sse_heartbeat_seconds: int = Field(default=15, ge=5, le=120)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("llm_model_catalog_json", mode="before")
    @classmethod
    def normalize_catalog_json(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None

    @property
    def model_catalog(self) -> list[LLMModelSpec]:
        if self.llm_model_catalog_json:
            payload = json.loads(self.llm_model_catalog_json)
            return [LLMModelSpec.model_validate(item) for item in payload]
        return [
            LLMModelSpec(
                key="gpt_4o_mini",
                provider="openai",
                model_name="gpt-4o-mini",
                input_token_price_per_million=0.15,
                output_token_price_per_million=0.60,
                max_context_tokens=128_000,
                max_output_tokens=16_384,
                supports_streaming=True,
            )
        ]

    @property
    def active_model(self) -> LLMModelSpec:
        for model in self.model_catalog:
            if model.key == self.llm_active_model_key:
                return model
        return self.model_catalog[0]


@lru_cache
def get_llm_settings() -> LLMSettings:
    return LLMSettings()
