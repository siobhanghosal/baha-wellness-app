from __future__ import annotations

from collections import Counter
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from baha_companion.embeddings.models import EmbeddingModel, KnowledgeEmbedding
from baha_companion.knowledge.models import KnowledgeMetadata, KnowledgeObject, KnowledgeQuality, KnowledgeTopic
from baha_companion.retrieval.models import RetrievalCandidate, RetrievalFilters


class RetrievalRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_candidates(
        self,
        *,
        filters: RetrievalFilters,
        model_key: str | None,
    ) -> list[RetrievalCandidate]:
        stmt: Select[tuple[KnowledgeObject]] = (
            select(KnowledgeObject)
            .join(KnowledgeMetadata, KnowledgeMetadata.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeQuality, KnowledgeQuality.knowledge_object_id == KnowledgeObject.id)
            .join(KnowledgeTopic, KnowledgeTopic.knowledge_object_id == KnowledgeObject.id)
            .where(KnowledgeTopic.is_primary.is_(True))
            .options(
                selectinload(KnowledgeObject.topics),
                selectinload(KnowledgeObject.keywords),
                selectinload(KnowledgeObject.citations),
                selectinload(KnowledgeObject.faqs),
                selectinload(KnowledgeObject.activities),
            )
        )
        stmt = self._apply_filters(stmt, filters)
        result = await self.session.execute(stmt)
        objects = list(result.scalars().unique().all())
        embedding_map = await self._current_embeddings(
            knowledge_object_ids=[item.id for item in objects],
            model_key=model_key,
        )
        return [
            RetrievalCandidate(
                knowledge_object_id=item.id,
                title=item.title,
                summary=item.summary,
                body=item.body,
                topic=next((topic.topic for topic in item.topics if topic.is_primary), None),
                subtopic=next((topic.subtopic for topic in item.topics if topic.is_primary), None),
                audience=item.details.audience,
                age_group=item.details.age_group,
                gender=item.details.gender,
                organisation=item.details.organization,
                priority=item.details.priority_level,
                evidence_level=item.details.evidence_level,
                publication_date=item.details.publication_date,
                country=item.details.country,
                language=item.details.language,
                keywords=[keyword.keyword for keyword in sorted(item.keywords, key=lambda row: row.sort_order)],
                retrieval_summary=embedding_map.get(item.id, {}).get("retrieval_summary", item.summary),
                retrieval_document=embedding_map.get(item.id, {}).get("retrieval_document", item.body),
                embedding_vector=embedding_map.get(item.id, {}).get("embedding_vector"),
                metadata={
                    "source_document": item.source_document,
                    "quality_score": item.quality.quality_score,
                    "quality_warnings": item.quality.warnings,
                },
            )
            for item in objects
        ]

    async def statistics(self, *, model_key: str | None) -> dict:
        total_knowledge_objects = int((await self.session.execute(select(func.count(KnowledgeObject.id)))).scalar_one())
        priority_rows = await self.session.execute(select(KnowledgeMetadata.priority_level))
        organisation_rows = await self.session.execute(select(KnowledgeMetadata.organization))
        topic_rows = await self.session.execute(
            select(KnowledgeTopic.topic).where(KnowledgeTopic.is_primary.is_(True))
        )
        embedded_objects_stmt = (
            select(func.count(func.distinct(KnowledgeEmbedding.knowledge_object_id)))
            .where(KnowledgeEmbedding.is_current.is_(True))
        )
        if model_key:
            embedded_objects_stmt = embedded_objects_stmt.join(
                EmbeddingModel,
                EmbeddingModel.id == KnowledgeEmbedding.model_id,
            ).where(EmbeddingModel.model_key == model_key)
        embedded_objects = int((await self.session.execute(embedded_objects_stmt)).scalar_one())

        priority_counter = Counter(priority for (priority,) in priority_rows)
        organisation_counter = Counter(organisation or "unknown" for (organisation,) in organisation_rows)
        topic_counter = Counter(topic for (topic,) in topic_rows)
        return {
            "total_knowledge_objects": total_knowledge_objects,
            "current_embedded_objects": embedded_objects,
            "priority_distribution": dict(priority_counter),
            "organisation_distribution": dict(organisation_counter),
            "topic_distribution": dict(topic_counter),
        }

    def _apply_filters(
        self,
        stmt: Select[tuple[KnowledgeObject]],
        filters: RetrievalFilters,
    ) -> Select[tuple[KnowledgeObject]]:
        if filters.topic:
            stmt = stmt.where(func.lower(KnowledgeTopic.topic) == filters.topic.lower())
        if filters.subtopic:
            stmt = stmt.where(func.lower(KnowledgeTopic.subtopic) == filters.subtopic.lower())
        if filters.audience:
            stmt = stmt.where(func.lower(KnowledgeMetadata.audience) == filters.audience.lower())
        if filters.age_group:
            stmt = stmt.where(func.lower(KnowledgeMetadata.age_group) == filters.age_group.lower())
        if filters.gender:
            stmt = stmt.where(func.lower(KnowledgeMetadata.gender) == filters.gender.lower())
        if filters.organisation:
            stmt = stmt.where(func.lower(KnowledgeMetadata.organization) == filters.organisation.lower())
        if filters.priority:
            stmt = stmt.where(func.lower(KnowledgeMetadata.priority_level) == filters.priority.lower())
        if filters.evidence_level:
            stmt = stmt.where(func.lower(KnowledgeMetadata.evidence_level) == filters.evidence_level.lower())
        if filters.language:
            stmt = stmt.where(func.lower(KnowledgeMetadata.language) == filters.language.lower())
        if filters.country:
            stmt = stmt.where(func.lower(KnowledgeMetadata.country) == filters.country.lower())
        if filters.publication_date_from:
            stmt = stmt.where(KnowledgeMetadata.publication_date >= filters.publication_date_from)
        if filters.publication_date_to:
            stmt = stmt.where(KnowledgeMetadata.publication_date <= filters.publication_date_to)
        return stmt.order_by(KnowledgeObject.updated_at.desc(), KnowledgeObject.created_at.desc())

    async def _current_embeddings(
        self,
        *,
        knowledge_object_ids: list[UUID],
        model_key: str | None,
    ) -> dict[UUID, dict]:
        if not knowledge_object_ids:
            return {}

        stmt = (
            select(
                KnowledgeEmbedding.knowledge_object_id,
                KnowledgeEmbedding.embedding_vector,
                KnowledgeEmbedding.retrieval_summary,
                KnowledgeEmbedding.retrieval_document,
            )
            .where(
                KnowledgeEmbedding.knowledge_object_id.in_(knowledge_object_ids),
                KnowledgeEmbedding.is_current.is_(True),
            )
        )
        if model_key:
            stmt = stmt.join(EmbeddingModel, EmbeddingModel.id == KnowledgeEmbedding.model_id).where(
                EmbeddingModel.model_key == model_key
            )
        result = await self.session.execute(stmt)
        return {
            knowledge_object_id: {
                "embedding_vector": embedding_vector,
                "retrieval_summary": retrieval_summary,
                "retrieval_document": retrieval_document,
            }
            for knowledge_object_id, embedding_vector, retrieval_summary, retrieval_document in result
        }
