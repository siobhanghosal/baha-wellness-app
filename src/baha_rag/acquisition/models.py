from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class ResourceCandidate:
    url: str
    organization: str
    source: str
    title: str | None = None
    author: str | None = None
    publication_date: str | None = None
    country: str | None = None
    language: str = "en"
    topic: str | None = None
    subtopic: str | None = None
    resource_type: str = "html"
    content_type: str | None = None
    discovered_via: str = "crawler"
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class DownloadedResource:
    candidate: ResourceCandidate
    storage_uri: str
    content_hash: str
    byte_size: int
    etag: str | None
    last_modified: str | None
    downloaded_at: datetime
