from __future__ import annotations

from pathlib import Path

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument


def parse_text_document(path: Path) -> ParsedDocument:
    blocks: list[ParsedBlock] = []
    for paragraph in path.read_text(encoding="utf-8", errors="ignore").split("\n\n"):
        cleaned = paragraph.strip()
        if cleaned:
            blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=cleaned))

    title = blocks[0].text.splitlines()[0][:255] if blocks else path.stem
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.TEXT,
        title=title,
        blocks=blocks,
    )

