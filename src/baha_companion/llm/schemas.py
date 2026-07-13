from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import ConfigDict, Field, field_validator

from baha_companion.chat.schemas import ConversationRead, MessageRead
from baha_companion.common.schemas import APIModel
from baha_companion.common.sanitization import sanitize_optional_text, sanitize_text
from baha_companion.llm.prompt_builder import PromptProfile
from baha_companion.retrieval.schemas import RetrievalFiltersInput


class LLMGenerationRequest(APIModel):
    question: str = Field(min_length=1, max_length=5000)
    conversation_id: UUID | None = None
    title: str | None = Field(default=None, max_length=255)
    profile: PromptProfile | None = None
    filters: RetrievalFiltersInput = Field(default_factory=RetrievalFiltersInput)
    top_k: int = Field(default=5, ge=1, le=20)
    conversation_metadata: dict = Field(default_factory=dict)
    message_metadata: dict = Field(default_factory=dict)
    model: str | None = Field(default=None, max_length=128)
    temperature: float | None = Field(default=None, ge=0, le=2)
    top_p: float | None = Field(default=None, ge=0, le=1)
    max_tokens: int | None = Field(default=None, ge=64, le=16_384)
    frequency_penalty: float | None = Field(default=None, ge=-2, le=2)
    presence_penalty: float | None = Field(default=None, ge=-2, le=2)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "question": "What can I do when exams make me feel overwhelmed?",
                "title": "Exam stress support",
                "profile": "student",
                "filters": {"topic": "stress", "audience": "student"},
                "top_k": 5,
                "message_metadata": {"source": "ios"},
            }
        }
    )

    @field_validator("question", mode="before")
    @classmethod
    def sanitize_question(cls, value: str) -> str:
        return sanitize_text(value)

    @field_validator("title", mode="before")
    @classmethod
    def sanitize_title(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class LLMRegenerateRequest(APIModel):
    conversation_id: UUID
    target_message_id: UUID | None = None
    profile: PromptProfile | None = None
    model: str | None = Field(default=None, max_length=128)
    temperature: float | None = Field(default=None, ge=0, le=2)
    top_p: float | None = Field(default=None, ge=0, le=1)
    max_tokens: int | None = Field(default=None, ge=64, le=16_384)
    frequency_penalty: float | None = Field(default=None, ge=-2, le=2)
    presence_penalty: float | None = Field(default=None, ge=-2, le=2)


class LLMStopRequest(APIModel):
    stream_id: str = Field(min_length=1, max_length=128)


class CitationRead(APIModel):
    source_id: str
    knowledge_object_id: str
    title: str
    organisation: str | None = None
    publication_date: date | None = None
    priority: str | None = None
    evidence_level: str | None = None


class TokenUsageRead(APIModel):
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


class CostBreakdownRead(APIModel):
    prompt_cost: float
    completion_cost: float
    total_cost: float
    currency: str = "USD"


class ValidationIssueRead(APIModel):
    code: str
    detail: str


class ResponseValidationRead(APIModel):
    sufficient_evidence: bool
    issues: list[ValidationIssueRead]


class ChatCompletionResponse(APIModel):
    conversation: ConversationRead
    message: MessageRead
    model_key: str
    model_name: str
    latency_ms: float
    retrieval_count: int
    usage: TokenUsageRead
    cost: CostBreakdownRead
    citations: list[CitationRead]
    validation: ResponseValidationRead


class ChatModelRead(APIModel):
    key: str
    provider: str
    model_name: str
    active: bool
    supports_streaming: bool
    input_token_price_per_million: float
    output_token_price_per_million: float
    max_context_tokens: int
    max_output_tokens: int


class ChatModelsResponse(APIModel):
    items: list[ChatModelRead]
    active_model_key: str


class ConversationCostRead(APIModel):
    conversation_id: UUID
    title: str | None = None
    message_count: int
    total_prompt_tokens: int
    total_completion_tokens: int
    total_tokens: int
    total_cost: float
    last_message_at: datetime | None = None


class ModelUsageRead(APIModel):
    model_key: str
    message_count: int
    total_prompt_tokens: int
    total_completion_tokens: int
    total_tokens: int
    total_cost: float


class PeriodCostRead(APIModel):
    period: str
    message_count: int
    total_cost: float


class ChatStatisticsResponse(APIModel):
    total_messages: int
    total_conversations: int
    total_prompt_tokens: int
    total_completion_tokens: int
    total_tokens: int
    total_cost: float
    conversations: list[ConversationCostRead]
    model_usage: list[ModelUsageRead]
    daily_cost: list[PeriodCostRead]
    monthly_cost: list[PeriodCostRead]
