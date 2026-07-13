from __future__ import annotations

import logging
from collections import defaultdict
from dataclasses import asdict
from datetime import UTC, date, datetime
from time import perf_counter
from uuid import UUID

from fastapi.responses import StreamingResponse

from baha_companion.chat.models import MessageSender
from baha_companion.chat.repository import ChatRepository
from baha_companion.chat.schemas import ConversationRead, MessageRead
from baha_companion.chat.service import ChatService
from baha_companion.common.exceptions import NotFoundError
from baha_companion.llm.client import GenerationOptions, OpenAIChatClient
from baha_companion.llm.config import LLMSettings
from baha_companion.llm.context_composer import ContextComposer
from baha_companion.llm.cost_tracker import CostTracker, UsageSnapshot
from baha_companion.llm.prompt_builder import PromptBuilder, PromptProfile
from baha_companion.llm.response_validator import ResponseValidator
from baha_companion.llm.schemas import (
    ChatCompletionResponse,
    ChatModelRead,
    ChatModelsResponse,
    ChatStatisticsResponse,
    CitationRead,
    ConversationCostRead,
    CostBreakdownRead,
    LLMGenerationRequest,
    LLMRegenerateRequest,
    ModelUsageRead,
    PeriodCostRead,
    ResponseValidationRead,
    TokenUsageRead,
    ValidationIssueRead,
)
from baha_companion.llm.streaming import StreamManager, sse_event
from baha_companion.llm.token_counter import TokenCounter
from baha_companion.middleware.request_context import get_request_id, set_conversation_id
from baha_companion.retrieval.models import RetrievalFilters
from baha_companion.retrieval.schemas import RetrievalFiltersInput
from baha_companion.retrieval.service import RetrievalService
from baha_companion.users.models import User

logger = logging.getLogger("baha_companion.llm")


