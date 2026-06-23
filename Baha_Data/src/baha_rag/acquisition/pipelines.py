from __future__ import annotations

import json
import os

import asyncpg
from itemadapter import ItemAdapter
from scrapy.exceptions import DropItem


class PostgresCandidatePipeline:
    def __init__(self) -> None:
        self.pool: asyncpg.Pool | None = None

    async def open_spider(self, spider) -> None:
        database_url = os.getenv("DATABASE_URL", "postgresql://baha:baha@localhost:5432/baha_rag")
        database_url = database_url.replace("postgresql+asyncpg://", "postgresql://")
        self.pool = await asyncpg.create_pool(database_url)

    async def close_spider(self, spider) -> None:
        if self.pool:
            await self.pool.close()

    async def process_item(self, item, spider):
        adapter = ItemAdapter(item)
        url = adapter.get("url")
        organization = adapter.get("organization")
        if not url or not organization:
            raise DropItem("Candidate requires url and organization")
        normalized_url = url.split("#", 1)[0].rstrip("/").lower()
        metadata = json.dumps(adapter.get("metadata") or {})
        assert self.pool is not None
        async with self.pool.acquire() as connection:
            await connection.execute(
                """
                insert into acquisition_candidates (
                  url, normalized_url, organization, source, title, author,
                  publication_date_raw, country, language, topic, subtopic,
                  resource_type, content_type, discovered_via, metadata, status,
                  discovered_at, updated_at
                )
                values ($1, $2, $3, $4, $5, $6, $7, $8, coalesce($9, 'en'), $10, $11,
                        coalesce($12, 'html'), $13, $14, $15::jsonb, 'discovered', now(), now())
                on conflict (normalized_url) do update set
                  title = coalesce(excluded.title, acquisition_candidates.title),
                  topic = coalesce(excluded.topic, acquisition_candidates.topic),
                  subtopic = coalesce(excluded.subtopic, acquisition_candidates.subtopic),
                  content_type = coalesce(excluded.content_type, acquisition_candidates.content_type),
                  metadata = acquisition_candidates.metadata || excluded.metadata,
                  updated_at = now()
                """,
                url,
                normalized_url,
                organization,
                adapter.get("source"),
                adapter.get("title"),
                adapter.get("author"),
                adapter.get("publication_date"),
                adapter.get("country"),
                adapter.get("language"),
                adapter.get("topic"),
                adapter.get("subtopic"),
                adapter.get("resource_type"),
                adapter.get("content_type"),
                adapter.get("discovered_via") or "scrapy",
                metadata,
            )
        return item
