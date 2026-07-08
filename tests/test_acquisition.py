import pytest

from baha_rag.acquisition.downloaders import BaseDownloader
from baha_rag.acquisition.duplicates import DuplicateDetector
from baha_rag.acquisition.knowledge_extraction import KnowledgeExtractionService
from baha_rag.acquisition.life_skills_campaign import is_life_skills_relevant
from baha_rag.acquisition.source_registry import SourceRegistryService
from baha_rag.acquisition.storage import StorageService
from baha_rag.acquisition.topics import classify_topic
from baha_rag.acquisition.update_detection import IncrementalUpdateDetector


def test_source_registry_resolves_approved_domain() -> None:
    source = SourceRegistryService().organization_for_domain("www.who.int")
    assert source is not None
    assert source.organization == "WHO"


def test_topic_classifier_detects_alias() -> None:
    topic, subtopic = classify_topic("A school toolkit about online bullying and digital safety")
    assert topic == "cyberbullying"
    assert subtopic == "online bullying"


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("Responsible decision-making classroom lesson", "decision making"),
        ("A family guide to healthy screen time", "screen time"),
        ("Chronic absenteeism and student attendance toolkit", "school avoidance"),
        ("Building self-awareness in secondary students", "self awareness"),
        ("Communication skills and active listening", "communication skills"),
    ],
)
def test_life_skills_topics_are_classified_individually(
    text: str,
    expected: str,
) -> None:
    topic, _ = classify_topic(text)
    assert topic == expected


def test_duplicate_detector_normalizes_url_fragments() -> None:
    detector = DuplicateDetector()
    assert detector.normalized_url_key("https://www.who.int/page/#section") == "https://www.who.int/page"


def test_incremental_update_detector_uses_hash() -> None:
    detector = IncrementalUpdateDetector()
    assert detector.changed(previous_hash="abc", current_hash="abc") is False
    assert detector.changed(previous_hash="abc", current_hash="def") is True


def test_downloader_rejects_binary_media(tmp_path) -> None:
    downloader = BaseDownloader(StorageService(tmp_path))
    assert downloader._is_supported_response(
        "https://example.org/guide.jpg",
        "image/jpeg",
    ) is False
    assert downloader._is_supported_response(
        "https://example.org/guide.pdf",
        "application/pdf",
    ) is True


def test_extraction_removes_database_invalid_control_bytes() -> None:
    cleaned = KnowledgeExtractionService()._clean_text("safe\x00text\x08value")
    assert cleaned == "safe text value"


def test_life_skills_extraction_builds_support_fields() -> None:
    extractor = KnowledgeExtractionService()
    profile = extractor._skill_profile(
        "Responsible decision making",
        (
            "Teachers can use a classroom activity to help students compare choices. "
            "Parents can discuss consequences and practice decisions at home. "
            "A whole school support team can reinforce the strategy."
        ),
    )
    assert "decision making" in profile["skills"]
    assert profile["teacher_support"]
    assert profile["parent_support"]
    assert profile["school_support"]
    assert profile["interventions"]


def test_campaign_relevance_is_source_specific() -> None:
    assert is_life_skills_relevant(
        "Digital citizenship curriculum for educators",
        "Common Sense Media",
    )
    assert is_life_skills_relevant(
        "Chronic absenteeism toolkit",
        "Attendance Works",
    )


@pytest.mark.parametrize("status", [401, 403, 404])
def test_client_errors_are_not_transient(status: int) -> None:
    downloader = BaseDownloader(StorageService("."))
    assert downloader._is_retryable_status(status) is False


@pytest.mark.parametrize("status", [408, 425, 429, 500, 503])
def test_transient_statuses_are_retried(status: int) -> None:
    downloader = BaseDownloader(StorageService("."))
    assert downloader._is_retryable_status(status) is True
