from __future__ import annotations

import re
import shutil
import tempfile
import zipfile
from dataclasses import dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import quote

from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.duplicates import DuplicateDetector
from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.acquisition.models import DownloadedResource, ResourceCandidate
from baha_rag.acquisition.priority_sources import PrioritySourceRegistry
from baha_rag.acquisition.quality import DocumentQualityValidator
from baha_rag.acquisition.repository import AcquisitionRepository
from baha_rag.acquisition.storage import StorageService


SUPPORTED_EXTENSIONS = {
    ".pdf": "pdf",
    ".docx": "docx",
    ".pptx": "powerpoint",
    ".txt": "video_transcript",
    ".md": "video_transcript",
    ".vtt": "video_transcript",
    ".srt": "video_transcript",
}
ARCHIVE_EXTENSION = ".zip"
MAX_ARCHIVE_MEMBERS = 500
MAX_ARCHIVE_MEMBER_BYTES = 250 * 1024 * 1024
MAX_ARCHIVE_TOTAL_BYTES = 1024 * 1024 * 1024


@dataclass(frozen=True)
class ManualResourceMetadata:
    organization: str
    reviewer: str
    source: str
    publication_date: date | None = None
    topic: str | None = None
    audience: str = "general"
    title: str | None = None
    language: str = "en"


