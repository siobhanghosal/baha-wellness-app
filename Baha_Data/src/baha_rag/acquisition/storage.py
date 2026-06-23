from __future__ import annotations

from pathlib import Path
from urllib.parse import urlparse

from baha_rag.acquisition.duplicates import DuplicateDetector


class StorageService:
    def __init__(self, root: str) -> None:
        self.root = Path(root)
        self.detector = DuplicateDetector()

    def store(self, *, url: str, organization: str, content: bytes, extension: str | None = None) -> tuple[str, str]:
        content_hash = self.detector.content_hash(content)
        parsed = urlparse(url)
        suffix = extension or Path(parsed.path).suffix or ".bin"
        org_slug = organization.lower().replace(" ", "-")
        target = self.root / org_slug / content_hash[:2] / f"{content_hash}{suffix}"
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(content)
        return str(target), content_hash
