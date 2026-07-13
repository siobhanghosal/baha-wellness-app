"""Create BAHA embedding and vector pipeline tables."""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260709_0003"
down_revision = "20260709_0002"
branch_labels = None
depends_on = None


class VectorType(sa.types.UserDefinedType):
    cache_ok = True

    def get_col_spec(self, **_kw) -> str:
        return "vector"


def upgrade() -> None:
    bind = op.get_bind()
    is_postgres = bind.dialect.name == "postgresql"
    if is_postgres:
        op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    vector_column_type = VectorType() if is_postgres else sa.JSON()

    op.create_table(
        "embedding_models",
        sa.Column("model_key", sa.String(length=128), nullable=False),
        sa.Column("provider_name", sa.String(length=64), nullable=False),
        sa.Column("provider_type", sa.String(length=64), nullable=False),
        sa.Column("model_name", sa.String(length=255), nullable=False),
        sa.Column("dimensions", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("config", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_embedding_models")),
        sa.UniqueConstraint("model_key", name=op.f("uq_embedding_models_model_key")),
    )
    op.create_index(op.f("ix_embedding_models_model_key"), "embedding_models", ["model_key"], unique=False)
    op.create_index(op.f("ix_embedding_models_provider_name"), "embedding_models", ["provider_name"], unique=False)
    op.create_index(op.f("ix_embedding_models_deleted_at"), "embedding_models", ["deleted_at"], unique=False)

    op.create_table(
        "embedding_versions",
        sa.Column("model_id", sa.Uuid(), nullable=False),
        sa.Column("version_label", sa.String(length=32), nullable=False),
        sa.Column("content_schema_version", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("metadata", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["model_id"], ["embedding_models.id"], name=op.f("fk_embedding_versions_model_id_embedding_models"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_embedding_versions")),
    )
    op.create_index(op.f("ix_embedding_versions_model_id"), "embedding_versions", ["model_id"], unique=False)
    op.create_index(op.f("ix_embedding_versions_version_label"), "embedding_versions", ["version_label"], unique=False)
    op.create_index(op.f("ix_embedding_versions_deleted_at"), "embedding_versions", ["deleted_at"], unique=False)

    op.create_table(
        "knowledge_embeddings",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=False),
        sa.Column("model_id", sa.Uuid(), nullable=False),
        sa.Column("version_id", sa.Uuid(), nullable=False),
        sa.Column("embedding_vector", vector_column_type, nullable=False),
        sa.Column("model_name", sa.String(length=255), nullable=False),
        sa.Column("embedding_dimension", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("retrieval_summary", sa.Text(), nullable=False),
        sa.Column("retrieval_document", sa.Text(), nullable=False),
        sa.Column("content_hash", sa.String(length=64), nullable=False),
        sa.Column("source_priority", sa.String(length=32), nullable=True),
        sa.Column("topic", sa.String(length=128), nullable=True),
        sa.Column("organisation", sa.String(length=255), nullable=True),
        sa.Column("audience", sa.String(length=64), nullable=True),
        sa.Column("age_group", sa.String(length=64), nullable=True),
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("metadata", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["knowledge_object_id"], ["knowledge_objects.id"], name=op.f("fk_knowledge_embeddings_knowledge_object_id_knowledge_objects"), ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["model_id"], ["embedding_models.id"], name=op.f("fk_knowledge_embeddings_model_id_embedding_models"), ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["version_id"], ["embedding_versions.id"], name=op.f("fk_knowledge_embeddings_version_id_embedding_versions"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_knowledge_embeddings")),
    )
    op.create_index(op.f("ix_knowledge_embeddings_knowledge_object_id"), "knowledge_embeddings", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_model_id"), "knowledge_embeddings", ["model_id"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_version_id"), "knowledge_embeddings", ["version_id"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_content_hash"), "knowledge_embeddings", ["content_hash"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_source_priority"), "knowledge_embeddings", ["source_priority"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_topic"), "knowledge_embeddings", ["topic"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_organisation"), "knowledge_embeddings", ["organisation"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_audience"), "knowledge_embeddings", ["audience"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_age_group"), "knowledge_embeddings", ["age_group"], unique=False)
    op.create_index(op.f("ix_knowledge_embeddings_deleted_at"), "knowledge_embeddings", ["deleted_at"], unique=False)

    op.create_table(
        "embedding_jobs",
        sa.Column("knowledge_object_id", sa.Uuid(), nullable=True),
        sa.Column("model_id", sa.Uuid(), nullable=False),
        sa.Column("version_id", sa.Uuid(), nullable=False),
        sa.Column("job_type", sa.String(length=32), nullable=False),
        sa.Column("state", sa.String(length=32), nullable=False),
        sa.Column("scope_key", sa.String(length=64), nullable=True),
        sa.Column("scope_value", sa.String(length=255), nullable=True),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_attempts", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("failed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("cancelled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("lease_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("leased_by", sa.String(length=128), nullable=True),
        sa.Column("queue_time_ms", sa.Integer(), nullable=True),
        sa.Column("embedding_time_ms", sa.Integer(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("metadata", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["knowledge_object_id"], ["knowledge_objects.id"], name=op.f("fk_embedding_jobs_knowledge_object_id_knowledge_objects"), ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["model_id"], ["embedding_models.id"], name=op.f("fk_embedding_jobs_model_id_embedding_models"), ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["version_id"], ["embedding_versions.id"], name=op.f("fk_embedding_jobs_version_id_embedding_versions"), ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_embedding_jobs")),
    )
    op.create_index(op.f("ix_embedding_jobs_knowledge_object_id"), "embedding_jobs", ["knowledge_object_id"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_model_id"), "embedding_jobs", ["model_id"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_version_id"), "embedding_jobs", ["version_id"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_job_type"), "embedding_jobs", ["job_type"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_state"), "embedding_jobs", ["state"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_scope_key"), "embedding_jobs", ["scope_key"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_scope_value"), "embedding_jobs", ["scope_value"], unique=False)
    op.create_index(op.f("ix_embedding_jobs_deleted_at"), "embedding_jobs", ["deleted_at"], unique=False)

    op.create_table(
        "embedding_statistics",
        sa.Column("model_id", sa.Uuid(), nullable=True),
        sa.Column("version_id", sa.Uuid(), nullable=True),
        sa.Column("knowledge_objects", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("embedded_objects", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("pending_jobs", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("processing_jobs", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("failed_jobs", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("average_embedding_time_ms", sa.Float(), nullable=False, server_default="0"),
        sa.Column("average_queue_time_ms", sa.Float(), nullable=False, server_default="0"),
        sa.Column("model_usage", sa.JSON(), nullable=False),
        sa.Column("embedding_versions", sa.JSON(), nullable=False),
        sa.Column("organisation_distribution", sa.JSON(), nullable=False),
        sa.Column("topic_distribution", sa.JSON(), nullable=False),
        sa.Column("priority_distribution", sa.JSON(), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["model_id"], ["embedding_models.id"], name=op.f("fk_embedding_statistics_model_id_embedding_models"), ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["version_id"], ["embedding_versions.id"], name=op.f("fk_embedding_statistics_version_id_embedding_versions"), ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_embedding_statistics")),
    )
    op.create_index(op.f("ix_embedding_statistics_model_id"), "embedding_statistics", ["model_id"], unique=False)
    op.create_index(op.f("ix_embedding_statistics_version_id"), "embedding_statistics", ["version_id"], unique=False)
    op.create_index(op.f("ix_embedding_statistics_deleted_at"), "embedding_statistics", ["deleted_at"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_embedding_statistics_deleted_at"), table_name="embedding_statistics")
    op.drop_index(op.f("ix_embedding_statistics_version_id"), table_name="embedding_statistics")
    op.drop_index(op.f("ix_embedding_statistics_model_id"), table_name="embedding_statistics")
    op.drop_table("embedding_statistics")

    op.drop_index(op.f("ix_embedding_jobs_deleted_at"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_scope_value"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_scope_key"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_state"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_job_type"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_version_id"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_model_id"), table_name="embedding_jobs")
    op.drop_index(op.f("ix_embedding_jobs_knowledge_object_id"), table_name="embedding_jobs")
    op.drop_table("embedding_jobs")

    op.drop_index(op.f("ix_knowledge_embeddings_deleted_at"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_age_group"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_audience"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_organisation"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_topic"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_source_priority"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_content_hash"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_version_id"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_model_id"), table_name="knowledge_embeddings")
    op.drop_index(op.f("ix_knowledge_embeddings_knowledge_object_id"), table_name="knowledge_embeddings")
    op.drop_table("knowledge_embeddings")

    op.drop_index(op.f("ix_embedding_versions_deleted_at"), table_name="embedding_versions")
    op.drop_index(op.f("ix_embedding_versions_version_label"), table_name="embedding_versions")
    op.drop_index(op.f("ix_embedding_versions_model_id"), table_name="embedding_versions")
    op.drop_table("embedding_versions")

    op.drop_index(op.f("ix_embedding_models_deleted_at"), table_name="embedding_models")
    op.drop_index(op.f("ix_embedding_models_provider_name"), table_name="embedding_models")
    op.drop_index(op.f("ix_embedding_models_model_key"), table_name="embedding_models")
    op.drop_table("embedding_models")