class ManualResourceIngestionService:
    def __init__(self, session: AsyncSession, storage_root: str) -> None:
        self.repository = AcquisitionRepository(session)
        root = Path(storage_root)
        self.storage = StorageService(str(root / "manual_resource_ingestion"))
        self.priority_registry = PrioritySourceRegistry()
        self.detector = DuplicateDetector()
        self.extractor = KnowledgeExtractionService()
        self.quality = DocumentQualityValidator()

    async def import_paths(
        self,
        paths: Iterable[str | Path],
        metadata: ManualResourceMetadata,
    ) -> dict[str, Any]:
        source = self.priority_registry.resolve(metadata.organization)
        if metadata.audience not in {
            "parent", "teacher", "counselor", "adolescent", "administrator", "general"
        }:
            raise ValueError(f"Unsupported audience: {metadata.audience}")
        path_list = [Path(path).expanduser().resolve() for path in paths]
        files = list(self._collect_files(path_list))
        if not files:
            raise ValueError("No supported manual resources were found")
        batch_id = await self.repository.create_manual_batch(
            organization=source.organization,
            reviewer=metadata.reviewer,
            source=metadata.source,
            submitted_count=len(files),
            metadata={"input_paths": [str(path) for path in path_list]},
        )
        counts = {"imported": 0, "duplicates": 0, "rejected": 0, "errors": 0}
        try:
            for path in files:
                try:
                    if path.suffix.lower() == ARCHIVE_EXTENSION:
                        archive_counts = await self._import_archive(path, metadata, batch_id)
                        for key, value in archive_counts.items():
                            counts[key] += value
                    else:
                        result = await self._import_single(path, metadata, batch_id)
                        counts[result] += 1
                except Exception as exc:
                    counts["errors"] += 1
                    await self.repository.record_manual_error(
                        batch_id=batch_id,
                        organization=source.organization,
                        reviewer=metadata.reviewer,
                        source=metadata.source,
                        original_filename=path.name,
                        resource_type=self._resource_type_or_archive(path),
                        publication_date=metadata.publication_date,
                        topic=metadata.topic,
                        audience=metadata.audience,
                        error=str(exc),
                        is_baha=source.is_baha,
                        is_iap=source.is_iap,
                    )
            status = "completed" if counts["errors"] == 0 else "completed_with_errors"
        except Exception:
            status = "failed"
            raise
        finally:
            await self.repository.complete_manual_batch(batch_id, status=status, **counts)
        await self.repository.refresh_topic_coverage()
        return {"batch_id": str(batch_id), "submitted": len(files), **counts}

    def _collect_files(self, paths: list[Path]) -> Iterable[Path]:
        for path in paths:
            if not path.exists():
                raise FileNotFoundError(path)
            if path.is_dir():
                for child in sorted(path.rglob("*")):
                    if child.is_file() and (
                        child.suffix.lower() in SUPPORTED_EXTENSIONS
                        or child.suffix.lower() == ARCHIVE_EXTENSION
                    ):
                        yield child
            elif path.is_file():
                if (
                    path.suffix.lower() in SUPPORTED_EXTENSIONS
                    or path.suffix.lower() == ARCHIVE_EXTENSION
                ):
                    yield path
                else:
                    raise ValueError(f"Unsupported manual resource type: {path.suffix}")

    async def _import_archive(
        self,
        archive: Path,
        metadata: ManualResourceMetadata,
        batch_id,
    ) -> dict[str, int]:
        counts = {"imported": 0, "duplicates": 0, "rejected": 0, "errors": 0}
        with tempfile.TemporaryDirectory(prefix="baha-manual-") as temp_dir:
            extracted = self._safe_extract_archive(archive, Path(temp_dir))
            for path in extracted:
                try:
                    result = await self._import_single(
                        path,
                        metadata,
                        batch_id,
                        archive_name=archive.name,
                    )
                    counts[result] += 1
                except Exception as exc:
                    counts["errors"] += 1
                    priority = self.priority_registry.resolve(metadata.organization)
                    await self.repository.record_manual_error(
                        batch_id=batch_id,
                        organization=priority.organization,
                        reviewer=metadata.reviewer,
                        source=metadata.source,
                        original_filename=f"{archive.name}:{path.name}",
                        resource_type=self._resource_type(path),
                        publication_date=metadata.publication_date,
                        topic=metadata.topic,
                        audience=metadata.audience,
                        error=str(exc),
                        is_baha=priority.is_baha,
                        is_iap=priority.is_iap,
                    )
            if not extracted:
                raise ValueError(f"Archive contains no supported resources: {archive.name}")
        return counts

    async def _import_single(
        self,
        path: Path,
        metadata: ManualResourceMetadata,
        batch_id,
        archive_name: str | None = None,
    ) -> str:
        resource_type = self._resource_type(path)
        content = path.read_bytes()
        content_hash = self.detector.content_hash(content)
        priority = self.priority_registry.resolve(metadata.organization)
        duplicate = await self.repository.existing_resource_for_hash(content_hash)
        storage_uri, stored_hash = self.storage.store(
            url=path.as_uri(),
            organization=priority.organization,
            content=content,
            extension=path.suffix.lower(),
        )
        manual_url = (
            f"manual://{self._slug(priority.organization)}/{stored_hash}/{quote(path.name)}"
        )
        candidate = ResourceCandidate(
            url=manual_url,
            organization=priority.organization,
            source=metadata.source,
            title=metadata.title or path.stem,
            publication_date=metadata.publication_date.isoformat()
            if metadata.publication_date
            else None,
            country="India" if priority.priority_rank <= 3 else None,
            language=metadata.language,
            topic=metadata.topic,
            resource_type=resource_type,
            content_type=self._content_type(path),
            discovered_via="manual_resource_ingestion",
            metadata={
                "audience": metadata.audience,
                "reviewer": metadata.reviewer,
                "original_filename": path.name,
                "archive_name": archive_name,
                "is_baha_resource": priority.is_baha,
                "is_iap_resource": priority.is_iap,
                "priority_rank": priority.priority_rank,
            },
        )
        downloaded = DownloadedResource(
            candidate=candidate,
            storage_uri=storage_uri,
            content_hash=stored_hash,
            byte_size=len(content),
            etag=None,
            last_modified=None,
            downloaded_at=datetime.now(timezone.utc),
        )
        resource_id = await self.repository.record_manual_download(
            downloaded,
            reviewer=metadata.reviewer,
            audience=metadata.audience,
            priority_rank=priority.priority_rank,
            is_baha=priority.is_baha,
            is_iap=priority.is_iap,
        )
        quality = self.quality.validate(
            storage_uri,
            resource_type=resource_type,
            byte_size=len(content),
        )
        await self.repository.mark_resource_quality(
            resource_id,
            status=quality.status,
            errors=quality.errors,
        )
        extracted: dict[str, Any] = {}
        status = "rejected"
        if quality.accepted:
            extracted = self.extractor.extract(
                storage_uri,
                {
                    "title": candidate.title,
                    "topic": candidate.topic,
                    "resource_type": resource_type,
                },
            )
            if metadata.topic:
                extracted["topic"] = metadata.topic
            extracted["audience"] = metadata.audience
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
            status = "duplicates" if duplicate else "imported"
        await self.repository.record_manual_ingestion(
            batch_id=batch_id,
            resource_id=resource_id,
            organization=priority.organization,
            reviewer=metadata.reviewer,
            resource_type=resource_type,
            original_filename=path.name,
            publication_date=metadata.publication_date,
            source=metadata.source,
            topic=extracted.get("topic") or metadata.topic,
            audience=metadata.audience,
            content_hash=stored_hash,
            storage_uri=storage_uri,
            status="duplicate" if duplicate else quality.status,
            is_baha=priority.is_baha,
            is_iap=priority.is_iap,
            metadata={"archive_name": archive_name, "quality_errors": list(quality.errors)},
        )
        if duplicate:
            await self.repository.record_duplicate(
                canonical_resource_id=duplicate["id"],
                duplicate_resource_id=resource_id,
                duplicate_type="manual_content_hash",
            )
        await self.repository.set_review_priority(
            resource_id,
            priority=100 - priority.priority_rank,
            reason=(
                f"Manual {priority.organization} resource; clinical and provenance review required"
            ),
        )
        return status

    def _safe_extract_archive(self, archive: Path, destination: Path) -> list[Path]:
        destination.mkdir(parents=True, exist_ok=True)
        extracted: list[Path] = []
        total_size = 0
        with zipfile.ZipFile(archive) as bundle:
            members = [member for member in bundle.infolist() if not member.is_dir()]
            if len(members) > MAX_ARCHIVE_MEMBERS:
                raise ValueError("ZIP archive exceeds the 500-file safety limit")
            for member in members:
                total_size += member.file_size
                if member.file_size > MAX_ARCHIVE_MEMBER_BYTES:
                    raise ValueError(f"ZIP member is too large: {member.filename}")
                if total_size > MAX_ARCHIVE_TOTAL_BYTES:
                    raise ValueError("ZIP archive exceeds the 1 GiB expanded-size limit")
                relative = Path(member.filename)
                if relative.is_absolute() or ".." in relative.parts:
                    raise ValueError(f"Unsafe ZIP member path: {member.filename}")
                if relative.suffix.lower() not in SUPPORTED_EXTENSIONS:
                    continue
                target = (destination / relative).resolve()
                if destination.resolve() not in target.parents:
                    raise ValueError(f"Unsafe ZIP member path: {member.filename}")
                target.parent.mkdir(parents=True, exist_ok=True)
                with bundle.open(member) as source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)
                extracted.append(target)
        return extracted

    def _resource_type(self, path: Path) -> str:
        try:
            return SUPPORTED_EXTENSIONS[path.suffix.lower()]
        except KeyError as exc:
            raise ValueError(f"Unsupported manual resource type: {path.suffix}") from exc

    def _resource_type_or_archive(self, path: Path) -> str:
        if path.suffix.lower() == ARCHIVE_EXTENSION:
            return "zip_archive"
        return self._resource_type(path)

    def _content_type(self, path: Path) -> str:
        return {
            ".pdf": "application/pdf",
            ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            ".txt": "text/plain",
            ".md": "text/markdown",
            ".vtt": "text/vtt",
            ".srt": "application/x-subrip",
        }[path.suffix.lower()]

    def _slug(self, value: str) -> str:
        return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
