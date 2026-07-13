from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.api.dependencies import get_chat_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.chat.models import ConversationStatus
from baha_companion.chat.schemas import (
    ConversationCreateRequest,
    ConversationDetail,
    ConversationListResponse,
    ConversationRead,
    ConversationUpdateRequest,
    MessageListResponse,
    MessageCreateRequest,
    MessageRead,
)
from baha_companion.chat.service import ChatService
from baha_companion.common.pagination import PaginationParams, pagination_params
from baha_companion.database.session import get_session
from baha_companion.middleware.rate_limit import settings_rate_limit_dependency
from baha_companion.middleware.request_context import set_conversation_id
from baha_companion.users.models import User

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/conversations", response_model=ConversationDetail, status_code=201)
async def create_conversation(
    request: ConversationCreateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
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
) -> ConversationDetail:
    conversation = await service.create_conversation(user_id=current_user.id, request=request)
    await session.commit()
    return ConversationDetail.model_validate(conversation)


@router.get("/conversations", response_model=ConversationListResponse)
async def list_conversations(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
    pagination: Annotated[PaginationParams, Depends(pagination_params)],
    status: ConversationStatus | None = Query(default=None),
    sort_by: str = Query(default="last_message_at", pattern="^(last_message_at|created_at)$"),
    sort_direction: str = Query(default="desc", pattern="^(asc|desc)$"),
) -> ConversationListResponse:
    conversations = await service.list_conversations(
        user_id=current_user.id,
        pagination=pagination,
        status=status,
        sort_by=sort_by,
        sort_direction=sort_direction,
    )
    return ConversationListResponse(
        items=[ConversationRead.model_validate(conversation) for conversation in conversations.items],
        meta=conversations.meta,
    )


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
) -> ConversationDetail:
    set_conversation_id(str(conversation_id))
    conversation = await service.get_conversation(
        conversation_id=conversation_id,
        user_id=current_user.id,
        include_messages=True,
    )
    return ConversationDetail.model_validate(conversation)


@router.post("/conversations/{conversation_id}/messages", response_model=MessageRead, status_code=201)
async def add_message(
    conversation_id: UUID,
    request: MessageCreateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
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
) -> MessageRead:
    set_conversation_id(str(conversation_id))
    message = await service.add_user_message(
        conversation_id=conversation_id,
        user_id=current_user.id,
        request=request,
    )
    await session.commit()
    return MessageRead.model_validate(message)


@router.get("/conversations/{conversation_id}/messages", response_model=MessageListResponse)
async def list_messages(
    conversation_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
    pagination: Annotated[PaginationParams, Depends(pagination_params)],
) -> MessageListResponse:
    set_conversation_id(str(conversation_id))
    messages = await service.list_messages(
        conversation_id=conversation_id,
        user_id=current_user.id,
        pagination=pagination,
    )
    return MessageListResponse(
        items=[MessageRead.model_validate(message) for message in messages.items],
        meta=messages.meta,
    )


@router.patch("/conversations/{conversation_id}", response_model=ConversationRead)
async def update_conversation(
    conversation_id: UUID,
    request: ConversationUpdateRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
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
) -> ConversationRead:
    set_conversation_id(str(conversation_id))
    conversation = await service.update_conversation(
        conversation_id=conversation_id,
        user_id=current_user.id,
        request=request,
    )
    await session.commit()
    return ConversationRead.model_validate(conversation)


@router.delete("/conversations/{conversation_id}", status_code=204)
async def delete_conversation(
    conversation_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[ChatService, Depends(get_chat_service)],
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
) -> Response:
    set_conversation_id(str(conversation_id))
    await service.delete_conversation(conversation_id=conversation_id, user_id=current_user.id)
    await session.commit()
    return Response(status_code=204)
