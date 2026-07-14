from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
from re import sub

from bs4 import BeautifulSoup


@dataclass(frozen=True)
class ProcessedDocument:
    title: str
    text: str
    tables: list[str]
    references: list[str]


def normalize_whitespace(text: str) -> str:
    return sub(r"\s+", " ", text).strip()


def extract_references(text: str) -> list[str]:
    markers = ("references", "bibliography", "resources")
    lowered = text.lower()
    for marker in markers:
        index = lowered.rfind(marker)
        if index > 0:
            tail = text[index:]
            return [line.strip() for line in tail.splitlines() if len(line.strip()) > 20][:100]
    return []


def process_html(content: bytes) -> ProcessedDocument:
    html = content.decode("utf-8", errors="ignore")
    try:
        import trafilatura

        extracted = trafilatura.extract(html, include_tables=True, include_comments=False) or ""
    except Exception:
        extracted = ""
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["nav", "footer", "header", "script", "style", "aside"]):
        tag.decompose()
    title = normalize_whitespace(soup.title.text) if soup.title else "Untitled"
    text = normalize_whitespace(extracted or soup.get_text(" "))
    tables = [normalize_whitespace(table.get_text(" | ")) for table in soup.find_all("table")]
    return ProcessedDocument(title=title, text=text, tables=tables, references=extract_references(text))


def process_pdf(content: bytes) -> ProcessedDocument:
    from pypdf import PdfReader

    reader = PdfReader(BytesIO(content))
    title = "Untitled PDF"
    if reader.metadata and reader.metadata.title:
        title = str(reader.metadata.title)
    pages = [page.extract_text() or "" for page in reader.pages]
    text = normalize_whitespace("\n".join(pages))
    return ProcessedDocument(title=title, text=text, tables=[], references=extract_references(text))


def process_document(content: bytes, content_type: str, url: str) -> ProcessedDocument:
    lowered = content_type.lower()
    if "pdf" in lowered or url.lower().endswith(".pdf"):
        return process_pdf(content)
    if "html" in lowered or "text" in lowered:
        return process_html(content)
    raise ValueError(f"Unsupported content type: {content_type}")
