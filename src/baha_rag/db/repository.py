from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.schemas import Citation, ChunkMetadata, SearchResult


def content_hash(content: bytes | str) -> str:
    data = content.encode("utf-8") if isinstance(content, str) else content
    return hashlib.sha256(data).hexdigest()


def vector_literal(vector: list[float]) -> str:
    return "[" + ",".join(f"{value:.8f}" for value in vector) + "]"


class KnowledgeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def upsert_document(
        self,
        *,
        title: str,
        url: str,
        source: str,
        organization: str,
        author: str | None,
        publication_date: Any,
        country: str | None,
        audience: str,
        hash_value: str,
        etag: str | None,
        last_modified: str | None,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into documents (
                  title, url, source, organization, author, publication_date, country,
                  audience, content_hash, etag, last_modified, ingested_at, version,
                  source_weight
                )
                values (
                  :title, :url, :source, :organization, :author, :publication_date, :country,
                  :audience, :content_hash, :etag, :last_modified, :ingested_at, 1,
                  coalesce(
                    (select source_weight from priority_sources where organization = :organization),
                    0.700
                  )
                )
                on conflict (url) do update set
                  title = excluded.title,
                  source = excluded.source,
                  organization = excluded.organization,
                  author = excluded.author,
                  publication_date = excluded.publication_date,
                  country = excluded.country,
                  audience = excluded.audience,
                  source_weight = excluded.source_weight,
                  etag = excluded.etag,
                  last_modified = excluded.last_modified,
                  ingested_at = excluded.ingested_at,
                  version = case
                    when documents.content_hash <> excluded.content_hash then documents.version + 1
                    else documents.version
                  end,
                  content_hash = excluded.content_hash
                returning id
                """
            ),
            {
                "title": title,
                "url": url,
                "source": source,
                "organization": organization,
                "author": author,
                "publication_date": publication_date,
                "country": country,
                "audience": audience,
                "content_hash": hash_value,
                "etag": etag,
                "last_modified": last_modified,
                "ingested_at": datetime.now(timezone.utc),
            },
        )
        return result.scalar_one()

    async def replace_chunks(
        self,
        *,
        document_id: UUID,
        chunks: list[tuple[int, str, int, ChunkMetadata, list[float], str]],
    ) -> int:
        await self.session.execute(text("delete from chunks where document_id = :document_id"), {"document_id": document_id})
        for ordinal, chunk_text, token_count, metadata, embedding, model_name in chunks:
            chunk_result = await self.session.execute(
                text(
                    """
                    insert into chunks (document_id, ordinal, text, token_count, metadata)
                    values (:document_id, :ordinal, :text, :token_count, cast(:metadata as jsonb))
                    returning id
                    """
                ),
                {
                    "document_id": document_id,
                    "ordinal": ordinal,
                    "text": chunk_text,
                    "token_count": token_count,
                    "metadata": metadata.model_dump_json(),
                },
            )
            chunk_id = chunk_result.scalar_one()
            await self.session.execute(
                text(
                    """
                    insert into embeddings (chunk_id, model, dimensions, embedding, version)
                    values (:chunk_id, :model, :dimensions, cast(:embedding as vector), 1)
                    """
                ),
                {
                    "chunk_id": chunk_id,
                    "model": model_name,
                    "dimensions": len(embedding),
                    "embedding": vector_literal(embedding),
                },
            )
        return len(chunks)

    async def dense_search(
        self,
        *,
        query_embedding: list[float],
        top_k: int,
        filters: dict[str, Any],
    ) -> list[SearchResult]:
        where_sql, params = self._resource_where(filters)
        params.update({"embedding": vector_literal(query_embedding), "top_k": top_k})
        result = await self.session.execute(
            text(
                f"""
                select
                  c.id as chunk_id,
                  r.id as document_id,
                  c.text,
                  c.metadata,
                  r.title,
                  r.organization,
                  r.url,
                  case
                    when r.publication_date_raw ~ '^\\d{{4}}-\\d{{2}}-\\d{{2}}'
                      then substring(r.publication_date_raw from 1 for 10)::date
                    when r.publication_date_raw ~ '^\\d{{4}}$'
                      then make_date(r.publication_date_raw::integer, 1, 1)
                    else null
                  end as publication_date,
                  r.source_weight,
                  r.downloaded_at,
                  1 - (e.embedding <=> cast(:embedding as vector)) as dense_score,
                  0.0 as lexical_score
                from resource_embeddings e
                join resource_chunks c on c.id = e.chunk_id
                join acquired_resources r on r.id = e.document_id
                {where_sql}
                order by e.embedding <=> cast(:embedding as vector)
                limit :top_k
                """
            ),
            params,
        )
        return [self._row_to_result(row._mapping) for row in result.fetchall()]

    async def lexical_search(self, *, query: str, top_k: int, filters: dict[str, Any]) -> list[SearchResult]:
        where_sql, params = self._resource_where(filters, prefix="and")
        params.update({"query": query, "top_k": top_k})
        result = await self.session.execute(
            text(
                f"""
                select
                  c.id as chunk_id,
                  r.id as document_id,
                  c.text,
                  c.metadata,
                  r.title,
                  r.organization,
                  r.url,
                  case
                    when r.publication_date_raw ~ '^\\d{{4}}-\\d{{2}}-\\d{{2}}'
                      then substring(r.publication_date_raw from 1 for 10)::date
                    when r.publication_date_raw ~ '^\\d{{4}}$'
                      then make_date(r.publication_date_raw::integer, 1, 1)
                    else null
                  end as publication_date,
                  r.source_weight,
                  r.downloaded_at,
                  0.0 as dense_score,
                  ts_rank_cd(c.search_vector, websearch_to_tsquery('english', :query)) as lexical_score
                from resource_chunks c
                join acquired_resources r on r.id = c.resource_id
                where c.search_vector @@ websearch_to_tsquery('english', :query)
                {where_sql}
                order by lexical_score desc
                limit :top_k
                """
            ),
            params,
        )
        return [self._row_to_result(row._mapping) for row in result.fetchall()]

    async def graph_context(
        self,
        *,
        query_embedding: list[float],
        top_k: int = 12,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                with nearest as (
                  select
                    knowledge_node_id,
                    node_type,
                    label,
                    1 - (embedding <=> cast(:embedding as vector)) as similarity
                  from knowledge_embeddings
                  order by embedding <=> cast(:embedding as vector)
                  limit :top_k
                )
                select node_type, label, similarity
                from nearest
                order by similarity desc
                """
            ),
            {"embedding": vector_literal(query_embedding), "top_k": top_k},
        )
        nodes = [dict(row._mapping) for row in result.fetchall()]
        return {
            "nodes": nodes,
            "terms": [row["label"] for row in nodes],
            "conditions": [
                row["label"] for row in nodes if row["node_type"] == "Condition"
            ],
        }

    async def dashboard_metrics(self) -> dict[str, Any]:
        rows = {}
        for name, sql in {
            "documents": "select count(*) from documents",
            "chunks": "select count(*) from chunks",
            "embeddings": "select count(*) from embeddings",
            "stale_documents": "select count(*) from documents where ingested_at < now() - interval '180 days'",
        }.items():
            result = await self.session.execute(text(sql))
            rows[name] = result.scalar_one()
        return rows

    def _metadata_where(self, filters: dict[str, Any], prefix: str = "where") -> tuple[str, dict[str, Any]]:
        clauses = []
        params: dict[str, Any] = {}
        for index, (key, value) in enumerate(filters.items()):
            if value is None:
                continue
            param = f"filter_{index}"
            clauses.append(f"c.metadata ->> '{key}' = :{param}")
            params[param] = str(value)
        if not clauses:
            return "", params
        return f"{prefix} " + " and ".join(clauses), params

    def _resource_where(
        self,
        filters: dict[str, Any],
        prefix: str = "where",
    ) -> tuple[str, dict[str, Any]]:
        columns = {
            "organization": "r.organization",
            "topic": "r.topic",
            "audience": "r.audience",
            "country": "r.country",
            "language": "r.language",
            "condition": "r.extracted_metadata ->> 'condition'",
        }
        clauses = []
        params: dict[str, Any] = {}
        for index, (key, value) in enumerate(filters.items()):
            if value is None or key not in columns:
                continue
            param = f"filter_{index}"
            clauses.append(f"lower(coalesce({columns[key]}, '')) = lower(:{param})")
            params[param] = str(value)
        if not clauses:
            return "", params
        return f"{prefix} " + " and ".join(clauses), params

    def _row_to_result(self, row: Any) -> SearchResult:
        metadata = row["metadata"]
        if isinstance(metadata, str):
            metadata = json.loads(metadata)
        citation = Citation(
            title=row["title"],
            organization=row["organization"],
            url=row["url"],
            publication_date=row["publication_date"],
            chunk_id=row["chunk_id"],
        )
        return SearchResult(
            chunk_id=row["chunk_id"],
            document_id=row["document_id"],
            text=row["text"],
            metadata=ChunkMetadata.model_validate(metadata),
            citations=[citation],
            dense_score=float(row["dense_score"] or 0.0),
            lexical_score=float(row["lexical_score"] or 0.0),
            confidence=0.0,
        )
