from __future__ import annotations

from pathlib import Path

from pypdf import PdfReader

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument


def parse_pdf(path: Path) -> ParsedDocument:
    reader = PdfReader(str(path))
    blocks: list[ParsedBlock] = []
    for page_number, page in enumerate(reader.pages, start=1):
        text = (page.extract_text() or "").strip()
        if not text:
            continue
        for paragraph in [item.strip() for item in text.split("\n\n") if item.strip()]:
            blocks.append(
                ParsedBlock(
                    kind=BlockKind.PARAGRAPH,
                    text=paragraph,
                    metadata={"page": page_number},
                )
            )

    title = blocks[0].text.splitlines()[0][:255] if blocks else path.stem
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.PDF,
        title=title,
        blocks=blocks,
        metadata={"page_count": len(reader.pages)},
    )

