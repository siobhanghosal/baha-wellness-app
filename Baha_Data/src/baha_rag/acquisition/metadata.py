from __future__ import annotations

from datetime import date
from email.utils import parsedate_to_datetime

from bs4 import BeautifulSoup
from pypdf import PdfReader

from io import BytesIO


def parse_http_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return parsedate_to_datetime(value).date()
    except Exception:
        return None


class MetadataExtractionPipeline:
    def from_html(self, content: bytes, url: str) -> dict[str, str | None]:
        soup = BeautifulSoup(content.decode("utf-8", errors="ignore"), "html.parser")
        title = self._meta(soup, "citation_title") or self._meta(soup, "dc.title")
        if not title and soup.title:
            title = soup.title.get_text(" ", strip=True)
        author = self._meta(soup, "citation_author") or self._meta(soup, "dc.creator")
        publication_date = (
            self._meta(soup, "citation_publication_date")
            or self._meta(soup, "article:published_time")
            or self._meta(soup, "dc.date")
        )
        language = soup.html.get("lang") if soup.html else None
        return {
            "title": title or url,
            "author": author,
            "publication_date": publication_date,
            "language": language or "en",
        }

    def from_pdf(self, content: bytes, url: str) -> dict[str, str | None]:
        reader = PdfReader(BytesIO(content))
        metadata = reader.metadata
        return {
            "title": str(metadata.title) if metadata and metadata.title else url.rsplit("/", 1)[-1],
            "author": str(metadata.author) if metadata and metadata.author else None,
            "publication_date": None,
            "language": "en",
        }

    def _meta(self, soup: BeautifulSoup, name: str) -> str | None:
        tag = soup.find("meta", attrs={"name": name}) or soup.find("meta", attrs={"property": name})
        if not tag:
            return None
        value = tag.get("content")
        return str(value).strip() if value else None
