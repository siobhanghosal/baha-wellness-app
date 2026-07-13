from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import ZipFile

from pypdf import PdfWriter

from baha_companion.knowledge.classifiers import (
    AudienceClassifier,
    AgeClassifier,
    DemographicClassifier,
    EvidenceClassifier,
    PriorityAssigner,
    ReadingLevelClassifier,
    TopicClassifier,
)
from baha_companion.knowledge.cli import run_process_document, run_statistics
from baha_companion.knowledge.duplicates import DuplicateDetectionService
from baha_companion.knowledge.normalization import KnowledgeNormalizationService
from baha_companion.knowledge.parsers import (
    parse_docx,
    parse_html,
    parse_json_document,
    parse_markdown,
    parse_pdf,
    parse_text_document,
)
from baha_companion.knowledge.quality import QualityService
from baha_companion.knowledge.repository import KnowledgeRepository
from baha_companion.knowledge.schemas import KnowledgeQueryFilters, ProcessDocumentRequest
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.service import KnowledgeProcessingService


FIXTURE_ROOT = Path("tests/fixtures/knowledge")


def build_service(db_session) -> KnowledgeProcessingService:
    return KnowledgeProcessingService(
        KnowledgeRepository(db_session),
        workspace_root=Path.cwd(),
        normalization_service=KnowledgeNormalizationService(),
        segmentation_service=DocumentSegmentationService(),
        topic_classifier=TopicClassifier(),
        audience_classifier=AudienceClassifier(),
        age_classifier=AgeClassifier(),
        evidence_classifier=EvidenceClassifier(),
        demographic_classifier=DemographicClassifier(),
        priority_assigner=PriorityAssigner(),
        reading_level_classifier=ReadingLevelClassifier(),
        quality_service=QualityService(),
        duplicate_detection_service=DuplicateDetectionService(),
    )


def test_parsers_and_normalization(tmp_path):
    html_document = parse_html(FIXTURE_ROOT / "sample.html")
    assert html_document.title == "Understanding Anxiety in Students"
    assert any(block.text.startswith("Symptoms") for block in html_document.blocks)

    markdown_document = parse_markdown(FIXTURE_ROOT / "sample.md")
    assert markdown_document.title == "Sleep Guidance for Teenagers"
    assert any(block.text == "Student Guidance" for block in markdown_document.blocks)

    text_document = parse_text_document(FIXTURE_ROOT / "sample.txt")
    assert text_document.title.startswith("Teacher guidance")

    json_document = parse_json_document(FIXTURE_ROOT / "sample.json")
    assert json_document.organization == "UNICEF"
    assert json_document.publication_date.isoformat() == "2025-02-01"

    docx_path = tmp_path / "sample.docx"
    with ZipFile(docx_path, "w") as archive:
        archive.writestr(
            "word/document.xml",
            (
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
                "<w:body><w:p><w:r><w:t>DOCX support guidance</w:t></w:r></w:p></w:body></w:document>"
            ),
        )
    docx_document = parse_docx(docx_path)
    assert docx_document.blocks[0].text == "DOCX support guidance"

    pdf_path = tmp_path / "sample.pdf"
    writer = PdfWriter()
    writer.add_blank_page(width=300, height=300)
    with pdf_path.open("wb") as handle:
        writer.write(handle)
    pdf_document = parse_pdf(pdf_path)
    assert pdf_document.title == "sample"

    normalization = KnowledgeNormalizationService()
    html_document.blocks.append(html_document.blocks[-1])
    normalized = normalization.normalize_document(html_document)
    texts = [block.text for block in normalized.blocks]
    assert "Accept all cookies" not in texts
    assert len(texts) == len(set(texts))

    sections = DocumentSegmentationService().segment(normalized)
    assert any(section.section_type == "symptoms" for section in sections)
    assert any(section.section_type == "parent_guidance" for section in sections)


