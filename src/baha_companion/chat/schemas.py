from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import ConfigDict, Field, field_validator

from baha_companion.chat.models import ConversationStatus, MessageSender
from baha_companion.common.schemas import APIModel, PaginatedResponse
from baha_companion.common.sanitization import sanitize_optional_text, sanitize_text


class ConversationCreateRequest(APIModel):
    title: str | None = Field(default=None, max_length=255)
    initial_message: str | None = Field(default=None, min_length=1, max_length=5000)
    initial_markdown: bool = False
    summary: str | None = Field(default=None, max_length=4000)
    metadata: dict = Field(default_factory=dict)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "title": "Evening routine ideas",
                "initial_message": "I want help building a journaling routine.",
                "initial_markdown": False,
                "summary": "Conversation about habit building.",
                "metadata": {"source": "mobile"},
            }
        }
    )

    @field_validator("title", "summary", mode="before")
    @classmethod
    def sanitize_text_fields(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)

    @field_validator("initial_message", mode="before")
    @classmethod
    def sanitize_initial_message(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class ConversationRead(APIModel):
    id: UUID
    user_id: UUID
    title: str | None = None
    summary: str | None = None
    status: ConversationStatus
    last_message_at: datetime | None = None
    message_count: int
    embedding: list[float] | None = None
    metadata_: dict = Field(default_factory=dict, serialization_alias="metadata", validation_alias="metadata_")
    created_at: datetime
    updated_at: datetime


class ConversationUpdateRequest(APIModel):
    title: str | None = Field(default=None, max_length=255)
    summary: str | None = Field(default=None, max_length=4000)
    status: ConversationStatus | None = None
    metadata: dict | None = None

    @field_validator("title", "summary", mode="before")
    @classmethod
    def sanitize_text_fields(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class MessageCreateRequest(APIModel):
    content: str = Field(min_length=1, max_length=5000)
    markdown: bool = False
    metadata: dict = Field(default_factory=dict)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "content": "Can you save this as part of my conversation?",
                "markdown": False,
                "metadata": {"source": "web"},
            }
        }
    )

    @field_validator("content", mode="before")
    @classmethod
    def sanitize_content(cls, value: str) -> str:
        return sanitize_text(value)


class MessageRead(APIModel):
    id: UUID
    conversation_id: UUID
    user_id: UUID | None = None
    role: MessageSender
    content: str
    markdown: bool
    token_count: int | None = None
    latency: int | None = None
    citations: list = Field(default_factory=list)
    sequence_number: int
    metadata_: dict = Field(default_factory=dict, serialization_alias="metadata", validation_alias="metadata_")
    llm_response_id: str | None = None
    created_at: datetime
    updated_at: datetime


class ConversationDetail(APIModel):
    id: UUID
    user_id: UUID
    title: str | None = None
    summary: str | None = None
    status: ConversationStatus
    last_message_at: datetime | None = None
    message_count: int
    embedding: list[float] | None = None
    metadata_: dict = Field(default_factory=dict, serialization_alias="metadata", validation_alias="metadata_")
    created_at: datetime
    updated_at: datetime
    messages: list[MessageRead]


class ConversationListResponse(PaginatedResponse[ConversationRead]):
    pass


class MessageListResponse(PaginatedResponse[MessageRead]):
    pass
