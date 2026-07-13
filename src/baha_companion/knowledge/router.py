from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.api.dependencies import get_knowledge_processing_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.common.pagination import PaginationParams, pagination_params
from baha_companion.database.session import get_session
from baha_companion.knowledge.schemas import (
    KnowledgeListResponse,
    KnowledgeObjectRead,
    KnowledgeQualityResponse,
    KnowledgeQueryFilters,
    KnowledgeStatisticsResponse,
    KnowledgeTopicsResponse,
    ProcessBatchRequest,
    ProcessBatchResponse,
    ProcessDocumentRequest,
    ProcessDocumentResponse,
    QualityListItem,
    TopicSummary,
)
from baha_companion.knowledge.service import KnowledgeProcessingService
from baha_companion.middleware.rate_limit import settings_rate_limit_dependency
from baha_companion.users.models import User

router = APIRouter(tags=["Knowledge"])


def serialize_knowledge_object(knowledge_object) -> KnowledgeObjectRead:
    primary_topic = next((item for item in knowledge_object.topics if item.is_primary), knowledge_object.topics[0])
    return KnowledgeObjectRead(
        id=knowledge_object.id,
        title=knowledge_object.title,
        topic=primary_topic.topic,
        subtopic=primary_topic.subtopic,
        summary=knowledge_object.summary,
        body=knowledge_object.body,
        organization=knowledge_object.details.organization,
        source_document=knowledge_object.source_document,
        document_url=knowledge_object.details.document_url,
        publication_date=knowledge_object.details.publication_date,
        country=knowledge_object.details.country,
        language=knowledge_object.details.language,
        audience=knowledge_object.details.audience,
        age_group=knowledge_object.details.age_group,
        gender=knowledge_object.details.gender,
        evidence_level=knowledge_object.details.evidence_level,
        evidence_confidence=knowledge_object.details.evidence_confidence,
        clinical_review_status=knowledge_object.details.clinical_review_status,
        priority_level=knowledge_object.details.priority_level,
        citations=knowledge_object.citations,
        activities=knowledge_object.activities,
        faqs=knowledge_object.faqs,
        keywords=[item.keyword for item in sorted(knowledge_object.keywords, key=lambda item: item.sort_order)],
        reading_level=knowledge_object.details.reading_level,
        tags=list(knowledge_object.details.tags),
        metadata=knowledge_object.metadata_,
        quality=knowledge_object.quality,
        created_at=knowledge_object.created_at,
        updated_at=knowledge_object.updated_at,
    )


@router.post("/process/document", response_model=ProcessDocumentResponse, status_code=status.HTTP_202_ACCEPTED)
async def process_document(
    request: ProcessDocumentRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="knowledge_process",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
) -> ProcessDocumentResponse:
    response = await service.process_document(request)
    await session.commit()
    return response


@router.post("/process/batch", response_model=ProcessBatchResponse, status_code=status.HTTP_202_ACCEPTED)
async def process_batch(
    request: ProcessBatchRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="knowledge_process_batch",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
) -> ProcessBatchResponse:
    response = await service.process_batch(request)
    await session.commit()
    return response


@router.get("/knowledge", response_model=KnowledgeListResponse)
async def list_knowledge(
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
    pagination: Annotated[PaginationParams, Depends(pagination_params)],
    topic: str | None = Query(default=None),
    audience: str | None = Query(default=None),
    age_group: str | None = Query(default=None),
    organization: str | None = Query(default=None),
    priority_level: str | None = Query(default=None),
    evidence_level: str | None = Query(default=None),
    min_quality_score: float | None = Query(default=None, ge=0, le=100),
    sort_by: str = Query(default="updated_at", pattern="^(updated_at|publication_date|quality_score|title)$"),
    sort_direction: str = Query(default="desc", pattern="^(asc|desc)$"),
) -> KnowledgeListResponse:
    filters = KnowledgeQueryFilters(
        topic=topic,
        audience=audience,
        age_group=age_group,
        organization=organization,
        priority_level=priority_level,
        evidence_level=evidence_level,
        min_quality_score=min_quality_score,
        sort_by=sort_by,
        sort_direction=sort_direction,
    )
    result = await service.list_knowledge(pagination=pagination, filters=filters)
    return KnowledgeListResponse(
        items=[serialize_knowledge_object(item) for item in result.items],
        meta=result.meta,
    )


@router.get("/knowledge/topics", response_model=KnowledgeTopicsResponse)
async def list_topics(
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
) -> KnowledgeTopicsResponse:
    return KnowledgeTopicsResponse(items=[TopicSummary(**item) for item in await service.topic_summary()])


@router.get("/knowledge/statistics", response_model=KnowledgeStatisticsResponse)
async def statistics(
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
) -> KnowledgeStatisticsResponse:
    return KnowledgeStatisticsResponse(**(await service.statistics()))


@router.get("/knowledge/quality", response_model=KnowledgeQualityResponse)
async def quality_report(
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
) -> KnowledgeQualityResponse:
    report = await service.quality_report()
    return KnowledgeQualityResponse(
        items=[QualityListItem(**item) for item in report["items"]],
        average_quality_score=report["average_quality_score"],
        below_threshold_count=report["below_threshold_count"],
    )


@router.get("/knowledge/{knowledge_object_id}", response_model=KnowledgeObjectRead)
async def get_knowledge(
    knowledge_object_id: UUID,
    service: Annotated[KnowledgeProcessingService, Depends(get_knowledge_processing_service)],
) -> KnowledgeObjectRead:
    knowledge_object = await service.get_knowledge(knowledge_object_id)
    return serialize_knowledge_object(knowledge_object)
