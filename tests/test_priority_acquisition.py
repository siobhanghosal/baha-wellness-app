from pathlib import Path
from zipfile import ZipFile

import pytest

from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.acquisition.manual_ingestion import ManualResourceIngestionService
from baha_rag.acquisition.priority_sources import AHA, BAHA, IAP, PrioritySourceRegistry
from baha_rag.acquisition.topics import REQUIRED_CONDITION_PROFILES


def test_priority_source_order_starts_with_baha_and_iap() -> None:
    sources = PrioritySourceRegistry().all()
    assert [source.organization for source in sources[:3]] == [BAHA, AHA, IAP]
    assert sources[0].source_weight == 1.0
    assert sources[1].source_weight == 0.95


def test_docx_open_xml_text_is_extractable(tmp_path: Path) -> None:
    path = tmp_path / "parent-guide.docx"
    with ZipFile(path, "w") as package:
        package.writestr(
            "word/document.xml",
            (
                '<w:document xmlns:w="urn:test"><w:body><w:p><w:r>'
                "<w:t>Parent guide for adolescent anxiety and school support.</w:t>"
                "</w:r></w:p></w:body></w:document>"
            ),
        )
    text = KnowledgeExtractionService()._read_text(str(path), "docx")
    assert "adolescent anxiety" in text


def test_extraction_can_link_one_resource_to_multiple_conditions(tmp_path: Path) -> None:
    path = tmp_path / "school-guide.html"
    path.write_text(
        "<h1>Teacher guide</h1><p>Support for adolescent anxiety, depression, "
        "and exam stress in the classroom.</p>"
    )
    extracted = KnowledgeExtractionService().extract(
        str(path),
        {"title": "School mental health guide", "resource_type": "html"},
    )
    assert {"Anxiety", "Depression", "Exam Stress"} <= set(extracted["clinical_profiles"])
    assert extracted["audience"] == "teacher"


def test_required_profile_set_matches_campaign_target() -> None:
    assert len(REQUIRED_CONDITION_PROFILES) == 25
    assert "Exam Stress" in REQUIRED_CONDITION_PROFILES
    assert "School Refusal" in REQUIRED_CONDITION_PROFILES
    assert "Emotional Regulation" in REQUIRED_CONDITION_PROFILES


def test_zip_import_rejects_path_traversal(tmp_path: Path) -> None:
    archive = tmp_path / "unsafe.zip"
    with ZipFile(archive, "w") as package:
        package.writestr("../escape.txt", "not allowed")
    service = ManualResourceIngestionService.__new__(ManualResourceIngestionService)
    with pytest.raises(ValueError, match="Unsafe ZIP member path"):
        service._safe_extract_archive(archive, tmp_path / "output")


def test_explicit_unsupported_manual_file_is_rejected(tmp_path: Path) -> None:
    video = tmp_path / "raw-video.mp4"
    video.write_bytes(b"not a transcript")
    service = ManualResourceIngestionService.__new__(ManualResourceIngestionService)
    with pytest.raises(ValueError, match="Unsupported manual resource type"):
        list(service._collect_files([video]))
