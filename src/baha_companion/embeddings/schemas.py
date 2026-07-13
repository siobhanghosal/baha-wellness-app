from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import Field

from baha_companion.common.schemas import APIModel


class EmbeddingEnqueueRequest(APIModel):
    version_label: str | None = Field(default=None, max_length=32)
    model_key: str | None = Field(default=None, max_length=128)
    force: bool = False

    model_config = {
        "json_schema_extra": {
            "example": {
                "version_label": "v1",
                "model_key": "future_local_default",
                "force": False,
            }
        }
    }


class EmbeddingRunRequest(APIModel):
    version_label: str | None = Field(default=None, max_length=32)
    model_key: str | None = Field(default=None, max_length=128)
    limit: int = Field(default=100, ge=1, le=5000)
    worker_name: str = Field(default="api-worker", max_length=128)

    model_config = {
        "json_schema_extra": {
            "example": {
                "version_label": "v1",
                "model_key": "future_local_default",
                "limit": 100,
                "worker_name": "embedding-worker-1",
            }
        }
    }


class EmbeddingRetryRequest(APIModel):
    limit: int = Field(default=100, ge=1, le=5000)

    model_config = {"json_schema_extra": {"example": {"limit": 100}}}


class EmbeddingRebuildRequest(APIModel):
    version_label: str = Field(default="v1", max_length=32)
    model_key: str | None = Field(default=None, max_length=128)
    topic: str | None = Field(default=None, max_length=128)
    organisation: str | None = Field(default=None, max_length=255)
    audience: str | None = Field(default=None, max_length=64)
    age_group: str | None = Field(default=None, max_length=64)
    force: bool = True

    model_config = {
        "json_schema_extra": {
            "example": {
                "version_label": "v2",
                "model_key": "future_local_default",
                "topic": "anxiety",
                "organisation": "UNICEF",
                "audience": "students",
                "age_group": "adolescents",
                "force": True,
            }
        }
    }


class EmbeddingQueueResponse(APIModel):
    queued_jobs: int
    model_key: str
    version_label: str
    scope: str


class EmbeddingRunResponse(APIModel):
    leased_jobs: int
    completed_jobs: int
    failed_jobs: int
    retried_jobs: int
    skipped_jobs: int
    worker_name: str
    model_key: str
    version_label: str


class EmbeddingModelRead(APIModel):
    id: UUID | None = None
    model_key: str
    provider_name: str
    provider_type: str
    model_name: str
    dimensions: int
    is_active: bool
    api_key_configured: bool
    usage_count: int = 0


class EmbeddingJobRead(APIModel):
    id: UUID
    knowledge_object_id: UUID | None = None
    job_type: str
    state: str
    scope_key: str | None = None
    scope_value: str | None = None
    attempts: int
    max_attempts: int
    priority: int
    scheduled_at: datetime
    started_at: datetime | None = None
    completed_at: datetime | None = None
    failed_at: datetime | None = None
    error_message: str | None = None


class EmbeddingStatusResponse(APIModel):
    pending: int
    processing: int
    completed: int
    failed: int
    cancelled: int
    retry: int
    active_model_key: str
    active_version: str
    recent_jobs: list[EmbeddingJobRead]


class EmbeddingStatisticsResponse(APIModel):
    knowledge_objects: int
    embedded_objects: int
    pending: int
    processing: int
    failed: int
    average_embedding_time_ms: float
    average_queue_time_ms: float
    embedding_model_usage: dict[str, int]
    embedding_versions: dict[str, int]
    organisation_distribution: dict[str, int]
    topic_distribution: dict[str, int]
    priority_distribution: dict[str, int]
