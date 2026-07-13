from __future__ import annotations

import re
import unicodedata

from baha_companion.knowledge.types import BlockKind, ParsedBlock, ParsedDocument


COOKIE_PATTERN = re.compile(r"\b(cookie|privacy policy|accept all|subscribe|advertisement|sign up)\b", re.IGNORECASE)
WHITESPACE_PATTERN = re.compile(r"\s+")
BROKEN_LINE_PATTERN = re.compile(r"(?<![.!?:])\n(?=[a-z(])")
OCR_FIX_PATTERN = re.compile(r"(?<=\w)-\s+(?=\w)")
LIST_BULLET_PATTERN = re.compile(r"^[\u2022\-*]+\s*")


class KnowledgeNormalizationService:
    def normalize_document(self, document: ParsedDocument) -> ParsedDocument:
        cleaned_blocks: list[ParsedBlock] = []
        seen_paragraphs: set[str] = set()
        for block in document.blocks:
            text = self.normalize_text(block.text)
            if not text or COOKIE_PATTERN.search(text):
                continue
            if block.kind == BlockKind.PARAGRAPH and text in seen_paragraphs:
                continue
            if block.kind == BlockKind.PARAGRAPH:
                seen_paragraphs.add(text)
            cleaned_blocks.append(
                ParsedBlock(
                    kind=block.kind,
                    text=text,
                    level=block.level,
                    metadata=dict(block.metadata),
                )
            )

        document.blocks = cleaned_blocks
        if document.title:
            document.title = self.normalize_text(document.title)
        return document

    def normalize_text(self, value: str) -> str:
        normalized = unicodedata.normalize("NFKC", value)
        normalized = normalized.replace("\u2018", "'").replace("\u2019", "'")
        normalized = normalized.replace("\u201c", '"').replace("\u201d", '"')
        normalized = normalized.replace("\u2013", "-").replace("\u2014", "-")
        normalized = OCR_FIX_PATTERN.sub("", normalized)
        normalized = BROKEN_LINE_PATTERN.sub(" ", normalized)
        normalized = LIST_BULLET_PATTERN.sub("- ", normalized.strip())
        normalized = WHITESPACE_PATTERN.sub(" ", normalized)
        return normalized.strip()

