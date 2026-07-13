"""Create BAHA knowledge processing pipeline tables."""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

revision = "20260709_0002"
down_revision = "20260708_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "knowledge_objects",
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("source_document", sa.String(length=1024), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_objects")),
    )
    op.create_index(op.f("ix_knowledge_objects_title"), "knowledge_objects", ["title"], unique=False)
    op.create_index(op.f("ix_knowledge_objects_source_document"), "knowledge_objects", ["source_document"], unique=False)
    op.create_index(op.f("ix_knowledge_objects_deleted_at"), "knowledge_objects", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_metadata",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("organization", sa.String(length=255), nullable=True),
        sa.Column("document_url", sa.String(length=2048), nullable=True),
        sa.Column("publication_date", sa.Date(), nullable=True),
        sa.Column("country", sa.String(length=128), nullable=True),
        sa.Column("language", sa.String(length=64), nullable=True),
        sa.Column("audience", sa.String(length=64), nullable=False),
        sa.Column("age_group", sa.String(length=64), nullable=False),
        sa.Column("gender", sa.String(length=32), nullable=False),
        sa.Column("evidence_level", sa.String(length=64), nullable=False),
        sa.Column("evidence_confidence", sa.Float(), nullable=False),
        sa.Column("clinical_review_status", sa.String(length=64), nullable=False),
        sa.Column("priority_level", sa.String(length=32), nullable=False),
        sa.Column("reading_level", sa.String(length=32), nullable=False),
        sa.Column("source_type", sa.String(length=32), nullable=False),
        sa.Column("parser_name", sa.String(length=128), nullable=False),
        sa.Column("extraction_confidence", sa.Float(), nullable=False),
        sa.Column("duplicate_likelihood", sa.Float(), nullable=False),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_metadata_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_metadata")),
        sa.UniqueConstraint("knowledge_object_id", name=op.f("uq_knowledge_metadata_knowledge_object_id")),
    )
    op.create_index(op.f("ix_knowledge_metadata_knowledge_object_id"), "knowledge_metadata", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_organization"), "knowledge_metadata", ["organization"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_publication_date"), "knowledge_metadata", ["publication_date"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_country"), "knowledge_metadata", ["country"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_language"), "knowledge_metadata", ["language"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_audience"), "knowledge_metadata", ["audience"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_age_group"), "knowledge_metadata", ["age_group"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_gender"), "knowledge_metadata", ["gender"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_evidence_level"), "knowledge_metadata", ["evidence_level"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_clinical_review_status"), "knowledge_metadata", ["clinical_review_status"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_priority_level"), "knowledge_metadata", ["priority_level"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_source_type"), "knowledge_metadata", ["source_type"], unique=False)
    op.create_index(op.f("ix_knowledge_metadata_deleted_at"), "knowledge_metadata", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_topics",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("topic", sa.String(length=128), nullable=False),
        sa.Column("subtopic", sa.String(length=128), nullable=True),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_topics_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_topics")),
    )
    op.create_index(op.f("ix_knowledge_topics_knowledge_object_id"), "knowledge_topics", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_topics_topic"), "knowledge_topics", ["topic"], unique=False)
    op.create_index(op.f("ix_knowledge_topics_subtopic"), "knowledge_topics", ["subtopic"], unique=False)
    op.create_index(op.f("ix_knowledge_topics_deleted_at"), "knowledge_topics", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_keywords",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("keyword", sa.String(length=128), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_keywords_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_keywords")),
    )
    op.create_index(op.f("ix_knowledge_keywords_knowledge_object_id"), "knowledge_keywords", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_keywords_keyword"), "knowledge_keywords", ["keyword"], unique=False)
    op.create_index(op.f("ix_knowledge_keywords_deleted_at"), "knowledge_keywords", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_citations",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("citation_text", sa.Text(), nullable=False),
        sa.Column("citation_url", sa.String(length=2048), nullable=True),
        sa.Column("source_title", sa.String(length=255), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_citations_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_citations")),
    )
    op.create_index(op.f("ix_knowledge_citations_knowledge_object_id"), "knowledge_citations", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_citations_deleted_at"), "knowledge_citations", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_faqs",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("question", sa.Text(), nullable=False),
        sa.Column("answer", sa.Text(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_faqs_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_faqs")),
    )
    op.create_index(op.f("ix_knowledge_faqs_knowledge_object_id"), "knowledge_faqs", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_faqs_deleted_at"), "knowledge_faqs", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_activities",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("activity_type", sa.String(length=64), nullable=False, server_default="exercise"),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_activities_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_activities")),
    )
    op.create_index(op.f("ix_knowledge_activities_knowledge_object_id"), "knowledge_activities", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_activities_deleted_at"), "knowledge_activities", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_quality",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("quality_score", sa.Float(), nullable=False),
        sa.Column("completeness_score", sa.Float(), nullable=False),
        sa.Column("readability_score", sa.Float(), nullable=False),
        sa.Column("metadata_completeness_score", sa.Float(), nullable=False),
        sa.Column("duplicate_likelihood_score", sa.Float(), nullable=False),
        sa.Column("extraction_confidence_score", sa.Float(), nullable=False),
        sa.Column("reference_quality_score", sa.Float(), nullable=False),
        sa.Column("language_quality_score", sa.Float(), nullable=False),
        sa.Column("warnings", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["knowledge_object_id"],
            ["knowledge_objects.id"],
            name=op.f("fk_knowledge_quality_knowledge_object_id_knowledge_objects"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_quality")),
        sa.UniqueConstraint("knowledge_object_id", name=op.f("uq_knowledge_quality_knowledge_object_id")),
    )
    op.create_index(op.f("ix_knowledge_quality_knowledge_object_id"), "knowledge_quality", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_quality_quality_score"), "knowledge_quality", ["quality_score"], unique=False)
    op.create_index(op.f("ix_knowledge_quality_deleted_at"), "knowledge_quality", ["deleted_at"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_knowledge_quality_deleted_at"), table_name="knowledge_quality")
    op.drop_index(op.f("ix_knowledge_quality_quality_score"), table_name="knowledge_quality")
    op.drop_index(op.f("ix_knowledge_quality_knowledge_object_id"), table_name="knowledge_quality")
    op.drop_table("knowledge_quality")

    op.drop_index(op.f("ix_knowledge_activities_deleted_at"), table_name="knowledge_activities")
    op.drop_index(op.f("ix_knowledge_activities_knowledge_object_id"), table_name="knowledge_activities")
    op.drop_table("knowledge_activities")

    op.drop_index(op.f("ix_knowledge_faqs_deleted_at"), table_name="knowledge_faqs")
    op.drop_index(op.f("ix_knowledge_faqs_knowledge_object_id"), table_name="knowledge_faqs")
    op.drop_table("knowledge_faqs")

    op.drop_index(op.f("ix_knowledge_citations_deleted_at"), table_name="knowledge_citations")
    op.drop_index(op.f("ix_knowledge_citations_knowledge_object_id"), table_name="knowledge_citations")
    op.drop_table("knowledge_citations")

    op.drop_index(op.f("ix_knowledge_keywords_deleted_at"), table_name="knowledge_keywords")
    op.drop_index(op.f("ix_knowledge_keywords_keyword"), table_name="knowledge_keywords")
    op.drop_index(op.f("ix_knowledge_keywords_knowledge_object_id"), table_name="knowledge_keywords")
    op.drop_table("knowledge_keywords")

    op.drop_index(op.f("ix_knowledge_topics_deleted_at"), table_name="knowledge_topics")
    op.drop_index(op.f("ix_knowledge_topics_subtopic"), table_name="knowledge_topics")
    op.drop_index(op.f("ix_knowledge_topics_topic"), table_name="knowledge_topics")
    op.drop_index(op.f("ix_knowledge_topics_knowledge_object_id"), table_name="knowledge_topics")
    op.drop_table("knowledge_topics")

    op.drop_index(op.f("ix_knowledge_metadata_deleted_at"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_source_type"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_priority_level"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_clinical_review_status"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_evidence_level"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_gender"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_age_group"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_audience"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_language"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_country"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_publication_date"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_organization"), table_name="knowledge_metadata")
    op.drop_index(op.f("ix_knowledge_metadata_knowledge_object_id"), table_name="knowledge_metadata")
    op.drop_table("knowledge_metadata")

    op.drop_index(op.f("ix_knowledge_objects_deleted_at"), table_name="knowledge_objects")
    op.drop_index(op.f("ix_knowledge_objects_source_document"), table_name="knowledge_objects")
    op.drop_index(op.f("ix_knowledge_objects_title"), table_name="knowledge_objects")
    op.drop_table("knowledge_objects")
