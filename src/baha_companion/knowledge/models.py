from __future__ import annotations

from datetime import date
from uuid import UUID

from sqlalchemy import Boolean, Date, Float, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from baha_companion.common.models import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin


class KnowledgeObject(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_objects"

    title: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    source_document: Mapped[str] = mapped_column(String(1024), nullable=False, index=True)
    metadata_: Mapped[dict] = mapped_column("metadata", JSON, nullable=False, default=dict)

    details = relationship(
        "KnowledgeMetadata",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        uselist=False,
        lazy="joined",
    )
    topics = relationship(
        "KnowledgeTopic",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    keywords = relationship(
        "KnowledgeKeyword",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    citations = relationship(
        "KnowledgeCitation",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    faqs = relationship(
        "KnowledgeFaq",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    activities = relationship(
        "KnowledgeActivity",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    quality = relationship(
        "KnowledgeQuality",
        back_populates="knowledge_object",
        cascade="all, delete-orphan",
        uselist=False,
        lazy="joined",
    )


class KnowledgeMetadata(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_metadata"
    __table_args__ = (UniqueConstraint("knowledge_object_id"),)

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    organization: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    document_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    publication_date: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    country: Mapped[str | None] = mapped_column(String(128), nullable=True, index=True)
    language: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    audience: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    age_group: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    gender: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    evidence_level: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    evidence_confidence: Mapped[float] = mapped_column(Float, nullable=False)
    clinical_review_status: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    priority_level: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    reading_level: Mapped[str] = mapped_column(String(32), nullable=False)
    source_type: Mapped[str] = mapped_column(String(32), nullable=False, index=True)
    parser_name: Mapped[str] = mapped_column(String(128), nullable=False)
    extraction_confidence: Mapped[float] = mapped_column(Float, nullable=False)
    duplicate_likelihood: Mapped[float] = mapped_column(Float, nullable=False)
    tags: Mapped[list] = mapped_column(JSON, nullable=False, default=list)

    knowledge_object = relationship("KnowledgeObject", back_populates="details", lazy="joined")


class KnowledgeTopic(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_topics"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    topic: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    subtopic: Mapped[str | None] = mapped_column(String(128), nullable=True, index=True)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    is_primary: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")

    knowledge_object = relationship("KnowledgeObject", back_populates="topics", lazy="joined")


class KnowledgeKeyword(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_keywords"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    keyword: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    knowledge_object = relationship("KnowledgeObject", back_populates="keywords", lazy="joined")


class KnowledgeCitation(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_citations"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    citation_text: Mapped[str] = mapped_column(Text, nullable=False)
    citation_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    source_title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    knowledge_object = relationship("KnowledgeObject", back_populates="citations", lazy="joined")


class KnowledgeFaq(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_faqs"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    question: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    knowledge_object = relationship("KnowledgeObject", back_populates="faqs", lazy="joined")


class KnowledgeActivity(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_activities"

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    activity_type: Mapped[str] = mapped_column(String(64), nullable=False, default="exercise", server_default="exercise")
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    knowledge_object = relationship("KnowledgeObject", back_populates="activities", lazy="joined")


class KnowledgeQuality(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "knowledge_quality"
    __table_args__ = (UniqueConstraint("knowledge_object_id"),)

    knowledge_object_id: Mapped[UUID] = mapped_column(
        ForeignKey("knowledge_objects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    quality_score: Mapped[float] = mapped_column(Float, nullable=False, index=True)
    completeness_score: Mapped[float] = mapped_column(Float, nullable=False)
    readability_score: Mapped[float] = mapped_column(Float, nullable=False)
    metadata_completeness_score: Mapped[float] = mapped_column(Float, nullable=False)
    duplicate_likelihood_score: Mapped[float] = mapped_column(Float, nullable=False)
    extraction_confidence_score: Mapped[float] = mapped_column(Float, nullable=False)
    reference_quality_score: Mapped[float] = mapped_column(Float, nullable=False)
    language_quality_score: Mapped[float] = mapped_column(Float, nullable=False)
    warnings: Mapped[list] = mapped_column(JSON, nullable=False, default=list)

    knowledge_object = relationship("KnowledgeObject", back_populates="quality", lazy="joined")

