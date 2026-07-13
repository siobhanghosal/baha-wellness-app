from __future__ import annotations

from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect, text


def test_alembic_upgrade_and_downgrade_are_reversible(tmp_path):
    database_path = tmp_path / "migration_test.db"
    config = Config(str(Path("alembic.ini").resolve()))
    config.set_main_option("sqlalchemy.url", f"sqlite:///{database_path}")

    command.upgrade(config, "head")

    engine = create_engine(f"sqlite:///{database_path}")
    inspector = inspect(engine)
    tables = set(inspector.get_table_names())
    assert {
        "users",
        "refresh_tokens",
        "conversations",
        "messages",
        "login_attempts",
        "knowledge_objects",
        "knowledge_metadata",
        "knowledge_topics",
        "knowledge_keywords",
        "knowledge_citations",
        "knowledge_faqs",
        "knowledge_activities",
        "knowledge_quality",
        "embedding_models",
        "embedding_versions",
        "knowledge_embeddings",
        "embedding_jobs",
        "embedding_statistics",
    }.issubset(tables)

    with engine.connect() as connection:
        version = connection.execute(text("select version_num from alembic_version")).scalar_one()
    assert version == "20260709_0003"

    command.downgrade(config, "base")

    post_downgrade_inspector = inspect(engine)
    assert "users" not in post_downgrade_inspector.get_table_names()
