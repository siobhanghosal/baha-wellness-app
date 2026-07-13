from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from enum import StrEnum
from pathlib import Path
from typing import Any


class BlockKind(StrEnum):
    TITLE = "title"
    HEADING = "heading"
    PARAGRAPH = "paragraph"
    LIST_ITEM = "list_item"
    TABLE = "table"
    LINK = "link"


class DocumentType(StrEnum):
    PDF = "pdf"
    DOCX = "docx"
    HTML = "html"
    MARKDOWN = "markdown"
    TEXT = "text"
    JSON = "json"


class PriorityLevel(StrEnum):
    PRIORITY_1 = "priority_1"
    PRIORITY_2 = "priority_2"
    PRIORITY_3 = "priority_3"
    UNKNOWN = "unknown"


class AudienceType(StrEnum):
    STUDENT = "student"
    PARENT = "parent"
    TEACHER = "teacher"
    COUNSELLOR = "counsellor"
    HEALTHCARE_PROFESSIONAL = "healthcare_professional"
    ADMINISTRATOR = "administrator"
    GENERAL = "general"


class AgeGroup(StrEnum):
    AGES_9_12 = "9-12"
    AGES_13_16 = "13-16"
    AGES_17_19 = "17-19"
    PARENT = "parent"
    TEACHER = "teacher"
    GENERAL = "general"


class GenderGroup(StrEnum):
    MALE = "male"
    FEMALE = "female"
    GENERAL = "general"


class EvidenceLevel(StrEnum):
    CLINICAL_GUIDELINE = "clinical_guideline"
    SYSTEMATIC_REVIEW = "systematic_review"
    META_ANALYSIS = "meta_analysis"
    RANDOMIZED_TRIAL = "randomized_trial"
    OBSERVATIONAL_STUDY = "observational_study"
    EXPERT_CONSENSUS = "expert_consensus"
    GOVERNMENT_POLICY = "government_policy"
    EDUCATIONAL_CONTENT = "educational_content"
    UNKNOWN = "unknown"


class ClinicalReviewStatus(StrEnum):
    GOVERNMENT_ISSUED = "government_issued"
    PEER_REVIEWED = "peer_reviewed"
    EDITORIAL_REVIEWED = "editorial_reviewed"
    UNREVIEWED = "unreviewed"


@dataclass(slots=True)
class ParsedBlock:
    kind: BlockKind
    text: str
    level: int | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class ParsedDocument:
    source_path: Path
    document_type: DocumentType
    title: str | None
    blocks: list[ParsedBlock]
    metadata: dict[str, Any] = field(default_factory=dict)
    organization: str | None = None
    document_url: str | None = None
    publication_date: date | None = None
    language: str | None = None
    country: str | None = None


@dataclass(slots=True)
class SegmentedSection:
    title: str
    body: str
    section_type: str
    order: int
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class KnowledgeObjectDraft:
    title: str
    summary: str
    body: str
    source_document: str
    organization: str | None
    document_url: str | None
    publication_date: date | None
    country: str | None
    language: str | None
    metadata: dict[str, Any]
    topic: str
    subtopic: str | None
    topic_confidence: float
    audience: AudienceType
    age_group: AgeGroup
    gender: GenderGroup
    evidence_level: EvidenceLevel
    evidence_confidence: float
    clinical_review_status: ClinicalReviewStatus
    priority_level: PriorityLevel
    citations: list[dict[str, str]]
    activities: list[dict[str, str]]
    faqs: list[dict[str, str]]
    keywords: list[str]
    reading_level: str
    tags: list[str]
    quality_breakdown: dict[str, float | list[str]]
    duplicate_likelihood: float
    extraction_confidence: float
    parser_name: str
    document_type: DocumentType

