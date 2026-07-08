from __future__ import annotations

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.downloaders import (
    BaseDownloader,
    DatasetDownloader,
    DownloadError,
    PDFDownloader,
    ResearchPaperDownloader,
)
from baha_rag.acquisition.coverage import GapQueryGenerator
from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.acquisition.models import ResourceCandidate
from baha_rag.acquisition.quality import DocumentQualityValidator
from baha_rag.acquisition.repository import AcquisitionRepository
from baha_rag.acquisition.research.discovery import ResearchDiscoveryService
from baha_rag.acquisition.source_registry import SourceRegistryService
from baha_rag.acquisition.storage import StorageService
from baha_rag.acquisition.topics import DISCOVERY_TOPICS
from baha_rag.acquisition.update_detection import IncrementalUpdateDetector
from baha_rag.config import Settings


class AcquisitionService:
    def __init__(self, session: AsyncSession, settings: Settings) -> None:
        self.repository = AcquisitionRepository(session)
        self.settings = settings
        self.storage = StorageService(settings.storage_root)

    async def seed_sources(self) -> int:
        registry = SourceRegistryService()
        count = 0
        for source in registry.all_sources():
            await self.repository.seed_source(source)
            count += 1
        return count

    async def discover_research(
        self,
        *,
        limit_per_topic: int = 25,
        queries: list[str] | None = None,
    ) -> int:
        candidates = await ResearchDiscoveryService().discover(
            limit_per_topic=limit_per_topic,
            queries=queries,
        )
        for candidate in candidates:
            await self.repository.upsert_candidate(candidate)
        return len(candidates)

    async def discover_gap_research(
        self,
        *,
        limit_per_query: int = 25,
        max_topics: int = 10,
    ) -> dict[str, Any]:
        gaps = await self.repository.topic_gaps()
        selected = gaps[:max_topics]
        queries = [
            query
            for gap in selected
            for query in GapQueryGenerator().generate(gap["topic"])
        ]
        candidates = await ResearchDiscoveryService().discover(
            limit_per_topic=limit_per_query,
            queries=queries,
        )
        for candidate in candidates:
            await self.repository.upsert_candidate(candidate)
        return {
            "topics": [gap["topic"] for gap in selected],
            "queries": len(queries),
            "candidates": len(candidates),
        }

    async def download_due_candidates(
        self,
        *,
        limit: int = 100,
        resource_type: str | None = None,
        organization: str | None = None,
    ) -> dict[str, int]:
        candidates = await self.repository.get_due_candidates(
            limit,
            resource_type=resource_type,
            organization=organization,
        )
        downloaded = 0
        errors = 0
        skipped = 0
        for row in candidates:
            candidate = self._candidate_from_row(row)
            try:
                async with self.repository.session.begin_nested():
                    previous = await self.repository.existing_resource_for_url(row["normalized_url"])
                    downloader = self._downloader_for(candidate)
                    resource = await downloader.download(candidate)
                    if previous and not IncrementalUpdateDetector().changed(
                        previous_hash=previous.get("content_hash"),
                        current_hash=resource.content_hash,
                        previous_etag=previous.get("etag"),
                        current_etag=resource.etag,
                        previous_last_modified=previous.get("last_modified"),
                        current_last_modified=resource.last_modified,
                    ):
                        await self.repository.mark_candidate_status(row["id"], "unchanged")
                        skipped += 1
                        continue
                    duplicate = await self.repository.existing_resource_for_hash(resource.content_hash)
                    resource_id = await self.repository.record_download(resource)
                    quality = DocumentQualityValidator().validate(
                        resource.storage_uri,
                        resource_type=resource.candidate.resource_type,
                        byte_size=resource.byte_size,
                    )
                    await self.repository.mark_resource_quality(
                        resource_id,
                        status=quality.status,
                        errors=quality.errors,
                    )
                    if quality.accepted:
                        extraction_result = await self._extract_resource(
                            resource_id=resource_id,
                            storage_uri=resource.storage_uri,
                            candidate=resource.candidate,
                        )
                        if not extraction_result.get("topic"):
                            await self.repository.mark_resource_quality(
                                resource_id,
                                status="rejected",
                                errors=("irrelevant_topic",),
                            )
                    resource_row = await self.repository.existing_resource_for_url(row["normalized_url"])
                    if duplicate and resource_row:
                        await self.repository.record_duplicate(
                            canonical_resource_id=duplicate["id"],
                            duplicate_resource_id=resource_row["id"],
                            duplicate_type="content_hash",
                        )
                    await self.repository.mark_candidate_status(row["id"], "downloaded")
                    downloaded += 1
            except DownloadError as exc:
                async with self.repository.session.begin_nested():
                    await self.repository.mark_candidate_status(row["id"], "failed", str(exc))
                errors += 1
            except Exception as exc:
                async with self.repository.session.begin_nested():
                    await self.repository.mark_candidate_status(row["id"], "failed", str(exc))
                errors += 1
            finally:
                # Keep long source batches restartable and release profile/graph row locks.
                await self.repository.session.commit()
        await self.repository.refresh_topic_coverage()
        result = {"downloaded": downloaded, "errors": errors, "skipped": skipped}
        if downloaded and self.settings.embedding_auto_index:
            from baha_rag.embeddings.indexer import IncrementalEmbeddingIndexer

            embedding_result = await IncrementalEmbeddingIndexer(
                self.repository.session,
                self.settings,
            ).index(
                resource_limit=downloaded,
                condition_limit=100,
                knowledge_limit=5000,
            )
            result["embedded_resources"] = embedding_result["resources_embedded"]
            result["embedded_chunks"] = embedding_result["chunks_embedded"]
        return result

    async def backfill_quality_and_extraction(
        self,
        *,
        limit: int = 1000,
        force: bool = False,
        organization: str | None = None,
    ) -> dict[str, int]:
        rows = await self.repository.resources_for_extraction(
            limit=limit,
            only_unchecked=not force,
            organization=organization,
        )
        accepted = 0
        rejected = 0
        extracted = 0
        for row in rows:
            quality = DocumentQualityValidator().validate(
                row["storage_uri"],
                resource_type=row["resource_type"],
                byte_size=row["byte_size"],
            )
            await self.repository.mark_resource_quality(
                row["id"],
                status=quality.status,
                errors=quality.errors,
            )
            if not quality.accepted:
                rejected += 1
                continue
            accepted += 1
            extraction_result = await self._extract_resource(
                resource_id=row["id"],
                storage_uri=row["storage_uri"],
                candidate=self._candidate_from_row(row),
            )
            if not extraction_result.get("topic"):
                await self.repository.mark_resource_quality(
                    row["id"],
                    status="rejected",
                    errors=("irrelevant_topic",),
                )
                rejected += 1
                accepted -= 1
                continue
            extracted += 1
        await self.repository.refresh_topic_coverage()
        return {"accepted": accepted, "rejected": rejected, "extracted": extracted}

    async def coverage_gaps(self) -> list[dict[str, Any]]:
        return await self.repository.topic_gaps()

    async def embedding_readiness(self) -> dict[str, Any]:
        return await self.repository.embedding_readiness()

    async def inventory_dashboard(self) -> dict[str, Any]:
        return await self.repository.source_inventory()

    async def priority_dashboard(self) -> dict[str, Any]:
        return await self.repository.priority_coverage_dashboard()

    async def final_report(self) -> dict[str, Any]:
        return await self.repository.final_report(list(DISCOVERY_TOPICS))

    async def phase_report(self) -> dict[str, Any]:
        report = await self.repository.phase_report()
        report["embedding_readiness"] = await self.repository.embedding_readiness()
        return report

    async def _extract_resource(
        self,
        *,
        resource_id,
        storage_uri: str,
        candidate: ResourceCandidate,
    ) -> dict[str, Any]:
        extracted = KnowledgeExtractionService().extract(
            storage_uri,
            {
                "title": candidate.title,
                "topic": candidate.topic,
                "subtopic": candidate.subtopic,
                "resource_type": candidate.resource_type,
                "audience": candidate.metadata.get("audience"),
            },
        )
        await self.repository.update_extracted_metadata(resource_id, extracted=extracted)
        profiles = extracted.get("clinical_profiles") or {}
        if not profiles and extracted.get("condition") and extracted.get("clinical_profile"):
            profiles = {extracted["condition"]: extracted["clinical_profile"]}
        for condition, profile in profiles.items():
            await self.repository.upsert_condition_profile(
                condition=condition,
                profile=profile,
                resource_id=resource_id,
            )
            await self.repository.upsert_knowledge_graph(
                condition=condition,
                profile=profile,
                resource_id=resource_id,
            )
        if extracted.get("skills"):
            await self.repository.upsert_skill_knowledge_graph(
                skills=extracted["skills"],
                extracted=extracted,
                resource_id=resource_id,
            )
        return extracted

    def _downloader_for(self, candidate: ResourceCandidate) -> BaseDownloader:
        if candidate.resource_type == "pdf":
            return PDFDownloader(self.storage)
        if candidate.resource_type == "research_paper":
            return ResearchPaperDownloader(self.storage)
        if candidate.resource_type == "dataset":
            return DatasetDownloader(self.storage)
        return BaseDownloader(self.storage)

    def _candidate_from_row(self, row: dict[str, Any]) -> ResourceCandidate:
        return ResourceCandidate(
            url=row["url"],
            organization=row["organization"],
            source=row["source"],
            title=row.get("title"),
            author=row.get("author"),
            publication_date=row.get("publication_date_raw"),
            country=row.get("country"),
            language=row.get("language") or "en",
            topic=row.get("topic"),
            subtopic=row.get("subtopic"),
            resource_type=row.get("resource_type") or "html",
            content_type=row.get("content_type"),
            discovered_via=row.get("discovered_via") or "database",
            metadata=row.get("metadata") or {},
        )
