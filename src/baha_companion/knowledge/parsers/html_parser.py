from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument


IGNORED_TAGS = {"script", "style", "nav", "header", "footer", "aside", "noscript"}
CONTENT_TAGS = {"h1", "h2", "h3", "h4", "p", "li", "table", "a", "title"}


class _KnowledgeHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.blocks: list[ParsedBlock] = []
        self._ignored_stack: list[str] = []
        self._active_tag: str | None = None
        self._active_attrs: dict[str, str] = {}
        self._buffer: list[str] = []
        self.title: str | None = None

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in IGNORED_TAGS:
            self._ignored_stack.append(tag)
            return
        if self._ignored_stack:
            return
        if tag in CONTENT_TAGS:
            self._flush()
            self._active_tag = tag
            self._active_attrs = dict(attrs)
            self._buffer = []

    def handle_endtag(self, tag: str) -> None:
        if self._ignored_stack and tag == self._ignored_stack[-1]:
            self._ignored_stack.pop()
            return
        if self._ignored_stack:
            return
        if tag == self._active_tag:
            self._flush()

    def handle_data(self, data: str) -> None:
        if self._ignored_stack or self._active_tag is None:
            return
        if data.strip():
            self._buffer.append(data.strip())

    def _flush(self) -> None:
        if self._active_tag is None:
            return
        text = " ".join(self._buffer).strip()
        if text:
            if self._active_tag == "title":
                self.title = text[:255]
            elif self._active_tag.startswith("h"):
                self.blocks.append(
                    ParsedBlock(kind=BlockKind.HEADING, text=text, level=int(self._active_tag[1]))
                )
            elif self._active_tag == "li":
                self.blocks.append(ParsedBlock(kind=BlockKind.LIST_ITEM, text=text))
            elif self._active_tag == "table":
                self.blocks.append(ParsedBlock(kind=BlockKind.TABLE, text=text))
            elif self._active_tag == "a":
                self.blocks.append(
                    ParsedBlock(
                        kind=BlockKind.LINK,
                        text=text,
                        metadata={"href": self._active_attrs.get("href")},
                    )
                )
            else:
                self.blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=text))
        self._active_tag = None
        self._active_attrs = {}
        self._buffer = []


def parse_html(path: Path) -> ParsedDocument:
    parser = _KnowledgeHTMLParser()
    parser.feed(path.read_text(encoding="utf-8", errors="ignore"))
    parser.close()
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.HTML,
        title=parser.title or path.stem,
        blocks=parser.blocks,
    )
