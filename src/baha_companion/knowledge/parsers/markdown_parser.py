from __future__ import annotations

from pathlib import Path

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument


def parse_markdown(path: Path) -> ParsedDocument:
    blocks: list[ParsedBlock] = []
    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            level = len(line) - len(line.lstrip("#"))
            blocks.append(ParsedBlock(kind=BlockKind.HEADING, text=line[level:].strip(), level=level))
        elif line.startswith(("-", "*", "+")):
            blocks.append(ParsedBlock(kind=BlockKind.LIST_ITEM, text=line[1:].strip()))
        else:
            blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=line))

    title = next((block.text for block in blocks if block.kind == BlockKind.HEADING), path.stem)
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.MARKDOWN,
        title=title,
        blocks=blocks,
    )

