from __future__ import annotations

from pathlib import Path
from xml.etree import ElementTree
from zipfile import ZipFile

from baha_companion.knowledge.types import BlockKind, DocumentType, ParsedBlock, ParsedDocument


WORD_NAMESPACE = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def parse_docx(path: Path) -> ParsedDocument:
    blocks: list[ParsedBlock] = []
    with ZipFile(path) as archive:
        document_xml = archive.read("word/document.xml")

    root = ElementTree.fromstring(document_xml)
    for paragraph in root.findall(".//w:p", WORD_NAMESPACE):
        text_runs = [node.text or "" for node in paragraph.findall(".//w:t", WORD_NAMESPACE)]
        text = "".join(text_runs).strip()
        if not text:
            continue
        blocks.append(ParsedBlock(kind=BlockKind.PARAGRAPH, text=text))

    title = blocks[0].text[:255] if blocks else path.stem
    return ParsedDocument(
        source_path=path,
        document_type=DocumentType.DOCX,
        title=title,
        blocks=blocks,
    )

