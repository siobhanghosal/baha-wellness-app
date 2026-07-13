from __future__ import annotations

from uuid import UUID

from baha_companion.chat.models import ConversationStatus, MessageSender
from baha_companion.chat.repository import ChatRepository
from baha_companion.chat.schemas import ConversationCreateRequest, ConversationUpdateRequest, MessageCreateRequest
from baha_companion.common.exceptions import NotFoundError
from baha_companion.common.pagination import PaginationParams
from baha_companion.common.schemas import PaginatedResponse
from baha_companion.common.sanitization import sanitize_text


class ChatService:
    def __init__(self, repository: ChatRepository) -> None:
        self.repository = repository

    async def create_conversation(self, *, user_id: UUID, request: ConversationCreateRequest):
        conversation = await self.repository.create_conversation(
            user_id=user_id,
            title=request.title or self._derive_title(request.initial_message),
            summary=request.summary,
            metadata=request.metadata,
        )
        if request.initial_message:
            await self.repository.create_message(
                conversation_id=conversation.id,
                user_id=user_id,
                role=MessageSender.USER,
                content=request.initial_message,
                markdown=request.initial_markdown,
                token_count=self.estimate_token_count(request.initial_message),
            )
        return await self.get_conversation(conversation_id=conversation.id, user_id=user_id, include_messages=True)

    async def list_conversations(
        self,
        *,
        user_id: UUID,
        pagination: PaginationParams,
        status: ConversationStatus | None = None,
        sort_by: str = "last_message_at",
        sort_direction: str = "desc",
    ) -> PaginatedResponse:
        return await self.repository.list_conversations(
            user_id=user_id,
            pagination=pagination,
            status=status,
            sort_by=sort_by,
            sort_direction=sort_direction,
        )

    async def get_conversation(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        include_messages: bool = False,
    ):
        conversation = await self.repository.get_conversation(
            conversation_id=conversation_id,
            user_id=user_id,
            include_messages=include_messages,
        )
        if conversation is None:
            raise NotFoundError("Conversation not found.")
        return conversation

    async def add_user_message(self, *, conversation_id: UUID | str, user_id: UUID, request: MessageCreateRequest):
        await self.get_conversation(conversation_id=conversation_id, user_id=user_id)
        return await self.repository.create_message(
            conversation_id=conversation_id,
            user_id=user_id,
            role=MessageSender.USER,
            content=request.content,
            markdown=request.markdown,
            token_count=self.estimate_token_count(request.content),
            metadata=request.metadata,
        )

    async def list_messages(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        pagination: PaginationParams,
    ) -> PaginatedResponse:
        await self.get_conversation(conversation_id=conversation_id, user_id=user_id)
        return await self.repository.list_messages(
            conversation_id=conversation_id,
            user_id=user_id,
            pagination=pagination,
        )

    async def update_conversation(
        self,
        *,
        conversation_id: UUID | str,
        user_id: UUID,
        request: ConversationUpdateRequest,
    ):
        conversation = await self.get_conversation(conversation_id=conversation_id, user_id=user_id)
        return await self.repository.update_conversation(
            conversation,
            title=request.title,
            summary=request.summary,
            status=request.status,
            metadata=request.metadata,
        )

    async def delete_conversation(self, *, conversation_id: UUID | str, user_id: UUID):
        conversation = await self.get_conversation(conversation_id=conversation_id, user_id=user_id)
        return await self.repository.soft_delete_conversation(conversation)

    @staticmethod
    def _derive_title(initial_message: str | None) -> str | None:
        if not initial_message:
            return None
        cleaned = sanitize_text(initial_message)
        return cleaned[:80]

    @staticmethod
    def estimate_token_count(content: str) -> int:
        return max(1, len(content.split()))
