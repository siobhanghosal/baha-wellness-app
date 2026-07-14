from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from bs4 import BeautifulSoup
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.duplicates import DuplicateDetector
from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.acquisition.models import DownloadedResource, ResourceCandidate
from baha_rag.acquisition.quality import DocumentQualityValidator
from baha_rag.acquisition.repository import AcquisitionRepository
from baha_rag.acquisition.source_registry import SOURCE_REGISTRY


RESEARCH_SOURCE_SLUGS = {"europe-pmc", "pubmed", "semantic-scholar"}
SUPPORTED_SUFFIXES: dict[str, tuple[str, str]] = {
    ".docx": ("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
    ".htm": ("html", "text/html"),
    ".html": ("html", "text/html"),
    ".json": ("research_paper", "application/json"),
    ".md": ("video_transcript", "text/markdown"),
    ".pdf": ("pdf", "application/pdf"),
    ".pptx": ("powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"),
    ".srt": ("video_transcript", "text/plain"),
    ".txt": ("video_transcript", "text/plain"),
    ".vtt": ("video_transcript", "text/vtt"),
}
SLUG_OVERRIDES = {
    "american-academy-of-pediatrics": "American Academy of Pediatrics",
    "american-school-counselor-association": "American School Counselor Association",
    "attendance-works": "Attendance Works",
    "casel": "CASEL",
    "common-sense-media": "Common Sense Media",
    "europe-pmc": "Europe PMC",
    "iap-adolescent-health-academy": "IAP Adolescent Health Academy",
    "internet-matters": "Internet Matters",
    "national-association-of-school-psychologists": "National Association of School Psychologists",
    "national-center-for-school-mental-health": "National Center for School Mental Health",
    "national-institute-of-open-schooling": "National Institute of Open Schooling",
    "ncert": "NCERT",
    "ncpcr": "NCPCR",
    "nhs": "NHS",
    "nice": "NICE",
    "nimh": "NIMH",
    "nimhans": "NIMHANS",
    "pubmed": "PubMed",
    "semantic-scholar": "Semantic Scholar",
    "unesco": "UNESCO",
    "unicef": "UNICEF",
    "who": "WHO",
}


class RawStorageBootstrapService:
    def __init__(self, session: AsyncSession, storage_root: str) -> None:
        self.repository = AcquisitionRepository(session)
        self.storage_root = Path(storage_root)
        self.detector = DuplicateDetector()
        self.extractor = KnowledgeExtractionService()
        self.quality = DocumentQualityValidator()
        self.session = session
        self.known_sources = {
            self._slugify(source.organization): source
            for source in SOURCE_REGISTRY
        }

    async def import_directory(
        self,
        *,
        root: str | Path | None = None,
        limit: int | None = None,
        organizations: list[str] | None = None,
    ) -> dict[str, Any]:
        corpus_root = Path(root or self.storage_root).expanduser().resolve()
        requested = {self._slugify(value) for value in organizations or []}
        files = list(self._iter_files(corpus_root, requested=requested, limit=limit))
        counts = {
            "root": str(corpus_root),
            "discovered": len(files),
            "imported": 0,
            "duplicates": 0,
            "rejected": 0,
            "errors": 0,
            "condition_profiles": 0,
            "knowledge_graph_updates": 0,
            "organizations": sorted({path.relative_to(corpus_root).parts[0] for path in files}),
        }
        for index, path in enumerate(files, start=1):
            try:
                result = await self._import_file(corpus_root, path)
                counts[result["status"]] += 1
                counts["condition_profiles"] += result["condition_profiles"]
                counts["knowledge_graph_updates"] += result["knowledge_graph_updates"]
                await self.session.commit()
            except Exception:
                await self.session.rollback()
                counts["errors"] += 1
        await self.repository.refresh_topic_coverage()
        await self.session.commit()
        return counts

    def _iter_files(
        self,
        corpus_root: Path,
        *,
        requested: set[str],
        limit: int | None,
    ) -> list[Path]:
        files: list[Path] = []
        for organization_dir in sorted(path for path in corpus_root.iterdir() if path.is_dir()):
            if requested and self._slugify(organization_dir.name) not in requested:
                continue
            for path in sorted(organization_dir.rglob("*")):
                if not path.is_file():
                    continue
                if path.suffix.lower() not in SUPPORTED_SUFFIXES:
                    continue
                files.append(path)
                if limit and len(files) >= limit:
                    return files
        return files

    async def _import_file(self, corpus_root: Path, path: Path) -> dict[str, int | str]:
        relative_path = path.relative_to(corpus_root)
        organization_slug = relative_path.parts[0]
        organization = self._organization_name(organization_slug)
        source = self.known_sources.get(self._slugify(organization))
        resource_type, content_type = self._resource_details(path, organization_slug)
        candidate_metadata = self._candidate_metadata(path, organization_slug)
        content = path.read_bytes()
        content_hash = self.detector.content_hash(content)
        duplicate = await self.repository.existing_resource_for_hash(content_hash)
        downloaded = DownloadedResource(
            candidate=ResourceCandidate(
                url=path.as_uri(),
                organization=organization,
                source=organization,
                title=candidate_metadata["title"],
                author=candidate_metadata["author"],
                publication_date=candidate_metadata["publication_date"],
                country=source.country if source else None,
                language=candidate_metadata["language"],
                topic=candidate_metadata["topic"],
                resource_type=resource_type,
                content_type=content_type,
                discovered_via="raw_storage_bootstrap",
                metadata={
                    "audience": "general",
                    "bootstrap_relative_path": str(relative_path),
                    **candidate_metadata["metadata"],
                },
            ),
            storage_uri=str(path),
            content_hash=content_hash,
            byte_size=path.stat().st_size,
            etag=None,
            last_modified=None,
            downloaded_at=datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc),
        )
        resource_id = await self.repository.record_download(downloaded)
        quality = self.quality.validate(
            str(path),
            resource_type=resource_type,
            byte_size=downloaded.byte_size,
        )
        await self.repository.mark_resource_quality(
            resource_id,
            status=quality.status,
            errors=quality.errors,
        )
        condition_profiles = 0
        knowledge_graph_updates = 0
        if quality.accepted:
            extracted = self.extractor.extract(
                str(path),
                {
                    "title": downloaded.candidate.title,
                    "topic": downloaded.candidate.topic,
                    "resource_type": resource_type,
                    "audience": "general",
                },
            )
            await self.repository.update_extracted_metadata(resource_id, extracted=extracted)
            condition = extracted.get("condition")
            profile = extracted.get("clinical_profile")
            if condition and profile:
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
                condition_profiles = 1
                knowledge_graph_updates = 1
        if duplicate and duplicate["id"] != resource_id:
            await self.repository.record_duplicate(
                canonical_resource_id=duplicate["id"],
                duplicate_resource_id=resource_id,
                duplicate_type="raw_storage_content_hash",
            )
            status = "duplicates"
        elif quality.accepted:
            status = "imported"
        else:
            status = "rejected"
        return {
            "status": status,
            "condition_profiles": condition_profiles,
            "knowledge_graph_updates": knowledge_graph_updates,
        }

    def _organization_name(self, slug: str) -> str:
        normalized = self._slugify(slug)
        if normalized in SLUG_OVERRIDES:
            return SLUG_OVERRIDES[normalized]
        if normalized in self.known_sources:
            return self.known_sources[normalized].organization
        return " ".join(part.upper() if len(part) <= 4 else part.capitalize() for part in normalized.split("-"))

    def _resource_details(self, path: Path, organization_slug: str) -> tuple[str, str]:
        resource_type, content_type = SUPPORTED_SUFFIXES[path.suffix.lower()]
        if path.suffix.lower() == ".json" and self._slugify(organization_slug) not in RESEARCH_SOURCE_SLUGS:
            return "html", "application/json"
        return resource_type, content_type

    def _candidate_metadata(self, path: Path, organization_slug: str) -> dict[str, Any]:
        metadata: dict[str, Any] = {
            "author": None,
            "language": "en",
            "metadata": {},
            "publication_date": None,
            "title": path.stem,
            "topic": None,
        }
        suffix = path.suffix.lower()
        if suffix in {".html", ".htm"}:
            try:
                soup = BeautifulSoup(path.read_text(errors="ignore"), "html.parser")
                title = soup.title.string.strip() if soup.title and soup.title.string else None
                metadata["title"] = title or metadata["title"]
            except Exception:
                pass
        elif suffix == ".json":
            parsed = self._json_metadata(path, organization_slug)
            metadata.update(parsed)
        return metadata

    def _json_metadata(self, path: Path, organization_slug: str) -> dict[str, Any]:
        try:
            payload = json.loads(path.read_text(errors="ignore"))
        except (OSError, json.JSONDecodeError):
            return {
                "author": None,
                "language": "en",
                "metadata": {},
                "publication_date": None,
                "title": path.stem,
                "topic": None,
            }
        authors = payload.get("authors") or payload.get("author") or []
        if isinstance(authors, str):
            author_value = authors
        elif isinstance(authors, list):
            names = []
            for author in authors[:6]:
                if isinstance(author, str):
                    names.append(author)
                elif isinstance(author, dict):
                    names.append(
                        author.get("name")
                        or author.get("full_name")
                        or ", ".join(
                            value
                            for value in (author.get("fore_name"), author.get("last_name"))
                            if value
                        )
                    )
            author_value = ", ".join(name for name in names if name) or None
        else:
            author_value = None
        publication_date = (
            payload.get("publication_date")
            or payload.get("pub_date")
            or payload.get("year")
        )
        metadata = {
            key: payload.get(key)
            for key in ("doi", "paper_id", "pubmed_id", "pmcid", "source_id", "journal")
            if payload.get(key)
        }
        metadata["raw_source_slug"] = self._slugify(organization_slug)
        return {
            "author": author_value,
            "language": payload.get("language") or "en",
            "metadata": metadata,
            "publication_date": str(publication_date) if publication_date else None,
            "title": payload.get("title") or path.stem,
            "topic": payload.get("topic"),
        }

    def _slugify(self, value: str) -> str:
        return value.strip().lower().replace("_", "-").replace(" ", "-")
