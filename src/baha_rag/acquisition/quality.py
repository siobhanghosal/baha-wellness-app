from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from bs4 import BeautifulSoup
from pypdf import PdfReader

from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService


@dataclass(frozen=True)
class QualityResult:
    accepted: bool
    status: str
    errors: tuple[str, ...] = ()


class DocumentQualityValidator:
    def validate(self, storage_uri: str, *, resource_type: str, byte_size: int) -> QualityResult:
        errors: list[str] = []
        path = Path(storage_uri)
        if path.suffix.lower() in {
            ".avi", ".gif", ".jpeg", ".jpg", ".m4a", ".mov", ".mp3", ".mp4",
            ".png", ".svg", ".webm", ".webp",
        }:
            errors.append("unsupported_media")
        if byte_size == 0 or not path.exists():
            errors.append("empty_or_missing_file")
        if byte_size < 500 and resource_type != "research_paper":
            errors.append("thin_content")
        if resource_type == "pdf":
            errors.extend(self._pdf_errors(path))
        elif resource_type == "research_paper" and path.suffix.lower() == ".json":
            errors.extend(self._research_metadata_errors(path))
        elif resource_type in {"html", "research_paper"}:
            errors.extend(self._html_errors(path))
        elif resource_type in {"docx", "document", "powerpoint", "video_transcript"}:
            extraction_type = "docx" if path.suffix.lower() == ".docx" else resource_type
            if path.suffix.lower() != ".doc":
                errors.extend(self._office_or_transcript_errors(path, extraction_type))
        accepted = not errors
        return QualityResult(
            accepted=accepted,
            status="accepted" if accepted else "rejected",
            errors=tuple(errors),
        )

    def _pdf_errors(self, path: Path) -> list[str]:
        try:
            reader = PdfReader(str(path))
            if len(reader.pages) == 0:
                return ["corrupted_pdf"]
        except Exception:
            return ["corrupted_pdf"]
        return []

    def _html_errors(self, path: Path) -> list[str]:
        try:
            text = BeautifulSoup(path.read_text(errors="ignore"), "html.parser").get_text(" ", strip=True)
        except Exception:
            return ["unreadable_html"]
        if len(text.split()) < 50:
            return ["thin_content"]
        return []

    def _research_metadata_errors(self, path: Path) -> list[str]:
        try:
            payload = json.loads(path.read_text(errors="ignore"))
        except (OSError, json.JSONDecodeError):
            return ["unreadable_research_metadata"]
        if not payload.get("title"):
            return ["missing_research_title"]
        if not any(payload.get(key) for key in ("pubmed_id", "source_id", "paper_id", "doi")):
            return ["missing_research_identifier"]
        return []

    def _office_or_transcript_errors(self, path: Path, resource_type: str) -> list[str]:
        try:
            text = KnowledgeExtractionService()._read_text(str(path), resource_type)
        except Exception:
            return [f"unreadable_{resource_type}"]
        if not text.strip():
            return [f"unreadable_{resource_type}"]
        if len(text.split()) < 20:
            return ["thin_content"]
        return []
