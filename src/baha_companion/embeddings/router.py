from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.api.dependencies import get_embedding_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.database.session import get_session
from baha_companion.embeddings.schemas import (
    EmbeddingEnqueueRequest,
    EmbeddingJobRead,
    EmbeddingModelRead,
    EmbeddingQueueResponse,
    EmbeddingRebuildRequest,
    EmbeddingRetryRequest,
    EmbeddingRunRequest,
    EmbeddingRunResponse,
    EmbeddingStatisticsResponse,
    EmbeddingStatusResponse,
)
from baha_companion.embeddings.service import EmbeddingService
from baha_companion.middleware.rate_limit import settings_rate_limit_dependency
from baha_companion.users.models import User

router = APIRouter(prefix="/embeddings", tags=["Embeddings"])


@router.post("/run", response_model=EmbeddingRunResponse, status_code=status.HTTP_202_ACCEPTED)
async def run_embeddings(
    request: EmbeddingRunRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="embedding_run",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
) -> EmbeddingRunResponse:
    result = await service.run(
        limit=request.limit,
        worker_name=request.worker_name,
        version_label=request.version_label,
        model_key=request.model_key,
    )
    await session.commit()
    return EmbeddingRunResponse(**result)


@router.post("/object/{knowledge_object_id}", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_object(
    knowledge_object_id: UUID,
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_object(
        knowledge_object_id=knowledge_object_id,
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/topic/{topic}", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_topic(
    topic: str,
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_topic(
        topic=topic,
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/organisation/{organisation}", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_organisation(
    organisation: str,
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_organisation(
        organisation=organisation,
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/audience/{audience}", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_audience(
    audience: str,
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_audience(
        audience=audience,
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/age-group/{age_group}", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_age_group(
    age_group: str,
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_age_group(
        age_group=age_group,
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/all", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def enqueue_all(
    request: EmbeddingEnqueueRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.queue_all(
        version_label=request.version_label,
        model_key=request.model_key,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/rebuild", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def rebuild_embeddings(
    request: EmbeddingRebuildRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    result = await service.rebuild(
        version_label=request.version_label,
        model_key=request.model_key,
        topic=request.topic,
        organisation=request.organisation,
        audience=request.audience,
        age_group=request.age_group,
        force=request.force,
    )
    await session.commit()
    return EmbeddingQueueResponse(**result)


@router.post("/retry", response_model=EmbeddingQueueResponse, status_code=status.HTTP_202_ACCEPTED)
async def retry_failed_jobs(
    request: EmbeddingRetryRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingQueueResponse:
    retried = await service.retry_failed(limit=request.limit)
    await session.commit()
    return EmbeddingQueueResponse(
        queued_jobs=retried,
        model_key=service.settings.active_model.key,
        version_label=service.settings.embedding_active_version,
        scope="retry",
    )


@router.get("/status", response_model=EmbeddingStatusResponse)
async def embedding_status(
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingStatusResponse:
    status_payload = await service.status()
    return EmbeddingStatusResponse(
        pending=status_payload["pending"],
        processing=status_payload["processing"],
        completed=status_payload["completed"],
        failed=status_payload["failed"],
        cancelled=status_payload["cancelled"],
        retry=status_payload["retry"],
        active_model_key=status_payload["active_model_key"],
        active_version=status_payload["active_version"],
        recent_jobs=[EmbeddingJobRead.model_validate(item) for item in status_payload["recent_jobs"]],
    )


@router.get("/statistics", response_model=EmbeddingStatisticsResponse)
async def embedding_statistics(
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> EmbeddingStatisticsResponse:
    return EmbeddingStatisticsResponse(**(await service.statistics()))


@router.get("/models", response_model=list[EmbeddingModelRead])
async def embedding_models(
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[EmbeddingService, Depends(get_embedding_service)],
) -> list[EmbeddingModelRead]:
    return [EmbeddingModelRead(**item) for item in await service.models()]
