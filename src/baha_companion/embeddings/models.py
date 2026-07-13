from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from uuid import UUID

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text, TypeDecorator
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql.type_api import TypeEngine
from sqlalchemy.types import JSON as SA_JSON
from sqlalchemy.types import UserDefinedType

from baha_companion.common.models import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin
from baha_companion.embeddings.utils import vector_from_db_payload, vector_to_db_payload


class JobState(StrEnum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RETRY = "retry"


class JobType(StrEnum):
    OBJECT = "object"
    TOPIC = "topic"
    ORGANISATION = "organisation"
    AUDIENCE = "audience"
    AGE_GROUP = "age_group"
    CORPUS = "corpus"
    REBUILD = "rebuild"


class EmbeddingStatus(StrEnum):
    ACTIVE = "active"
    SUPERSEDED = "superseded"
    FAILED = "failed"


class VersionStatus(StrEnum):
    BUILDING = "building"
    ACTIVE = "active"
    DEPRECATED = "deprecated"
    FAILED = "failed"


class _PostgresVector(UserDefinedType):
    cache_ok = True

    def get_col_spec(self, **_kw) -> str:
        return "vector"


class VectorType(TypeDecorator):
    impl = SA_JSON
    cache_ok = True

    def load_dialect_impl(self, dialect) -> TypeEngine:
        if dialect.name == "postgresql":
            return dialect.type_descriptor(_PostgresVector())
        return dialect.type_descriptor(SA_JSON())

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        if dialect.name == "postgresql":
            return vector_to_db_payload(value)
        return value

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        if dialect.name == "postgresql":
            return vector_from_db_payload(value)
        return [float(item) for item in value]


class EmbeddingModel(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "embedding_models"

    model_key: Mapped[str] = mapped_column(String(128), nullable=False, unique=True, index=True)
    provider_name: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    provider_type: Mapped[str] = mapped_column(String(64), nullable=False)
    model_name: Mapped[str] = mapped_column(String(255), nullable=False)
    dimensions: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
    config: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    versions = relationship("EmbeddingVersion", back_populates="embedding_model", lazy="selectin")
    embeddings = relationship("KnowledgeEmbedding", back_populates="embedding_model", lazy="selectin")
    jobs = relationship("EmbeddingJob", back_populates="embedding_model", lazy="selectin")


class EmbeddingVersion(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "embedding_versions"

    model_id: Mapped[UUID] = mapped_column(
        ForeignKey("embedding_models.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    version_label: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    content_schema_version: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default=VersionStatus.BUILDING.value)
    is_current: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSON, nullable=False, default=dict)

    embedding_model = relationship("EmbeddingModel", back_populates="versions", lazy="joined")
    embeddings = relationship("KnowledgeEmbedding", back_populates="embedding_version", lazy="selectin")
    jobs = relationship("EmbeddingJob", back_populates="embedding_version", lazy="selectin")


class KnowledgeEmbedding(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_embeddings"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    model_id: Mapped[UUID] = mapped_column(ForeignKey("embedding_models.id", ondelete="CASCADE"), nullable=False, index=True)
    version_id: Mapped[UUID] = mapped_column(
        ForeignKey("embedding_versions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    embedding_vector: Mapped[list[float]] = mapped_column(VectorType(), nullable=False)
    model_name: Mapped[str] = mapped_column(String(255), nullable=False)
    embedding_dimension: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default=EmbeddingStatus.ACTIVE.value)
    retrieval_summary: Mapped[str] = mapped_column(Text, nullable=False)
    retrieval_document: Mapped[str] = mapped_column(Text, nullable=False)
    content_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    source_priority: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    topic: Mapped[str | None] = mapped_column(String(128), nullable=True, index=True)
    organisation: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    audience: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    age_group: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    is_current: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")
    metadata_: Mapped[dict] = mapped_column("metadata", JSON, nullable=False, default=dict)

    embedding_model = relationship("EmbeddingModel", back_populates="embeddings", lazy="joined")
    embedding_version = relationship("EmbeddingVersion", back_populates="embeddings", lazy="joined")


class EmbeddingJob(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "embedding_jobs"

    knowledge_object_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    model_id: Mapped[UUID] = mapped_column(ForeignKey("embedding_models.id", ondelete="CASCADE"), nullable=False, index=True)
    version_id: Mapped[UUID] = mapped_column(
        ForeignKey("embedding_versions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    job_type: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    state: Mapped[str] = mapped_column(String(32), nullable=False, default=JobState.PENDING.value, index=True)
    scope_key: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    scope_value: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    max_attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=3, server_default="3")
    priority: Mapped[int] = mapped_column(Integer, nullable=False, default=100, server_default="100")
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    failed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    lease_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    leased_by: Mapped[str | None] = mapped_column(String(128), nullable=True)
    queue_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    embedding_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSON, nullable=False, default=dict)

    embedding_model = relationship("EmbeddingModel", back_populates="jobs", lazy="joined")
    embedding_version = relationship("EmbeddingVersion", back_populates="jobs", lazy="joined")


class EmbeddingStatistics(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "embedding_statistics"

    model_id: Mapped[UUID | None] = mapped_column(ForeignKey("embedding_models.id", ondelete="SET NULL"), nullable=True, index=True)
    version_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("embedding_versions.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    knowledge_objects: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    embedded_objects: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    pending_jobs: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    processing_jobs: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    failed_jobs: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    average_embedding_time_ms: Mapped[float] = mapped_column(Float, nullable=False, default=0.0, server_default="0")
    average_queue_time_ms: Mapped[float] = mapped_column(Float, nullable=False, default=0.0, server_default="0")
    model_usage: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    embedding_versions: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    organisation_distribution: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    topic_distribution: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    priority_distribution: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    metadata_: Mapped[dict] = mapped_column("metadata", JSON, nullable=False, default=dict)
