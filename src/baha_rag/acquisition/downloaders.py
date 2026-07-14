from __future__ import annotations

import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

import aiohttp

from baha_rag.acquisition.campaign import classify_resource, source_weight
from baha_rag.acquisition.metadata import MetadataExtractionPipeline
from baha_rag.acquisition.models import DownloadedResource, ResourceCandidate
from baha_rag.acquisition.storage import StorageService
from baha_rag.acquisition.topics import classify_topic


class DownloadError(RuntimeError):
    pass


UNSUPPORTED_MEDIA_EXTENSIONS = {
    ".avi",
    ".gif",
    ".jpeg",
    ".jpg",
    ".m4a",
    ".mov",
    ".mp3",
    ".mp4",
    ".png",
    ".svg",
    ".webm",
    ".webp",
}


class BaseDownloader:
    def __init__(self, storage: StorageService, *, timeout_seconds: float = 45.0, retries: int = 3) -> None:
        self.storage = storage
        self.timeout_seconds = timeout_seconds
        self.retries = retries
        self.metadata = MetadataExtractionPipeline()

    async def download(self, candidate: ResourceCandidate) -> DownloadedResource:
        headers = {"User-Agent": "BAHA-Wellness-Acquisition/0.1"}
        last_error: Exception | None = None
        timeout = aiohttp.ClientTimeout(total=self.timeout_seconds)
        async with aiohttp.ClientSession(
            timeout=timeout,
            headers=headers,
            max_field_size=32768,
            max_line_size=32768,
        ) as session:
            for attempt in range(1, self.retries + 1):
                try:
                    async with session.get(candidate.url, allow_redirects=True) as response:
                        response.raise_for_status()
                        content_type = str(response.headers.get("content-type", ""))
                        if not self._is_supported_response(
                            str(response.url),
                            content_type,
                        ):
                            raise DownloadError(
                                f"Unsupported media response for {candidate.url}: {content_type}"
                            )
                        content = await response.read()
                        return self._to_downloaded(candidate, str(response.url), response.headers, content)
                except DownloadError as exc:
                    last_error = exc
                    break
                except aiohttp.ClientResponseError as exc:
                    last_error = exc
                    if not self._is_retryable_status(exc.status):
                        break
                    if attempt < self.retries:
                        await asyncio.sleep(min(2 ** (attempt - 1), 8))
                except Exception as exc:
                    last_error = exc
                    if attempt == self.retries:
                        break
                    await asyncio.sleep(min(2 ** (attempt - 1), 8))
        raise DownloadError(f"Could not download {candidate.url}: {last_error}") from last_error

    def _to_downloaded(
        self,
        candidate: ResourceCandidate,
        final_url: str,
        headers: aiohttp.typedefs.LooseHeaders,
        content: bytes,
    ) -> DownloadedResource:
        content_type = str(headers.get("content-type", candidate.content_type or ""))
        extension = self._extension(candidate.url, content_type)
        enriched = self._enrich_candidate(candidate, content, content_type)
        storage_uri, content_hash = self.storage.store(
            url=final_url,
            organization=candidate.organization,
            content=content,
            extension=extension,
        )
        return DownloadedResource(
            candidate=enriched,
            storage_uri=storage_uri,
            content_hash=content_hash,
            byte_size=len(content),
            etag=headers.get("etag"),
            last_modified=headers.get("last-modified"),
            downloaded_at=datetime.now(timezone.utc),
        )

    def _enrich_candidate(
        self,
        candidate: ResourceCandidate,
        content: bytes,
        content_type: str,
    ) -> ResourceCandidate:
        suffix = Path(urlparse(candidate.url).path).suffix.lower()
        if suffix == ".pdf" or ("pdf" in content_type.lower() and suffix not in {".ppt", ".pptx"}):
            extracted = self.metadata.from_pdf(content, candidate.url)
            resource_type = "pdf"
        elif suffix in {".ppt", ".pptx"}:
            extracted = {
                "title": candidate.title or Path(urlparse(candidate.url).path).stem,
                "author": candidate.author,
                "publication_date": None,
                "language": candidate.language,
            }
            resource_type = "powerpoint"
        elif suffix in {".doc", ".docx"}:
            extracted = {
                "title": candidate.title or Path(urlparse(candidate.url).path).stem,
                "author": candidate.author,
                "publication_date": None,
                "language": candidate.language,
            }
            resource_type = "document"
        elif "html" in content_type.lower() or "text" in content_type.lower():
            extracted = self.metadata.from_html(content, candidate.url)
            resource_type = "html"
        else:
            extracted = {"title": candidate.title or candidate.url, "author": candidate.author, "publication_date": None, "language": candidate.language}
            resource_type = candidate.resource_type
        topic, subtopic = classify_topic(" ".join(str(value or "") for value in extracted.values()))
        audience, resource_class = classify_resource(
            " ".join(
                str(value or "")
                for value in (
                    candidate.title,
                    extracted.get("title"),
                    candidate.url,
                    candidate.metadata.get("resource_class"),
                )
            )
        )
        return ResourceCandidate(
            url=candidate.url,
            organization=candidate.organization,
            source=candidate.source,
            title=candidate.title or extracted.get("title"),
            author=candidate.author or extracted.get("author"),
            publication_date=candidate.publication_date or extracted.get("publication_date"),
            country=candidate.country,
            language=extracted.get("language") or candidate.language,
            topic=candidate.topic or topic,
            subtopic=candidate.subtopic or subtopic,
            resource_type=resource_type,
            content_type=content_type,
            discovered_via=candidate.discovered_via,
            metadata={
                **candidate.metadata,
                "downloaded_content_type": content_type,
                "audience": candidate.metadata.get("audience") or audience,
                "resource_class": candidate.metadata.get("resource_class") or resource_class,
                "source_weight": source_weight(candidate.organization),
            },
        )

    def _extension(self, url: str, content_type: str) -> str:
        suffix = Path(urlparse(url).path).suffix
        if suffix:
            return suffix
        lowered = content_type.lower()
        if "pdf" in lowered:
            return ".pdf"
        if "html" in lowered:
            return ".html"
        if "json" in lowered:
            return ".json"
        if "csv" in lowered:
            return ".csv"
        return ".bin"

    def _is_supported_response(self, url: str, content_type: str) -> bool:
        suffix = Path(urlparse(url).path).suffix.lower()
        lowered_type = content_type.lower()
        return (
            suffix not in UNSUPPORTED_MEDIA_EXTENSIONS
            and not lowered_type.startswith(("image/", "audio/", "video/"))
        )

    def _is_retryable_status(self, status: int) -> bool:
        return status in {408, 425, 429} or status >= 500


