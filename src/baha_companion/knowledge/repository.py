from __future__ import annotations

from collections import Counter
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from baha_companion.common.pagination import PaginationParams, build_pagination_meta
from baha_companion.common.schemas import PaginatedResponse
from baha_companion.knowledge.models import (
    KnowledgeActivity,
    KnowledgeCitation,
    KnowledgeFaq,
    KnowledgeKeyword,
    KnowledgeMetadata,
    KnowledgeObject,
    KnowledgeQuality,
    KnowledgeTopic,
)
from baha_companion.knowledge.types import KnowledgeObjectDraft


class KnowledgeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_knowledge_object(self, draft: KnowledgeObjectDraft) -> KnowledgeObject:
        knowledge_object = KnowledgeObject(
            title=draft.title,
            summary=draft.summary,
            body=draft.body,
            source_document=draft.source_document,
            metadata_=draft.metadata,
        )
        knowledge_object.details = KnowledgeMetadata(
            organization=draft.organization,
            document_url=draft.document_url,
            publication_date=draft.publication_date,
            country=draft.country,
            language=draft.language or "English",
            audience=draft.audience.value,
            age_group=draft.age_group.value,
            gender=draft.gender.value,
            evidence_level=draft.evidence_level.value,
            evidence_confidence=draft.evidence_confidence,
            clinical_review_status=draft.clinical_review_status.value,
            priority_level=draft.priority_level.value,
            reading_level=draft.reading_level,
            source_type=draft.document_type.value,
            parser_name=draft.parser_name,
            extraction_confidence=draft.extraction_confidence,
            duplicate_likelihood=draft.duplicate_likelihood,
            tags=draft.tags,
        )
        knowledge_object.topics.append(
            KnowledgeTopic(
                topic=draft.topic,
                subtopic=draft.subtopic,
                confidence=draft.topic_confidence,
                is_primary=True,
            )
        )
        knowledge_object.keywords = [
            KnowledgeKeyword(keyword=keyword, sort_order=index)
            for index, keyword in enumerate(draft.keywords)
        ]
        knowledge_object.citations = [
            KnowledgeCitation(
                citation_text=item.get("text", ""),
                citation_url=item.get("url"),
                source_title=item.get("source_title"),
                sort_order=index,
            )
            for index, item in enumerate(draft.citations)
        ]
        knowledge_object.faqs = [
            KnowledgeFaq(question=item["question"], answer=item["answer"], sort_order=index)
            for index, item in enumerate(draft.faqs)
        ]
        knowledge_object.activities = [
            KnowledgeActivity(
                title=item["title"],
                body=item["body"],
                activity_type=item.get("activity_type", "exercise"),
                sort_order=index,
            )
            for index, item in enumerate(draft.activities)
        ]
        knowledge_object.quality = KnowledgeQuality(
            quality_score=float(draft.quality_breakdown["quality_score"]),
            completeness_score=float(draft.quality_breakdown["completeness_score"]),
            readability_score=float(draft.quality_breakdown["readability_score"]),
            metadata_completeness_score=float(draft.quality_breakdown["metadata_completeness_score"]),
            duplicate_likelihood_score=float(draft.quality_breakdown["duplicate_likelihood_score"]),
            extraction_confidence_score=float(draft.quality_breakdown["extraction_confidence_score"]),
            reference_quality_score=float(draft.quality_breakdown["reference_quality_score"]),
            language_quality_score=float(draft.quality_breakdown["language_quality_score"]),
            warnings=list(draft.quality_breakdown["warnings"]),
        )
        self.session.add(knowledge_object)
        await self.session.flush()
        await self.session.refresh(knowledge_object)
        return await self.get_knowledge_object(knowledge_object.id)

    async def get_knowledge_object(self, knowledge_object_id: UUID | str) -> KnowledgeObject | None:
        stmt = (
            select(KnowledgeObject)
            .where(KnowledgeObject.id == knowledge_object_id)
            .options(
                selectinload(KnowledgeObject.topics),
                selectinload(KnowledgeObject.keywords),
                selectinload(KnowledgeObject.citations),
                selectinload(KnowledgeObject.faqs),
                selectinload(KnowledgeObject.activities),
            )
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_knowledge_objects(
        self,
        *,
        pagination: PaginationParams,
        filters: dict,
    ) -> PaginatedResponse[KnowledgeObject]:
        stmt: Select[tuple[KnowledgeObject]] = (
            select(KnowledgeObject)
            .join(KnowledgeMetadata, KnowledgeMetadata.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeQuality, KnowledgeQuality.knowledge_object_id == KnowledgeObject.id)
            .options(
                selectinload(KnowledgeObject.topics),
                selectinload(KnowledgeObject.keywords),
                selectinload(KnowledgeObject.citations),
                selectinload(KnowledgeObject.faqs),
                selectinload(KnowledgeObject.activities),
            )
        )
        count_stmt = (
            select(func.count(KnowledgeObject.id))
            .join(KnowledgeMetadata, KnowledgeMetadata.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeQuality, KnowledgeQuality.knowledge_object_id == KnowledgeObject.id)
        )
        if topic := filters.get("topic"):
            stmt = stmt.join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id).where(
                func.lower(KnowledgeTopic.topic) == topic
            )
            count_stmt = count_stmt.join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id).where(
                func.lower(KnowledgeTopic.topic) == topic
            )
        if audience := filters.get("audience"):
            stmt = stmt.where(func.lower(KnowledgeMetadata.audience) == audience)
            count_stmt = count_stmt.where(func.lower(KnowledgeMetadata.audience) == audience)
        if age_group := filters.get("age_group"):
            stmt = stmt.where(func.lower(KnowledgeMetadata.age_group) == age_group)
            count_stmt = count_stmt.where(func.lower(KnowledgeMetadata.age_group) == age_group)
        if organization := filters.get("organization"):
            stmt = stmt.where(func.lower(KnowledgeMetadata.organization) == organization)
            count_stmt = count_stmt.where(func.lower(KnowledgeMetadata.organization) == organization)
        if priority_level := filters.get("priority_level"):
            stmt = stmt.where(func.lower(KnowledgeMetadata.priority_level) == priority_level)
            count_stmt = count_stmt.where(func.lower(KnowledgeMetadata.priority_level) == priority_level)
        if evidence_level := filters.get("evidence_level"):
            stmt = stmt.where(func.lower(KnowledgeMetadata.evidence_level) == evidence_level)
            count_stmt = count_stmt.where(func.lower(KnowledgeMetadata.evidence_level) == evidence_level)
        if min_quality_score := filters.get("min_quality_score"):
            stmt = stmt.where(KnowledgeQuality.quality_score >= min_quality_score)
            count_stmt = count_stmt.where(KnowledgeQuality.quality_score >= min_quality_score)

        sort_by = filters.get("sort_by", "updated_at")
        sort_direction = filters.get("sort_direction", "desc")
        sort_column = {
            "publication_date": KnowledgeMetadata.publication_date,
            "quality_score": KnowledgeQuality.quality_score,
            "title": KnowledgeObject.title,
        }.get(sort_by, KnowledgeObject.updated_at)
        stmt = stmt.order_by(sort_column.desc() if sort_direction == "desc" else sort_column.asc())
        stmt = stmt.offset(pagination.offset).limit(pagination.page_size)
        result = await self.session.execute(stmt)
        total_items = int((await self.session.execute(count_stmt)).scalar_one())
        return PaginatedResponse(
            items=list(result.scalars().unique().all()),
            meta=build_pagination_meta(total_items=total_items, page=pagination.page, page_size=pagination.page_size),
        )

    async def list_existing_for_duplicate_detection(self, *, organization: str | None, topic: str) -> list[dict]:
        stmt = (
            select(
                KnowledgeObject.id,
                KnowledgeObject.title,
                KnowledgeObject.body,
                KnowledgeMetadata.organization,
                KnowledgeMetadata.publication_date,
            )
            .join(KnowledgeMetadata, KnowledgeMetadata.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id)
            .where(KnowledgeTopic.topic == topic, KnowledgeTopic.is_primary.is_(True))
        )
        if organization:
            stmt = stmt.where(KnowledgeMetadata.organization == organization)
        result = await self.session.execute(stmt)
        return [dict(item._mapping) for item in result]

    async def find_by_source_document(self, source_document: str) -> list[KnowledgeObject]:
        result = await self.session.execute(
            select(KnowledgeObject).where(KnowledgeObject.source_document == source_document)
        )
        return list(result.scalars().all())

    async def topic_counts(self) -> list[dict[str, int | str]]:
        result = await self.session.execute(
            select(KnowledgeTopic.topic, func.count(KnowledgeTopic.id))
            .where(KnowledgeTopic.is_primary.is_(True))
            .group_by(KnowledgeTopic.topic)
            .order_by(func.count(KnowledgeTopic.id).desc(), KnowledgeTopic.topic.asc())
        )
        return [{"topic": topic, "total": total} for topic, total in result]

    async def statistics(self) -> dict:
        topic_rows = await self.session.execute(
            select(KnowledgeTopic.topic, func.count(KnowledgeTopic.id))
            .where(KnowledgeTopic.is_primary.is_(True))
            .group_by(KnowledgeTopic.topic)
        )
        metadata_rows = await self.session.execute(
            select(
                KnowledgeMetadata.audience,
                KnowledgeMetadata.age_group,
                KnowledgeMetadata.priority_level,
            )
        )
        quality_rows = await self.session.execute(select(KnowledgeQuality.quality_score))
        total_knowledge_objects = int((await self.session.execute(select(func.count(KnowledgeObject.id)))).scalar_one())

        topic_distribution = {topic: total for topic, total in topic_rows}
        audience_counter: Counter[str] = Counter()
        age_counter: Counter[str] = Counter()
        priority_counter: Counter[str] = Counter()
        for audience, age_group, priority_level in metadata_rows:
            audience_counter[audience] += 1
            age_counter[age_group] += 1
            priority_counter[priority_level] += 1

        quality_distribution = {"high": 0, "medium": 0, "low": 0}
        for (score,) in quality_rows:
            if score >= 80:
                quality_distribution["high"] += 1
            elif score >= 60:
                quality_distribution["medium"] += 1
            else:
                quality_distribution["low"] += 1

        return {
            "total_knowledge_objects": total_knowledge_objects,
            "topic_distribution": topic_distribution,
            "audience_distribution": dict(audience_counter),
            "age_distribution": dict(age_counter),
            "priority_distribution": dict(priority_counter),
            "quality_distribution": quality_distribution,
        }

    async def quality_report(self, *, threshold: float = 70.0) -> dict:
        result = await self.session.execute(
            select(
                KnowledgeObject.id,
                KnowledgeObject.title,
                KnowledgeObject.source_document,
                KnowledgeTopic.topic,
                KnowledgeQuality.quality_score,
                KnowledgeQuality.warnings,
            )
            .join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeQuality, KnowledgeQuality.knowledge_object_id == KnowledgeObject.id)
            .where(KnowledgeTopic.is_primary.is_(True))
            .order_by(KnowledgeQuality.quality_score.asc(), KnowledgeObject.title.asc())
        )
        items = [
            {
                "id": item.id,
                "title": item.title,
                "source_document": item.source_document,
                "topic": item.topic,
                "quality_score": item.quality_score,
                "warnings": item.warnings,
            }
            for item in result
        ]
        average_quality_score = round(sum(item["quality_score"] for item in items) / len(items), 2) if items else 0.0
        below_threshold_count = sum(1 for item in items if item["quality_score"] < threshold)
        return {
            "items": items,
            "average_quality_score": average_quality_score,
            "below_threshold_count": below_threshold_count,
        }

