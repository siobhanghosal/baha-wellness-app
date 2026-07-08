from __future__ import annotations

from dataclasses import dataclass

import httpx


@dataclass(frozen=True)
class RawDocument:
    url: str
    content: bytes
    content_type: str
    etag: str | None
    last_modified: str | None


class DocumentCrawler:
    def __init__(self, timeout_seconds: float = 30.0) -> None:
        self.timeout_seconds = timeout_seconds

    async def fetch(self, url: str, etag: str | None = None) -> RawDocument | None:
        headers = {"User-Agent": "BAHA-Wellness-RAG/0.1"}
        if etag:
            headers["If-None-Match"] = etag
        async with httpx.AsyncClient(timeout=self.timeout_seconds, follow_redirects=True) as client:
            response = await client.get(url, headers=headers)
        if response.status_code == 304:
            return None
        response.raise_for_status()
        return RawDocument(
            url=str(response.url),
            content=response.content,
            content_type=response.headers.get("content-type", "application/octet-stream"),
            etag=response.headers.get("etag"),
            last_modified=response.headers.get("last-modified"),
        )