def test_classifiers_duplicate_and_quality_services():
    topic_classifier = TopicClassifier()
    topic, subtopic, confidence = topic_classifier.classify("Students with anxiety and panic may struggle with sleep.")
    assert topic == "anxiety"
    assert subtopic == "anxiety"
    assert confidence > 0.3

    audience = AudienceClassifier().classify("For teachers supporting adolescents with bullying.")
    assert audience == "teacher"
    age_group = AgeClassifier().classify("Teen sleep guidance", audience=audience)
    assert age_group == "teacher"
    evidence_level, evidence_confidence, review_status = EvidenceClassifier().classify(
        "This randomized trial evaluated school-based intervention.",
        organization="WHO",
        metadata={},
    )
    assert evidence_level == "randomized_trial"
    assert evidence_confidence >= 0.9
    assert review_status == "peer_reviewed"
    assert PriorityAssigner().assign("UNICEF") == "priority_2"
    assert DemographicClassifier().classify_gender("Guidance for girls with exam stress.") == "female"
    assert ReadingLevelClassifier().classify("Short sentences help. Calm breathing helps.") == "easy"

    duplicate_service = DuplicateDetectionService()
    match = duplicate_service.detect_duplicate(
        draft=type(
            "Draft",
            (),
            {
                "title": "Anxiety basics",
                "body": "Students with anxiety may have panic and sleep problems.",
                "organization": "WHO",
                "publication_date": None,
            },
        )(),
        existing_objects=[
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "title": "Anxiety basics",
                "body": "Students with anxiety may have panic and sleep problems.",
                "organization": "WHO",
                "publication_date": None,
            }
        ],
    )
    assert match is not None
    assert match.score >= 0.82

    quality = QualityService().score(
        type(
            "Draft",
            (),
            {
                "body": "Clear guidance. Students can practice breathing every day.",
                "summary": "Clear guidance.",
                "topic": "anxiety",
                "audience": "student",
                "age_group": "13-16",
                "organization": "WHO",
                "document_url": "https://example.org",
                "publication_date": None,
                "country": "Global",
                "language": "English",
                "keywords": ["anxiety"],
                "tags": ["overview"],
                "citations": [{"text": "WHO"}],
                "duplicate_likelihood": 0.1,
                "extraction_confidence": 0.88,
            },
        )()
    )
    assert quality["quality_score"] > 50


async def test_knowledge_processing_service_and_repository(db_session):
    service = build_service(db_session)

    first_result = await service.process_document(ProcessDocumentRequest(path=str(FIXTURE_ROOT / "sample.html")))
    assert first_result.knowledge_objects_created >= 4
    assert first_result.duplicates_removed == 0

    duplicate_result = await service.process_document(ProcessDocumentRequest(path=str(FIXTURE_ROOT / "sample.html")))
    assert duplicate_result.duplicates_removed >= 1

    json_result = await service.process_document(ProcessDocumentRequest(path=str(FIXTURE_ROOT / "sample.json")))
    assert json_result.knowledge_objects_created >= 1

    listing = await service.list_knowledge(
        pagination=type("Pagination", (), {"page": 1, "page_size": 20, "offset": 0})(),
        filters=KnowledgeQueryFilters(topic="anxiety"),
    )
    assert listing.meta.total_items >= 1

    knowledge_object = await service.get_knowledge(listing.items[0].id)
    assert knowledge_object.details.audience in {"student", "parent", "general"}

    topics = await service.topic_summary()
    assert any(item["topic"] == "anxiety" for item in topics)

    statistics = await service.statistics()
    assert statistics["total_knowledge_objects"] >= 1
    assert "priority_distribution" in statistics

    quality_report = await service.quality_report()
    assert quality_report["average_quality_score"] >= 0


async def test_knowledge_api_endpoints(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    process_response = await client.post(
        "/api/v1/process/document",
        headers=headers,
        json={"path": "tests/fixtures/knowledge/sample.html"},
    )
    assert process_response.status_code == 202
    assert process_response.json()["knowledge_objects_created"] >= 1

    batch_response = await client.post(
        "/api/v1/process/batch",
        headers=headers,
        json={"root_path": "tests/fixtures/knowledge", "limit": 3},
    )
    assert batch_response.status_code == 202
    assert batch_response.json()["documents_processed"] >= 1

    list_response = await client.get("/api/v1/knowledge?page=1&page_size=10", headers=headers)
    assert list_response.status_code == 200
    assert list_response.json()["meta"]["total_items"] >= 1
    knowledge_id = list_response.json()["items"][0]["id"]

    detail_response = await client.get(f"/api/v1/knowledge/{knowledge_id}", headers=headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["title"]

    topics_response = await client.get("/api/v1/knowledge/topics", headers=headers)
    assert topics_response.status_code == 200
    assert topics_response.json()["items"]

    statistics_response = await client.get("/api/v1/knowledge/statistics", headers=headers)
    assert statistics_response.status_code == 200
    assert statistics_response.json()["total_knowledge_objects"] >= 1

    quality_response = await client.get("/api/v1/knowledge/quality", headers=headers)
    assert quality_response.status_code == 200
    assert quality_response.json()["average_quality_score"] >= 0


async def test_knowledge_cli_commands(session_factory, monkeypatch, capsys):
    import baha_companion.knowledge.cli as knowledge_cli

    monkeypatch.setattr(knowledge_cli, "get_session_factory", lambda: session_factory)

    await run_process_document(
        argparse.Namespace(
            path="tests/fixtures/knowledge/sample.md",
            organization=None,
            document_url=None,
            publication_date=None,
            country=None,
            language=None,
            overwrite=False,
        )
    )
    process_output = capsys.readouterr().out
    assert "knowledge_objects_created" in process_output

    await run_statistics()
    statistics_output = capsys.readouterr().out
    assert "total_knowledge_objects" in statistics_output
