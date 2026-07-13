from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status

from baha_companion.api.dependencies import get_llm_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.authentication.schemas import ActionAcceptedResponse
from baha_companion.llm.schemas import (
    ChatCompletionResponse,
    ChatModelsResponse,
    ChatStatisticsResponse,
    LLMGenerationRequest,
    LLMRegenerateRequest,
    LLMStopRequest,
)
from baha_companion.llm.service import LLMService
from baha_companion.middleware.rate_limit import settings_rate_limit_dependency
from baha_companion.users.models import User

router = APIRouter(prefix="/chat", tags=["LLM Chat"])


@router.post("", response_model=ChatCompletionResponse, status_code=status.HTTP_200_OK)
async def generate_chat_response(
    request: LLMGenerationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="chat_write",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
) -> ChatCompletionResponse:
    response = await service.generate(request=request, user=current_user)
    await service.repository.session.commit()
    return response


@router.post("/stream")
async def stream_chat_response(
    request: LLMGenerationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="chat_write",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
):
    return await service.stream(request=request, user=current_user)


@router.post("/regenerate", response_model=ChatCompletionResponse)
async def regenerate_chat_response(
    request: LLMRegenerateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="chat_write",
                attempts_setting="write_rate_limit_attempts",
                window_setting="write_rate_limit_window_seconds",
            )
        ),
    ],
) -> ChatCompletionResponse:
    response = await service.regenerate(request=request, user=current_user)
    await service.repository.session.commit()
    return response


@router.post("/stop", response_model=ActionAcceptedResponse, status_code=status.HTTP_202_ACCEPTED)
async def stop_chat_generation(
    request: LLMStopRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
) -> ActionAcceptedResponse:
    cancelled = service.stop(stream_id=request.stream_id, user=current_user)
    detail = "Generation cancellation requested." if cancelled else "No active generation matched the request."
    return ActionAcceptedResponse(detail=detail)


@router.get("/models", response_model=ChatModelsResponse)
async def list_chat_models(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
) -> ChatModelsResponse:
    return service.models()


@router.get("/statistics", response_model=ChatStatisticsResponse)
async def chat_statistics(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[LLMService, Depends(get_llm_service)],
) -> ChatStatisticsResponse:
    return await service.statistics(user=current_user)