class PDFDownloader(BaseDownloader):
    async def download(self, candidate: ResourceCandidate) -> DownloadedResource:
        downloaded = await super().download(candidate)
        if downloaded.candidate.resource_type != "pdf":
            raise DownloadError(f"Expected PDF but got {downloaded.candidate.content_type}")
        return downloaded


class ResearchPaperDownloader(BaseDownloader):
    async def download(self, candidate: ResourceCandidate) -> DownloadedResource:
        # PubMed is a citation index; E-utilities metadata is the approved record.
        if candidate.organization == "PubMed":
            return self._metadata_record(candidate)
        if candidate.metadata.get("is_open_access") is not True:
            return self._metadata_record(candidate)
        try:
            return await super().download(candidate)
        except DownloadError:
            # Preserve traceable API metadata when an external OA host expires or blocks robots.
            return self._metadata_record(candidate)

    def _metadata_record(self, candidate: ResourceCandidate) -> DownloadedResource:
        payload = {
            "title": candidate.title,
            "author": candidate.author,
            "organization": candidate.organization,
            "source": candidate.source,
            "url": candidate.url,
            "publication_date": candidate.publication_date,
            "topic": candidate.topic,
            "subtopic": candidate.subtopic,
            **candidate.metadata,
        }
        content = json.dumps(payload, ensure_ascii=True, sort_keys=True, default=str).encode()
        return self._to_downloaded(
            candidate,
            candidate.url,
            {"content-type": "application/json"},
            content,
        )


class DatasetDownloader(BaseDownloader):
    pass
