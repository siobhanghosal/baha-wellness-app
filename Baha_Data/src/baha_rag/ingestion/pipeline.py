from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.db.repository import KnowledgeRepository, content_hash
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.ingestion.chunking import chunk_text
from baha_rag.ingestion.crawler import DocumentCrawler
from baha_rag.ingestion.metadata import infer_metadata, parse_http_date
from baha_rag.ingestion.processors import process_document
from baha_rag.ingestion.sources import validate_source
from baha_rag.schemas import Audience, EvidenceLevel, IngestResponse


class IngestionPipeline:
    def __init__(self, session: AsyncSession, embeddings: EmbeddingService) -> None:
        self.repository = KnowledgeRepository(session)
        self.embeddings = embeddings
        self.crawler = DocumentCrawler()

    async def ingest_url(
        self,
        *,
        url: str,
        organization: str,
        audience: Audience,
        country: str | None,
        evidence_level: EvidenceLevel,
    ) -> IngestResponse:
        validation = validate_source(url, organization)
        if not validation.approved:
            raise ValueError(validation.reason)

        raw = await self.crawler.fetch(url)
        if raw is None:
            raise ValueError("Document was not modified")

        processed = process_document(raw.content, raw.content_type, raw.url)
        hash_value = content_hash(processed.text)
        publication_date = parse_http_date(raw.last_modified)
        document_id = await self.repository.upsert_document(
            title=processed.title,
            url=raw.url,
            source=validation.normalized_domain or raw.url,
            organization=organization,
            author=None,
            publication_date=publication_date,
            country=country,
            audience=audience,
            hash_value=hash_value,
            etag=raw.etag,
            last_modified=raw.last_modified,
        )
        text_chunks = chunk_text(processed.text)
        vectors = self.embeddings.embed_texts([chunk.text for chunk in text_chunks])
        payload = []
        for chunk, vector in zip(text_chunks, vectors, strict=True):
            metadata = infer_metadata(
                text=chunk.text,
                source=validation.normalized_domain or raw.url,
                organization=organization,
                audience=audience,
                country=country,
                evidence_level=evidence_level,
                publication_date=publication_date,
            )
            payload.append(
                (
                    chunk.ordinal,
                    chunk.text,
                    chunk.token_count,
                    metadata,
                    vector,
                    self.embeddings.model_name,
                )
            )
        chunks_created = await self.repository.replace_chunks(document_id=document_id, chunks=payload)
        return IngestResponse(
            document_id=document_id,
            url=raw.url,
            chunks_created=chunks_created,
            content_hash=hash_value,
            ingested_at=datetime.now(timezone.utc),
        )