class LLMService:
    def __init__(
        self,
        *,
        chat_service: ChatService,
        retrieval_service: RetrievalService,
        settings: LLMSettings,
        client: OpenAIChatClient,
        context_composer: ContextComposer,
        prompt_builder: PromptBuilder,
        response_validator: ResponseValidator,
        token_counter: TokenCounter,
        cost_tracker: CostTracker,
        stream_manager: StreamManager,
    ) -> None:
        self.chat_service = chat_service
        self.repository: ChatRepository = chat_service.repository
        self.retrieval_service = retrieval_service
        self.settings = settings
        self.client = client
        self.context_composer = context_composer
        self.prompt_builder = prompt_builder
        self.response_validator = response_validator
        self.token_counter = token_counter
        self.cost_tracker = cost_tracker
        self.stream_manager = stream_manager

    async def generate(self, *, request: LLMGenerationRequest, user: User) -> ChatCompletionResponse:
        started = perf_counter()
        conversation, recent_messages = await self._resolve_conversation(
            user=user,
            conversation_id=request.conversation_id,
            title=request.title,
            conversation_metadata=request.conversation_metadata,
            question=request.question,
        )
        set_conversation_id(str(conversation.id))
        user_message = await self.repository.create_message(
            conversation_id=conversation.id,
            user_id=user.id,
            role=MessageSender.USER,
            content=request.question,
            markdown=False,
            token_count=self.token_counter.count_text(request.question),
            metadata=request.message_metadata,
        )
        response = await self._generate_assistant_message(
            user=user,
            conversation=conversation,
            recent_messages=recent_messages,
            question=request.question,
            request=request,
            metadata_extra={"source_user_message_id": str(user_message.id)},
        )
        logger.info(
            "llm_generation_completed",
            extra={
                "details": {
                    "conversation_id": str(conversation.id),
                    "model_key": response.model_key,
                    "total_tokens": response.usage.total_tokens,
                    "total_cost": response.cost.total_cost,
                    "latency_ms": round((perf_counter() - started) * 1000, 2),
                }
            },
        )
        return response

    async def regenerate(self, *, request: LLMRegenerateRequest, user: User) -> ChatCompletionResponse:
        conversation = await self.chat_service.get_conversation(
            conversation_id=request.conversation_id,
            user_id=user.id,
            include_messages=True,
        )
        set_conversation_id(str(conversation.id))
        messages = list(conversation.messages)
        if not messages:
            raise NotFoundError("Conversation has no messages to regenerate.")

        target_user_message, recent_messages = self._resolve_regeneration_target(
            messages=messages,
            target_message_id=request.target_message_id,
        )
        generate_request = LLMGenerationRequest(
            question=target_user_message.content,
            conversation_id=conversation.id,
            profile=request.profile,
            model=request.model,
            temperature=request.temperature,
            top_p=request.top_p,
            max_tokens=request.max_tokens,
            frequency_penalty=request.frequency_penalty,
            presence_penalty=request.presence_penalty,
            filters=RetrievalFiltersInput.model_validate(
                (conversation.metadata_ or {}).get("retrieval_filters", {})
            ),
        )
        return await self._generate_assistant_message(
            user=user,
            conversation=conversation,
            recent_messages=recent_messages,
            question=target_user_message.content,
            request=generate_request,
            metadata_extra={
                "regenerated_from_message_id": str(request.target_message_id or target_user_message.id),
                "source_user_message_id": str(target_user_message.id),
            },
        )

    async def stream(self, *, request: LLMGenerationRequest, user: User) -> StreamingResponse:
        if not self.settings.llm_streaming_enabled:
            raise NotFoundError("Streaming is disabled.")
        conversation, recent_messages = await self._resolve_conversation(
            user=user,
            conversation_id=request.conversation_id,
            title=request.title,
            conversation_metadata=request.conversation_metadata,
            question=request.question,
        )
        set_conversation_id(str(conversation.id))
        user_message = await self.repository.create_message(
            conversation_id=conversation.id,
            user_id=user.id,
            role=MessageSender.USER,
            content=request.question,
            markdown=False,
            token_count=self.token_counter.count_text(request.question),
            metadata=request.message_metadata,
        )
        await self.repository.session.commit()
        stream_handle = self.stream_manager.create(user_id=user.id, conversation_id=conversation.id)
        conversation_id = str(conversation.id)
        user_message_id = str(user_message.id)
        payload = await self._prepare_generation_payload(
            conversation=conversation,
            recent_messages=recent_messages,
            question=request.question,
            request=request,
        )

        async def event_stream():
            accumulated = []
            started = perf_counter()
            try:
                yield sse_event(
                    "start",
                    {
                        "stream_id": stream_handle.stream_id,
                        "conversation_id": conversation_id,
                        "message_id": user_message_id,
                        "model_key": payload["model_key"],
                        "model_name": payload["model_name"],
                    },
                )
                async for chunk in self.client.stream_generate(
                    messages=payload["prompt_messages"],
                    options=payload["generation_options"],
                    cancel_event=stream_handle.cancel_event,
                ):
                    if stream_handle.cancel_event.is_set():
                        yield sse_event(
                            "cancelled",
                            {
                                "stream_id": stream_handle.stream_id,
                                "conversation_id": conversation_id,
                            },
                        )
                        break
                    if chunk.delta:
                        accumulated.append(chunk.delta)
                        yield sse_event("token", {"stream_id": stream_handle.stream_id, "delta": chunk.delta})
                    if chunk.is_final and not stream_handle.cancel_event.is_set():
                        response = await self._persist_generation_result(
                            conversation=conversation,
                            question=request.question,
                            prompt_messages=payload["prompt_messages"],
                            context_package=payload["context_package"],
                            result_content="".join(accumulated),
                            response_id=chunk.response_id,
                            finish_reason=chunk.finish_reason,
                            usage=chunk.usage,
                            request=request,
                            profile=payload["profile"],
                            latency_ms=round((perf_counter() - started) * 1000, 2),
                            metadata_extra={"source_user_message_id": user_message_id, "stream_id": stream_handle.stream_id},
                        )
                        await self.repository.session.commit()
                        yield sse_event(
                            "complete",
                            {
                                "stream_id": stream_handle.stream_id,
                                "conversation_id": conversation_id,
                                "assistant_message_id": str(response.message.id),
                                "usage": response.usage.model_dump(),
                                "cost": response.cost.model_dump(),
                                "citations": [citation.model_dump() for citation in response.citations],
                            },
                        )
            except Exception as exc:
                await self.repository.session.rollback()
                logger.exception("llm_stream_failed")
                yield sse_event(
                    "error",
                    {
                        "stream_id": stream_handle.stream_id,
                        "conversation_id": conversation_id,
                        "message": str(exc),
                    },
                )
            finally:
                self.stream_manager.complete(stream_handle.stream_id)

        return StreamingResponse(event_stream(), media_type="text/event-stream")

    def stop(self, *, stream_id: str, user: User) -> bool:
        return self.stream_manager.cancel(stream_id=stream_id, user_id=user.id)

    def models(self) -> ChatModelsResponse:
        items = [
            ChatModelRead(
                key=model.key,
                provider=model.provider,
                model_name=model.model_name,
                active=model.key == self.settings.active_model.key,
                supports_streaming=model.supports_streaming,
                input_token_price_per_million=model.input_token_price_per_million,
                output_token_price_per_million=model.output_token_price_per_million,
                max_context_tokens=model.max_context_tokens,
                max_output_tokens=model.max_output_tokens,
            )
            for model in self.settings.model_catalog
        ]
        return ChatModelsResponse(items=items, active_model_key=self.settings.active_model.key)

    async def statistics(self, *, user: User) -> ChatStatisticsResponse:
        messages = await self.repository.list_llm_messages(user_id=user.id)
        conversation_totals: dict[UUID, dict] = {}
        model_totals: dict[str, dict] = defaultdict(
            lambda: {
                "message_count": 0,
                "total_prompt_tokens": 0,
                "total_completion_tokens": 0,
                "total_tokens": 0,
                "total_cost": 0.0,
            }
        )
        daily_cost: dict[str, dict] = defaultdict(lambda: {"message_count": 0, "total_cost": 0.0})
        monthly_cost: dict[str, dict] = defaultdict(lambda: {"message_count": 0, "total_cost": 0.0})

        total_prompt_tokens = 0
        total_completion_tokens = 0
        total_tokens = 0
        total_cost = 0.0

        for message in messages:
            llm_meta = (message.metadata_ or {}).get("llm")
            if not llm_meta:
                continue
            conversation = message.conversation
            conversation_bucket = conversation_totals.setdefault(
                conversation.id,
                {
                    "title": conversation.title,
                    "message_count": 0,
                    "total_prompt_tokens": 0,
                    "total_completion_tokens": 0,
                    "total_tokens": 0,
                    "total_cost": 0.0,
                    "last_message_at": message.created_at,
                },
            )
            prompt_tokens = int(llm_meta.get("prompt_tokens", 0))
            completion_tokens = int(llm_meta.get("completion_tokens", 0))
            message_tokens = int(llm_meta.get("total_tokens", 0))
            message_cost = float(llm_meta.get("total_cost", 0.0))
            model_key = llm_meta.get("model_key", "unknown")

            conversation_bucket["message_count"] += 1
            conversation_bucket["total_prompt_tokens"] += prompt_tokens
            conversation_bucket["total_completion_tokens"] += completion_tokens
            conversation_bucket["total_tokens"] += message_tokens
            conversation_bucket["total_cost"] += message_cost
            conversation_bucket["last_message_at"] = max(
                conversation_bucket["last_message_at"],
                message.created_at,
            )

            model_totals[model_key]["message_count"] += 1
            model_totals[model_key]["total_prompt_tokens"] += prompt_tokens
            model_totals[model_key]["total_completion_tokens"] += completion_tokens
            model_totals[model_key]["total_tokens"] += message_tokens
            model_totals[model_key]["total_cost"] += message_cost

            day_key = message.created_at.astimezone(UTC).date().isoformat()
            month_key = message.created_at.astimezone(UTC).strftime("%Y-%m")
            daily_cost[day_key]["message_count"] += 1
            daily_cost[day_key]["total_cost"] += message_cost
            monthly_cost[month_key]["message_count"] += 1
            monthly_cost[month_key]["total_cost"] += message_cost

            total_prompt_tokens += prompt_tokens
            total_completion_tokens += completion_tokens
            total_tokens += message_tokens
            total_cost += message_cost

        return ChatStatisticsResponse(
            total_messages=sum(item["message_count"] for item in conversation_totals.values()),
            total_conversations=len(conversation_totals),
            total_prompt_tokens=total_prompt_tokens,
            total_completion_tokens=total_completion_tokens,
            total_tokens=total_tokens,
            total_cost=round(total_cost, 8),
            conversations=[
                ConversationCostRead(
                    conversation_id=conversation_id,
                    title=data["title"],
                    message_count=data["message_count"],
                    total_prompt_tokens=data["total_prompt_tokens"],
                    total_completion_tokens=data["total_completion_tokens"],
                    total_tokens=data["total_tokens"],
                    total_cost=round(data["total_cost"], 8),
                    last_message_at=data["last_message_at"],
                )
                for conversation_id, data in sorted(
                    conversation_totals.items(),
                    key=lambda item: item[1]["last_message_at"],
                    reverse=True,
                )
            ],
            model_usage=[
                ModelUsageRead(
                    model_key=model_key,
                    message_count=data["message_count"],
                    total_prompt_tokens=data["total_prompt_tokens"],
                    total_completion_tokens=data["total_completion_tokens"],
                    total_tokens=data["total_tokens"],
                    total_cost=round(data["total_cost"], 8),
                )
                for model_key, data in sorted(model_totals.items())
            ],
            daily_cost=[
                PeriodCostRead(period=period, message_count=data["message_count"], total_cost=round(data["total_cost"], 8))
                for period, data in sorted(daily_cost.items(), reverse=True)
            ],
            monthly_cost=[
                PeriodCostRead(period=period, message_count=data["message_count"], total_cost=round(data["total_cost"], 8))
                for period, data in sorted(monthly_cost.items(), reverse=True)
            ],
        )

    async def _resolve_conversation(
        self,
        *,
        user: User,
        conversation_id: UUID | None,
        title: str | None,
        conversation_metadata: dict,
        question: str,
    ):
        if conversation_id is not None:
            conversation = await self.chat_service.get_conversation(
                conversation_id=conversation_id,
                user_id=user.id,
                include_messages=False,
            )
            recent_messages = await self.repository.list_recent_messages(
                conversation_id=conversation.id,
                user_id=user.id,
                limit=self.settings.llm_max_recent_messages,
            )
            return conversation, recent_messages

        conversation = await self.repository.create_conversation(
            user_id=user.id,
            title=title or self.chat_service._derive_title(question),
            metadata=conversation_metadata,
        )
        return conversation, []

    async def _generate_assistant_message(
        self,
        *,
        user: User,
        conversation,
        recent_messages,
        question: str,
        request: LLMGenerationRequest,
        metadata_extra: dict,
    ) -> ChatCompletionResponse:
        payload = await self._prepare_generation_payload(
            conversation=conversation,
            recent_messages=recent_messages,
            question=question,
            request=request,
        )
        started = perf_counter()
        result = await self.client.generate(
            messages=payload["prompt_messages"],
            options=payload["generation_options"],
        )
        return await self._persist_generation_result(
            conversation=conversation,
            question=question,
            prompt_messages=payload["prompt_messages"],
            context_package=payload["context_package"],
            result_content=result.content,
            response_id=result.response_id,
            finish_reason=result.finish_reason,
            usage=result.usage,
            request=request,
            profile=payload["profile"],
            latency_ms=round((perf_counter() - started) * 1000, 2),
            metadata_extra=metadata_extra,
        )

    async def _prepare_generation_payload(
        self,
        *,
        conversation,
        recent_messages,
        question: str,
        request: LLMGenerationRequest,
    ) -> dict:
        filters = self._build_filters(request)
        conversation.metadata_ = {
            **(conversation.metadata_ or {}),
            "retrieval_filters": self._json_safe(request.filters.model_dump(exclude_none=True)),
        }
        retrieval_payload = await self.retrieval_service.retrieve(
            query=question,
            filters=filters,
            top_k=request.top_k,
        )
        context_package = self.context_composer.compose(
            query=question,
            retrieved_items=retrieval_payload["items"],
        )
        understanding = retrieval_payload["understanding"]
        profile = self.prompt_builder.infer_profile(
            explicit_profile=request.profile,
            audience=understanding.get("audience"),
            age_group=understanding.get("age_group"),
            gender=understanding.get("gender"),
        )
        prompt_messages = self.prompt_builder.build(
            profile=profile,
            question=question,
            conversation_summary=conversation.summary,
            recent_messages=recent_messages,
            context_package=context_package,
        )
        model_spec = next(
            (
                item
                for item in self.settings.model_catalog
                if item.key == (request.model or self.settings.active_model.key)
            ),
            self.settings.active_model,
        )
        generation_options = GenerationOptions(
            model_name=model_spec.model_name,
            temperature=request.temperature if request.temperature is not None else self.settings.llm_temperature,
            top_p=request.top_p if request.top_p is not None else self.settings.llm_top_p,
            max_tokens=min(
                request.max_tokens if request.max_tokens is not None else self.settings.llm_max_output_tokens,
                model_spec.max_output_tokens,
            ),
            frequency_penalty=(
                request.frequency_penalty
                if request.frequency_penalty is not None
                else self.settings.llm_frequency_penalty
            ),
            presence_penalty=(
                request.presence_penalty
                if request.presence_penalty is not None
                else self.settings.llm_presence_penalty
            ),
        )
        return {
            "retrieval_payload": retrieval_payload,
            "context_package": context_package,
            "profile": profile,
            "prompt_messages": prompt_messages,
            "generation_options": generation_options,
            "model_key": model_spec.key,
            "model_name": model_spec.model_name,
            "model_spec": model_spec,
        }

    async def _persist_generation_result(
        self,
        *,
        conversation,
        question: str,
        prompt_messages: list[dict[str, str]],
        context_package,
        result_content: str,
        response_id: str | None,
        finish_reason: str | None,
        usage,
        request: LLMGenerationRequest,
        profile: PromptProfile,
        latency_ms: float,
        metadata_extra: dict,
    ) -> ChatCompletionResponse:
        model_spec = next(
            (
                item
                for item in self.settings.model_catalog
                if item.key == (request.model or self.settings.active_model.key)
            ),
            self.settings.active_model,
        )
        validated = self.response_validator.validate(
            content=result_content,
            context_package=context_package,
            require_citations=self.settings.llm_require_citations,
        )
        usage_snapshot = UsageSnapshot(
            prompt_tokens=usage.prompt_tokens,
            completion_tokens=usage.completion_tokens,
            total_tokens=usage.total_tokens,
        )
        cost = self.cost_tracker.estimate(usage=usage_snapshot, model=model_spec)
        citations = self._json_safe(validated.citations)
        metadata = {
            "llm": {
                "request_id": get_request_id(),
                "model_key": model_spec.key,
                "model_name": model_spec.model_name,
                "profile": profile.value,
                "prompt": self._json_safe(prompt_messages),
                "question": question,
                "temperature": request.temperature if request.temperature is not None else self.settings.llm_temperature,
                "top_p": request.top_p if request.top_p is not None else self.settings.llm_top_p,
                "max_tokens": request.max_tokens if request.max_tokens is not None else self.settings.llm_max_output_tokens,
                "frequency_penalty": (
                    request.frequency_penalty
                    if request.frequency_penalty is not None
                    else self.settings.llm_frequency_penalty
                ),
                "presence_penalty": (
                    request.presence_penalty
                    if request.presence_penalty is not None
                    else self.settings.llm_presence_penalty
                ),
                "retrieved_context_ids": context_package.context_ids,
                "retrieval_count": len(context_package.entries),
                "prompt_tokens": usage_snapshot.prompt_tokens,
                "completion_tokens": usage_snapshot.completion_tokens,
                "total_tokens": usage_snapshot.total_tokens,
                "prompt_cost": cost.prompt_cost,
                "completion_cost": cost.completion_cost,
                "total_cost": cost.total_cost,
                "latency_ms": latency_ms,
                "finish_reason": finish_reason,
                "validation": self._json_safe([asdict(issue) for issue in validated.issues]),
                "generated_at": datetime.now(UTC).isoformat(),
                **metadata_extra,
            }
        }
        message = await self.repository.create_message(
            conversation_id=conversation.id,
            user_id=None,
            role=MessageSender.ASSISTANT,
            content=validated.content,
            markdown=validated.markdown,
            token_count=usage_snapshot.completion_tokens,
            latency=int(latency_ms),
            citations=citations,
            metadata=self._json_safe(metadata),
            llm_response_id=response_id,
        )
        conversation_read = ConversationRead.model_validate(conversation)
        message_read = MessageRead.model_validate(message)
        return ChatCompletionResponse(
            conversation=conversation_read,
            message=message_read,
            model_key=model_spec.key,
            model_name=model_spec.model_name,
            latency_ms=latency_ms,
            retrieval_count=len(context_package.entries),
            usage=TokenUsageRead(
                prompt_tokens=usage_snapshot.prompt_tokens,
                completion_tokens=usage_snapshot.completion_tokens,
                total_tokens=usage_snapshot.total_tokens,
            ),
            cost=CostBreakdownRead(
                prompt_cost=cost.prompt_cost,
                completion_cost=cost.completion_cost,
                total_cost=cost.total_cost,
                currency=cost.currency,
            ),
            citations=[CitationRead.model_validate(item) for item in citations],
            validation=ResponseValidationRead(
                sufficient_evidence=validated.sufficient_evidence,
                issues=[ValidationIssueRead.model_validate(asdict(item)) for item in validated.issues],
            ),
        )

    def _resolve_regeneration_target(self, *, messages, target_message_id: UUID | None):
        target_index = len(messages) - 1
        if target_message_id is not None:
            for index, message in enumerate(messages):
                if message.id == target_message_id:
                    target_index = index
                    break
            else:
                raise NotFoundError("Target message for regeneration was not found.")

        for index in range(target_index, -1, -1):
            if messages[index].role == MessageSender.USER:
                recent_start = max(0, index - self.settings.llm_max_recent_messages)
                recent_messages = messages[recent_start:index]
                return messages[index], recent_messages
        raise NotFoundError("No user message found for regeneration.")

    def _build_filters(self, request: LLMGenerationRequest) -> RetrievalFilters:
        return RetrievalFilters(
            topic=request.filters.topic,
            subtopic=request.filters.subtopic,
            age_group=request.filters.age_group,
            audience=request.filters.audience,
            gender=request.filters.gender,
            organisation=request.filters.organisation,
            priority=request.filters.priority,
            evidence_level=request.filters.evidence_level,
            language=request.filters.language,
            publication_date_from=request.filters.publication_date_from,
            publication_date_to=request.filters.publication_date_to,
            country=request.filters.country,
            keywords=request.filters.keywords,
        )

    def _json_safe(self, value):
        if isinstance(value, dict):
            return {str(key): self._json_safe(item) for key, item in value.items()}
        if isinstance(value, list):
            return [self._json_safe(item) for item in value]
        if isinstance(value, tuple):
            return [self._json_safe(item) for item in value]
        if isinstance(value, (datetime, date)):
            return value.isoformat()
        if isinstance(value, UUID):
            return str(value)
        return value
