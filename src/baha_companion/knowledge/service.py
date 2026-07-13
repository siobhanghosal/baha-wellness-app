from __future__ import annotations

import logging
from datetime import UTC, datetime
from pathlib import Path
from uuid import UUID

from baha_companion.common.exceptions import NotFoundError, ValidationError
from baha_companion.common.pagination import PaginationParams
from baha_companion.knowledge.classifiers import (
    AudienceClassifier,
    AgeClassifier,
    DemographicClassifier,
    EvidenceClassifier,
    PriorityAssigner,
    ReadingLevelClassifier,
    TopicClassifier,
)
from baha_companion.knowledge.duplicates import DuplicateDetectionService
from baha_companion.knowledge.models import KnowledgeObject
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
from baha_companion.knowledge.schemas import (
    KnowledgeQueryFilters,
    ProcessBatchRequest,
    ProcessBatchResponse,
    ProcessDocumentRequest,
    ProcessDocumentResponse,
    ProcessedObjectResult,
)
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.types import DocumentType, KnowledgeObjectDraft, ParsedDocument
from baha_companion.knowledge.utils import infer_organization_from_path, relative_source_path

logger = logging.getLogger("baha_companion.knowledge.processing")


SUPPORTED_SUFFIXES = {
    ".pdf": DocumentType.PDF,
    ".docx": DocumentType.DOCX,
    ".html": DocumentType.HTML,
    ".htm": DocumentType.HTML,
    ".aspx": DocumentType.HTML,
    ".md": DocumentType.MARKDOWN,
    ".markdown": DocumentType.MARKDOWN,
    ".txt": DocumentType.TEXT,
    ".json": DocumentType.JSON,
}


