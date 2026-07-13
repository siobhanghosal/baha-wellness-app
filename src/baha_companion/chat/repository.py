from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from baha_companion.chat.models import Conversation, ConversationStatus, Message, MessageSender
from baha_companion.common.pagination import PaginationParams, build_pagination_meta
from baha_companion.common.schemas import PaginatedResponse


class ChatRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_conversation(
        self,
        *,
        user_id: UUID,
        title: str | None,
        summary: str | None = None,
        metadata: dict | None = None,
    ) -> Conversation:
        conversation = Conversation(user_id=user_id, title=title, summary=summary, metadata_=metadata or {})
        self.session.add(conversation)
        await self.session.flush()
        await self.session.refresh(conversation)
        return conversation

    async def list_conversations(
        self,
        *,
        user_id: UUID,
        pagination: PaginationParams,
        status: ConversationStatus | None = None,
        sort_by: str = "last_message_at",
        sort_direction: str = "desc",
    ) -> PaginatedResponse[Conversation]:
        stmt: Select[tuple[Conversation]] = (
            select(Conversation)
            .where(Conversation.user_id == user_id)
        )
        count_stmt = select(func.count(Conversation.id)).where(Conversation.user_id == user_id)
        if status is not None:
            stmt = stmt.where(Conversation.status == status)
            count_stmt = count_stmt.where(Conversation.status == status)
        sort_column = Conversation.last_message_at if sort_by == "last_message_at" else Conversation.created_at
        stmt = stmt.order_by(sort_column.desc() if sort_direction == "desc" else sort_column.asc())
        stmt = stmt.offset(pagination.offset).limit(pagination.page_size)
        result = await self.session.execute(stmt)
        total_items = int((await self.session.execute(count_stmt)).scalar_one())
        return PaginatedResponse(
            items=list(result.scalars().all()),
            meta=build_pagination_meta(
                total_items=total_items,
                page=pagination.page,
                page_size=pagination.page_size,
            ),
        )

    async def get_conversation(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        include_messages: bool = False,
    ) -> Conversation | None:
        stmt = select(Conversation).where(Conversation.id == conversation_id, Conversation.user_id == user_id)
        if include_messages:
            stmt = stmt.options(selectinload(Conversation.messages))
        stmt = stmt.execution_options(populate_existing=True)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def next_sequence_number(self, *, conversation_id: UUID | str) -> int:
        result = await self.session.execute(
            select(func.coalesce(func.max(Message.sequence_number), 0) + 1).where(
                Message.conversation_id == conversation_id
            )
        )
        return int(result.scalar_one())

    async def create_message(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID | None,
        role: MessageSender,
        content: str,
        markdown: bool = False,
        token_count: int | None = None,
        latency: int | None = None,
        citations: list | None = None,
        metadata: dict | None = None,
        llm_response_id: str | None = None,
    ) -> Message:
        message = Message(
            conversation_id=conversation_id,
            user_id=user_id,
            role=role,
            content=content,
            markdown=markdown,
            token_count=token_count,
            latency=latency,
            citations=citations or [],
            sequence_number=await self.next_sequence_number(conversation_id=conversation_id),
            metadata_=metadata or {},
            llm_response_id=llm_response_id,
        )
        self.session.add(message)
        conversation = await self.session.get(Conversation, conversation_id)
        if conversation is not None:
            conversation.updated_at = datetime.now(UTC)
            conversation.last_message_at = message.created_at if message.created_at else None
            conversation.message_count = (conversation.message_count or 0) + 1
        await self.session.flush()
        if conversation is not None:
            conversation.last_message_at = message.created_at
        await self.session.refresh(message)
        return message

    async def list_messages(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        pagination: PaginationParams,
    ) -> PaginatedResponse[Message]:
        count_stmt = (
            select(func.count(Message.id))
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Message.conversation_id == conversation_id, Conversation.user_id == user_id)
        )
        stmt = (
            select(Message)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Message.conversation_id == conversation_id, Conversation.user_id == user_id)
            .order_by(Message.sequence_number.asc())
            .offset(pagination.offset)
            .limit(pagination.page_size)
        )
        total_items = int((await self.session.execute(count_stmt)).scalar_one())
        result = await self.session.execute(stmt)
        return PaginatedResponse(
            items=list(result.scalars().all()),
            meta=build_pagination_meta(
                total_items=total_items,
                page=pagination.page,
                page_size=pagination.page_size,
            ),
        )

    async def list_recent_messages(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        limit: int,
        before_sequence: int | None = None,
    ) -> list[Message]:
        stmt = (
            select(Message)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Message.conversation_id == conversation_id, Conversation.user_id == user_id)
            .order_by(Message.sequence_number.desc())
            .limit(limit)
        )
        if before_sequence is not None:
            stmt = stmt.where(Message.sequence_number < before_sequence)
        result = await self.session.execute(stmt)
        return list(reversed(result.scalars().all()))

    async def get_message(
        self,
        *,
        message_id: UUID | str,
        user_id: UUID,
    ) -> Message | None:
        stmt = (
            select(Message)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Message.id == message_id, Conversation.user_id == user_id)
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_llm_messages(self, *, user_id: UUID) -> list[Message]:
        stmt = (
            select(Message)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Conversation.user_id == user_id, Message.role == MessageSender.ASSISTANT)
            .options(selectinload(Message.conversation))
            .order_by(Message.created_at.desc())
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().unique().all())

    async def update_conversation(
        self,
        conversation: Conversation,
        *,
        title: str | None,
        summary: str | None,
        status: ConversationStatus | None,
        metadata: dict | None,
    ) -> Conversation:
        if title is not None:
            conversation.title = title
        if summary is not None:
            conversation.summary = summary
        if status is not None:
            conversation.status = status
        if metadata is not None:
            conversation.metadata_ = metadata
        await self.session.flush()
        await self.session.refresh(conversation)
        return conversation

    async def soft_delete_conversation(self, conversation: Conversation) -> Conversation:
        conversation.deleted_at = datetime.now(UTC)
        conversation.status = ConversationStatus.ARCHIVED
        await self.session.flush()
        return conversation
