from __future__ import annotations

import json
from pathlib import Path

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument
from baha_companion.knowledge.utils import coerce_json_text, first_non_empty, parse_publication_date


TEXT_FIELDS = (
    "abstract",
    "summary",
    "body",
    "content",
    "description",
    "results",
    "conclusion",
    "methods",
)


def parse_json_document(path: Path) -> ParsedDocument:
    payload = json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    title = first_non_empty(
        payload.get("title") if isinstance(payload, dict) else None,
        path.stem,
    )
    blocks: list[ParsedBlock] = []

    if isinstance(payload, dict):
        for field in TEXT_FIELDS:
            value = payload.get(field)
            if value:
                kind = BlockKind.HEADING if field in {"methods", "results", "conclusion"} else BlockKind.PARAGRAPH
                blocks.append(ParsedBlock(kind=kind, text=coerce_json_text(value)))
        if not blocks:
            blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=coerce_json_text(payload)))
    else:
        blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=coerce_json_text(payload)))

    metadata = payload if isinstance(payload, dict) else {"payload": payload}
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.JSON,
        title=str(title)[:255],
        blocks=blocks,
        metadata=metadata,
        organization=metadata.get("organization") if isinstance(metadata, dict) else None,
        document_url=metadata.get("url") if isinstance(metadata, dict) else None,
        publication_date=parse_publication_date(metadata.get("publication_date")) if isinstance(metadata, dict) else None,
        language=metadata.get("language") if isinstance(metadata, dict) else None,
        country=metadata.get("country") if isinstance(metadata, dict) else None,
    )

