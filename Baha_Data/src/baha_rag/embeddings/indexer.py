from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.config import Settings
from baha_rag.db.repository import vector_literal
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.ingestion.chunking import chunk_tokens


def _hash_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


class IncrementalEmbeddingIndexer:
    def __init__(self, session: AsyncSession, settings: Settings) -> None:
        self.session = session
        self.settings = settings
        self.embeddings = EmbeddingService(settings)
        self.extractor = KnowledgeExtractionService()

    async def index(
        self,
        *,
        resource_limit: int = 100000,
        condition_limit: int = 1000,
        knowledge_limit: int = 100000,
    ) -> dict[str, Any]:
        run_id = await self._start_run()
        report = {
            "model": self.settings.embedding_model,
            "chunk_size": self.settings.embedding_chunk_tokens,
            "chunk_overlap": self.settings.embedding_chunk_overlap_tokens,
            "resources_embedded": 0,
            "chunks_embedded": 0,
            "conditions_embedded": 0,
            "knowledge_nodes_embedded": 0,
            "errors": 0,
        }
        try:
            resource_result = await self._index_resources(resource_limit)
            report.update(resource_result)
            report["conditions_embedded"] = await self._index_conditions(condition_limit)
            report["knowledge_nodes_embedded"] = await self._index_knowledge_nodes(knowledge_limit)
            await self._finish_run(run_id, "completed", report)
            await self.session.commit()
            return report
        except Exception:
            report["errors"] += 1
            await self.session.rollback()
            async with self.session.begin():
                await self._finish_run(run_id, "failed", report)
            raise

    async def _index_resources(self, limit: int) -> dict[str, int]:
        rows = await self.session.execute(
            text(
                """
                select r.*
                from acquired_resources r
                where r.quality_status = 'accepted'
                  and not exists (
                    select 1
                    from resource_embeddings e
                    where e.document_id = r.id
                      and e.model = :model
                      and e.content_hash = r.content_hash
                  )
                order by r.downloaded_at, r.id
                limit :limit
                """
            ),
            {"model": self.settings.embedding_model, "limit": limit},
        )
        resources = 0
        chunks_embedded = 0
        errors = 0
        for row in rows.fetchall():
            item = dict(row._mapping)
            try:
                result = await self._index_resource(item)
                if result:
                    resources += 1
                    chunks_embedded += result
                else:
                    errors += 1
            except Exception:
                errors += 1
            if (resources + errors) % 10 == 0:
                await self.session.commit()
        await self.session.commit()
        return {
            "resources_embedded": resources,
            "chunks_embedded": chunks_embedded,
            "errors": errors,
        }

    async def _index_resource(self, row: dict[str, Any]) -> int:
        storage_uri = row["storage_uri"]
        if not storage_uri or not Path(storage_uri).exists():
            return 0
        text_value = self.extractor._read_text(storage_uri, row["resource_type"])
        if not text_value.strip():
            text_value = self._fallback_resource_text(row)
        if not text_value.strip():
            return 0
        chunks = chunk_tokens(
            text_value,
            tokenizer=self.embeddings.tokenizer,
            max_tokens=self.settings.embedding_chunk_tokens,
            overlap_tokens=self.settings.embedding_chunk_overlap_tokens,
        )
        if not chunks:
            return 0
        vectors = self.embeddings.embed_long_texts(chunk.text for chunk in chunks)
        metadata = {
            "condition": (row.get("extracted_metadata") or {}).get("condition"),
            "topic": row.get("topic"),
            "subtopic": row.get("subtopic"),
            "audience": row.get("audience") or "general",
            "source": row.get("source"),
            "organization": row.get("organization"),
            "country": row.get("country"),
            "language": row.get("language") or "en",
            "publication_date": self._safe_publication_date(
                row.get("publication_date_raw")
            ),
            "source_weight": float(row.get("source_weight") or 0.7),
        }
        await self.session.execute(
            text("delete from resource_chunks where resource_id = :resource_id"),
            {"resource_id": row["id"]},
        )
        for chunk, vector in zip(chunks, vectors, strict=True):
            chunk_hash = _hash_text(chunk.text)
            chunk_result = await self.session.execute(
                text(
                    """
                    insert into resource_chunks (
                      resource_id, ordinal, text, token_count, content_hash, metadata
                    )
                    values (
                      :resource_id, :ordinal, :text, :token_count, :content_hash,
                      cast(:metadata as jsonb)
                    )
                    returning id
                    """
                ),
                {
                    "resource_id": row["id"],
                    "ordinal": chunk.ordinal,
                    "text": chunk.text,
                    "token_count": chunk.token_count,
                    "content_hash": row["content_hash"],
                    "metadata": json.dumps(metadata, default=str),
                },
            )
            chunk_id = chunk_result.scalar_one()
            await self.session.execute(
                text(
                    """
                    insert into resource_embeddings (
                      chunk_id, document_id, source, organization, topic, audience,
                      model, dimensions, embedding, content_hash
                    )
                    values (
                      :chunk_id, :document_id, :source, :organization, :topic, :audience,
                      :model, :dimensions, cast(:embedding as vector), :content_hash
                    )
                    """
                ),
                {
                    "chunk_id": chunk_id,
                    "document_id": row["id"],
                    "source": row["source"],
                    "organization": row["organization"],
                    "topic": row.get("topic"),
                    "audience": row.get("audience") or "general",
                    "model": self.settings.embedding_model,
                    "dimensions": self.settings.embedding_dimensions,
                    "embedding": vector_literal(vector),
                    "content_hash": row["content_hash"],
                },
            )
        return len(chunks)

    def _fallback_resource_text(self, row: dict[str, Any]) -> str:
        extracted = row.get("extracted_metadata") or {}
        values = (
            row.get("title"),
            extracted.get("summary"),
            row.get("organization"),
            row.get("topic"),
            row.get("subtopic"),
            row.get("source"),
            row.get("url"),
        )
        return "\n".join(str(value).strip() for value in values if value)

    def _safe_publication_date(self, value: str | None) -> str | None:
        if not value:
            return None
        match = re.match(r"^(\d{4})(?:-(\d{2})-(\d{2}))?", str(value))
        if not match:
            return None
        if match.group(2) and match.group(3):
            return f"{match.group(1)}-{match.group(2)}-{match.group(3)}"
        return f"{match.group(1)}-01-01"

    async def _index_conditions(self, limit: int) -> int:
        result = await self.session.execute(
            text(
                """
                select id, condition, profile,
                  encode(digest(profile::text, 'sha256'), 'hex') as content_hash
                from condition_profiles p
                where not exists (
                  select 1 from condition_embeddings e
                  where e.condition_profile_id = p.id and e.model = :model
                    and e.content_hash = encode(
                      digest(p.profile::text, 'sha256'), 'hex'
                    )
                )
                order by condition
                limit :limit
                """
            ),
            {"model": self.settings.embedding_model, "limit": limit},
        )
        count = 0
        for row in result.fetchall():
            profile_text = f"{row.condition}\n{json.dumps(row.profile, sort_keys=True, default=str)}"
            content_hash = row.content_hash
            vector = self.embeddings.embed_long_texts([profile_text])[0]
            await self.session.execute(
                text("delete from condition_embeddings where condition_profile_id = :id"),
                {"id": row.id},
            )
            await self.session.execute(
                text(
                    """
                    insert into condition_embeddings (
                      condition_profile_id, condition, text, model, dimensions,
                      embedding, content_hash
                    )
                    values (
                      :id, :condition, :text, :model, :dimensions,
                      cast(:embedding as vector), :content_hash
                    )
                    """
                ),
                {
                    "id": row.id,
                    "condition": row.condition,
                    "text": profile_text,
                    "model": self.settings.embedding_model,
                    "dimensions": self.settings.embedding_dimensions,
                    "embedding": vector_literal(vector),
                    "content_hash": content_hash,
                },
            )
            count += 1
        await self.session.commit()
        return count

    async def _index_knowledge_nodes(self, limit: int) -> int:
        result = await self.session.execute(
            text(
                """
                select id, node_type, label, metadata,
                  encode(
                    digest(node_type || '|' || label || '|' || metadata::text, 'sha256'),
                    'hex'
                  ) as content_hash
                from knowledge_graph_nodes n
                where not exists (
                  select 1 from knowledge_embeddings e
                  where e.knowledge_node_id = n.id and e.model = :model
                    and e.content_hash = encode(
                      digest(n.node_type || '|' || n.label || '|' || n.metadata::text, 'sha256'),
                      'hex'
                    )
                )
                order by n.node_type, n.label
                limit :limit
                """
            ),
            {"model": self.settings.embedding_model, "limit": limit},
        )
        rows = list(result.fetchall())
        count = 0
        batch_size = max(8, self.settings.embedding_batch_size * 4)
        for start in range(0, len(rows), batch_size):
            batch = rows[start : start + batch_size]
            texts = [
                f"{row.node_type}: {row.label}. {json.dumps(row.metadata, sort_keys=True, default=str)}"
                for row in batch
            ]
            vectors = self.embeddings.embed_texts(texts)
            for row, text_value, vector in zip(batch, texts, vectors, strict=True):
                content_hash = row.content_hash
                await self.session.execute(
                    text("delete from knowledge_embeddings where knowledge_node_id = :id"),
                    {"id": row.id},
                )
                await self.session.execute(
                    text(
                        """
                        insert into knowledge_embeddings (
                          knowledge_node_id, node_type, label, text, model, dimensions,
                          embedding, content_hash
                        )
                        values (
                          :id, :node_type, :label, :text, :model, :dimensions,
                          cast(:embedding as vector), :content_hash
                        )
                        """
                    ),
                    {
                        "id": row.id,
                        "node_type": row.node_type,
                        "label": row.label,
                        "text": text_value,
                        "model": self.settings.embedding_model,
                        "dimensions": self.settings.embedding_dimensions,
                        "embedding": vector_literal(vector),
                        "content_hash": content_hash,
                    },
                )
                count += 1
            await self.session.commit()
        return count

    async def report(self) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                select
                  (select count(*) from acquired_resources where quality_status = 'accepted')
                    as accepted_resources,
                  (select count(distinct document_id) from resource_embeddings)
                    as embedded_resources,
                  (select count(*) from resource_chunks) as resource_chunks,
                  (select count(*) from resource_embeddings) as resource_embeddings,
                  (select count(*) from condition_embeddings) as condition_embeddings,
                  (select count(*) from knowledge_embeddings) as knowledge_embeddings,
                  (select pg_size_pretty(pg_total_relation_size('resource_embeddings')))
                    as resource_index_size,
                  (select pg_size_pretty(pg_total_relation_size('condition_embeddings')))
                    as condition_index_size,
                  (select pg_size_pretty(pg_total_relation_size('knowledge_embeddings')))
                    as knowledge_index_size
                """
            )
        )
        index_result = await self.session.execute(
            text(
                """
                select indexname, indexdef
                from pg_indexes
                where schemaname = current_schema()
                  and tablename in (
                    'resource_embeddings', 'condition_embeddings', 'knowledge_embeddings'
                  )
                order by tablename, indexname
                """
            )
        )
        return {
            **dict(result.one()._mapping),
            "model": self.settings.embedding_model,
            "dimensions": self.settings.embedding_dimensions,
            "chunk_size": self.settings.embedding_chunk_tokens,
            "chunk_overlap": self.settings.embedding_chunk_overlap_tokens,
            "indexes": [dict(row._mapping) for row in index_result.fetchall()],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    async def _start_run(self) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into embedding_runs (model, chunk_size, chunk_overlap)
                values (:model, :chunk_size, :chunk_overlap)
                returning id
                """
            ),
            {
                "model": self.settings.embedding_model,
                "chunk_size": self.settings.embedding_chunk_tokens,
                "chunk_overlap": self.settings.embedding_chunk_overlap_tokens,
            },
        )
        await self.session.commit()
        return result.scalar_one()

    async def _finish_run(self, run_id: UUID, status: str, report: dict[str, Any]) -> None:
        await self.session.execute(
            text(
                """
                update embedding_runs
                set status = :status,
                    resources_embedded = :resources_embedded,
                    chunks_embedded = :chunks_embedded,
                    conditions_embedded = :conditions_embedded,
                    knowledge_nodes_embedded = :knowledge_nodes_embedded,
                    errors = :errors,
                    report = cast(:report as jsonb),
                    finished_at = now()
                where id = :id
                """
            ),
            {
                "id": run_id,
                "status": status,
                **{
                    key: report.get(key, 0)
                    for key in (
                        "resources_embedded",
                        "chunks_embedded",
                        "conditions_embedded",
                        "knowledge_nodes_embedded",
                        "errors",
                    )
                },
                "report": json.dumps(report, default=str),
            },
        )