class KnowledgeProcessingService:
    def __init__(
        self,
        repository: KnowledgeRepository,
        *,
        workspace_root: Path,
        normalization_service: KnowledgeNormalizationService,
        segmentation_service: DocumentSegmentationService,
        topic_classifier: TopicClassifier,
        audience_classifier: AudienceClassifier,
        age_classifier: AgeClassifier,
        evidence_classifier: EvidenceClassifier,
        demographic_classifier: DemographicClassifier,
        priority_assigner: PriorityAssigner,
        reading_level_classifier: ReadingLevelClassifier,
        quality_service: QualityService,
        duplicate_detection_service: DuplicateDetectionService,
    ) -> None:
        self.repository = repository
        self.workspace_root = workspace_root
        self.normalization_service = normalization_service
        self.segmentation_service = segmentation_service
        self.topic_classifier = topic_classifier
        self.audience_classifier = audience_classifier
        self.age_classifier = age_classifier
        self.evidence_classifier = evidence_classifier
        self.demographic_classifier = demographic_classifier
        self.priority_assigner = priority_assigner
        self.reading_level_classifier = reading_level_classifier
        self.quality_service = quality_service
        self.duplicate_detection_service = duplicate_detection_service

    async def process_document(self, request: ProcessDocumentRequest) -> ProcessDocumentResponse:
        path = self._resolve_document_path(request.path)
        if request.overwrite:
            for existing in await self.repository.find_by_source_document(relative_source_path(path, workspace_root=self.workspace_root)):
                existing.deleted_at = datetime.now(UTC)

        parsed = self._parse_document(path)
        parsed.organization = request.organization or parsed.organization or infer_organization_from_path(path)
        parsed.document_url = request.document_url or parsed.document_url
        parsed.publication_date = request.publication_date or parsed.publication_date
        parsed.country = request.country or parsed.country or self._infer_country(parsed.organization)
        parsed.language = request.language or parsed.language or "English"
        parsed = self.normalization_service.normalize_document(parsed)
        sections = self.segmentation_service.segment(parsed)
        if not sections:
            raise ValidationError("No usable content sections were detected for this document.")

        citations = self.segmentation_service.extract_citations(sections)
        processed_objects: list[ProcessedObjectResult] = []
        duplicates_removed = 0
        created = 0
        for section in sections:
            combined_text = f"{parsed.title or path.stem}\n{section.title}\n{section.body}"
            topic, subtopic, topic_confidence = self.topic_classifier.classify(
                combined_text,
                metadata_topic=self._metadata_value(parsed.metadata, "topic"),
                metadata_subtopic=self._metadata_value(parsed.metadata, "subtopic"),
            )
            audience = self.audience_classifier.classify(combined_text)
            age_group = self.age_classifier.classify(combined_text, audience=audience)
            evidence_level, evidence_confidence, clinical_review_status = self.evidence_classifier.classify(
                combined_text,
                organization=parsed.organization,
                metadata=parsed.metadata,
            )
            draft = KnowledgeObjectDraft(
                title=self._build_title(parsed, section.title),
                summary=self._summary(section.body),
                body=section.body,
                source_document=relative_source_path(path, workspace_root=self.workspace_root),
                organization=parsed.organization,
                document_url=parsed.document_url,
                publication_date=parsed.publication_date,
                country=parsed.country,
                language=parsed.language,
                metadata={
                    "section_type": section.section_type,
                    "section_order": section.order,
                    "document_title": parsed.title,
                    "raw_metadata": parsed.metadata,
                },
                topic=topic,
                subtopic=subtopic,
                topic_confidence=topic_confidence,
                audience=audience,
                age_group=age_group,
                gender=self.demographic_classifier.classify_gender(combined_text),
                evidence_level=evidence_level,
                evidence_confidence=evidence_confidence,
                clinical_review_status=clinical_review_status,
                priority_level=self.priority_assigner.assign(parsed.organization, document_url=parsed.document_url),
                citations=citations,
                activities=self.segmentation_service.extract_activities(section),
                faqs=self.segmentation_service.extract_faqs(section),
                keywords=self.topic_classifier.extract_keywords(combined_text, topic=topic, subtopic=subtopic),
                reading_level=self.reading_level_classifier.classify(section.body),
                tags=self._build_tags(section.section_type, topic, audience.value),
                quality_breakdown={},
                duplicate_likelihood=0.0,
                extraction_confidence=self._extraction_confidence(parsed, section.body),
                parser_name=f"{parsed.document_type.value}_parser",
                document_type=parsed.document_type,
            )
            duplicate = self.duplicate_detection_service.detect_duplicate(
                draft,
                existing_objects=await self.repository.list_existing_for_duplicate_detection(
                    organization=draft.organization,
                    topic=draft.topic,
                ),
            )
            draft.duplicate_likelihood = duplicate.score if duplicate else 0.0
            draft.quality_breakdown = self.quality_service.score(draft)

            if duplicate is not None:
                duplicates_removed += 1
                processed_objects.append(
                    ProcessedObjectResult(
                        title=draft.title,
                        topic=draft.topic,
                        source_document=draft.source_document,
                        duplicate_of=UUID(duplicate.knowledge_object_id),
                        quality_score=float(draft.quality_breakdown["quality_score"]),
                    )
                )
                continue

            knowledge_object = await self.repository.create_knowledge_object(draft)
            created += 1
            processed_objects.append(
                ProcessedObjectResult(
                    id=knowledge_object.id,
                    title=draft.title,
                    topic=draft.topic,
                    source_document=draft.source_document,
                    quality_score=float(draft.quality_breakdown["quality_score"]),
                )
            )
        logger.info(
            "knowledge_document_processed",
            extra={
                "details": {
                    "document_path": str(path),
                    "knowledge_objects_created": created,
                    "duplicates_removed": duplicates_removed,
                }
            },
        )
        return ProcessDocumentResponse(
            document_path=str(path),
            processed=created > 0,
            duplicates_removed=duplicates_removed,
            knowledge_objects_created=created,
            objects=processed_objects,
        )

    async def process_batch(self, request: ProcessBatchRequest) -> ProcessBatchResponse:
        root = self._resolve_root_path(request.root_path)
        topic_set: set[str] = set()
        audience_distribution: dict[str, int] = {}
        age_distribution: dict[str, int] = {}
        priority_distribution: dict[str, int] = {}
        quality_distribution = {"high": 0, "medium": 0, "low": 0}

        documents_processed = 0
        knowledge_objects_created = 0
        duplicates_removed = 0
        for path in self._iter_supported_documents(root):
            if request.organization and infer_organization_from_path(path).lower() != request.organization.lower():
                continue
            result = await self.process_document(
                ProcessDocumentRequest(path=str(path), organization=request.organization, overwrite=request.overwrite)
            )
            documents_processed += 1
            knowledge_objects_created += result.knowledge_objects_created
            duplicates_removed += result.duplicates_removed
            for item in result.objects:
                topic_set.add(item.topic)
            if request.limit and documents_processed >= request.limit:
                break

        statistics = await self.repository.statistics()
        audience_distribution.update(statistics["audience_distribution"])
        age_distribution.update(statistics["age_distribution"])
        priority_distribution.update(statistics["priority_distribution"])
        quality_distribution.update(statistics["quality_distribution"])
        return ProcessBatchResponse(
            documents_processed=documents_processed,
            knowledge_objects_created=knowledge_objects_created,
            duplicates_removed=duplicates_removed,
            topics_discovered=sorted(topic_set),
            audience_distribution=audience_distribution,
            age_distribution=age_distribution,
            priority_distribution=priority_distribution,
            quality_distribution=quality_distribution,
        )

    async def list_knowledge(self, *, pagination: PaginationParams, filters: KnowledgeQueryFilters):
        return await self.repository.list_knowledge_objects(pagination=pagination, filters=filters.model_dump())

    async def get_knowledge(self, knowledge_object_id: UUID | str) -> KnowledgeObject:
        knowledge_object = await self.repository.get_knowledge_object(knowledge_object_id)
        if knowledge_object is None:
            raise NotFoundError("Knowledge object not found.")
        return knowledge_object

    async def topic_summary(self):
        return await self.repository.topic_counts()

    async def statistics(self):
        return await self.repository.statistics()

    async def quality_report(self):
        return await self.repository.quality_report()

    def _parse_document(self, path: Path) -> ParsedDocument:
        document_type = self._document_type(path)
        if document_type == DocumentType.PDF:
            return parse_pdf(path)
        if document_type == DocumentType.DOCX:
            return parse_docx(path)
        if document_type == DocumentType.HTML:
            return parse_html(path)
        if document_type == DocumentType.MARKDOWN:
            return parse_markdown(path)
        if document_type == DocumentType.TEXT:
            return parse_text_document(path)
        if document_type == DocumentType.JSON:
            return parse_json_document(path)
        raise ValidationError(f"Unsupported document type for path: {path}")

    def _document_type(self, path: Path) -> DocumentType:
        suffix = path.suffix.lower()
        if suffix in SUPPORTED_SUFFIXES:
            return SUPPORTED_SUFFIXES[suffix]
        raise ValidationError(f"Unsupported document suffix: {suffix}")

    def _resolve_document_path(self, path_value: str) -> Path:
        path = Path(path_value)
        resolved = (self.workspace_root / path).resolve() if not path.is_absolute() else path.resolve()
        if not resolved.exists() or not resolved.is_file():
            raise ValidationError("Document path does not exist or is not a file.")
        if self.workspace_root.resolve() not in resolved.parents and resolved != self.workspace_root.resolve():
            raise ValidationError("Document path must remain inside the workspace.")
        return resolved

    def _resolve_root_path(self, path_value: str) -> Path:
        path = Path(path_value)
        resolved = (self.workspace_root / path).resolve() if not path.is_absolute() else path.resolve()
        if not resolved.exists() or not resolved.is_dir():
            raise ValidationError("Root path does not exist or is not a directory.")
        if self.workspace_root.resolve() not in resolved.parents and resolved != self.workspace_root.resolve():
            raise ValidationError("Root path must remain inside the workspace.")
        return resolved

    def _iter_supported_documents(self, root: Path):
        for path in sorted(root.rglob("*")):
            if path.is_file() and path.name != ".DS_Store":
                try:
                    self._document_type(path)
                except ValidationError:
                    continue
                yield path

    def _build_title(self, parsed: ParsedDocument, section_title: str) -> str:
        if parsed.title and section_title.lower() not in parsed.title.lower():
            return f"{parsed.title}: {section_title}"[:255]
        return section_title[:255] or (parsed.title or parsed.source_path.stem)[:255]

    def _summary(self, body: str) -> str:
        sentences = [item.strip() for item in body.split(".") if item.strip()]
        summary = ". ".join(sentences[:2]).strip()
        if summary and not summary.endswith("."):
            summary += "."
        return summary[:600] or body[:600]

    def _build_tags(self, section_type: str, topic: str, audience: str) -> list[str]:
        return list(dict.fromkeys([section_type, topic, audience]))

    def _metadata_value(self, metadata: dict, field_name: str) -> str | None:
        value = metadata.get(field_name)
        return str(value).strip() if value else None

    def _infer_country(self, organization: str | None) -> str:
        if not organization:
            return "Global"
        lowered = organization.lower()
        if any(key in lowered for key in ("ncert", "nimhans", "cbse", "aiims", "mohfw", "ncpcr", "icmr", "iap")):
            return "India"
        if any(key in lowered for key in ("cdc", "nih", "aap", "samhsa")):
            return "United States"
        if any(key in lowered for key in ("nhs", "nice")):
            return "United Kingdom"
        return "Global"

    def _extraction_confidence(self, parsed: ParsedDocument, section_body: str) -> float:
        base = {
            DocumentType.JSON: 0.95,
            DocumentType.HTML: 0.88,
            DocumentType.MARKDOWN: 0.9,
            DocumentType.TEXT: 0.82,
            DocumentType.DOCX: 0.84,
            DocumentType.PDF: 0.78,
        }[parsed.document_type]
        if len(section_body) > 250:
            base += 0.04
        return min(0.99, round(base, 2))
