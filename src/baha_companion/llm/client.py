from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Any

from baha_companion.common.exceptions import AppError
from baha_companion.llm.config import LLMSettings
from baha_companion.llm.token_counter import TokenCounter


class LLMProviderError(AppError):
    status_code = 502
    code = "llm_provider_error"


class LLMProviderAuthenticationError(AppError):
    status_code = 503
    code = "llm_provider_authentication_error"


class LLMProviderRateLimitError(AppError):
    status_code = 429
    code = "llm_provider_rate_limited"


@dataclass(slots=True)
class GenerationOptions:
    model_name: str
    temperature: float
    top_p: float
    max_tokens: int
    frequency_penalty: float
    presence_penalty: float


@dataclass(slots=True)
class UsageInfo:
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


@dataclass(slots=True)
class GenerationResult:
    content: str
    model_name: str
    response_id: str | None
    finish_reason: str | None
    usage: UsageInfo


@dataclass(slots=True)
class StreamChunk:
    delta: str = ""
    response_id: str | None = None
    model_name: str | None = None
    finish_reason: str | None = None
    usage: UsageInfo | None = None
    is_final: bool = False


class OpenAIChatClient:
    def __init__(
        self,
        settings: LLMSettings,
        *,
        token_counter: TokenCounter | None = None,
        client_factory=None,
    ) -> None:
        self.settings = settings
        self.token_counter = token_counter or TokenCounter()
        self.client_factory = client_factory
        self._sdk_client = None

    async def generate(
        self,
        *,
        messages: list[dict[str, str]],
        options: GenerationOptions,
    ) -> GenerationResult:
        prompt_tokens = self.token_counter.count_messages(messages)

        async def operation() -> Any:
            client = self._client()
            return await client.chat.completions.create(
                model=options.model_name,
                messages=messages,
                temperature=options.temperature,
                top_p=options.top_p,
                max_tokens=options.max_tokens,
                frequency_penalty=options.frequency_penalty,
                presence_penalty=options.presence_penalty,
            )

        response = await self._call_with_retries(operation)
        content = response.choices[0].message.content or ""
        usage = self._usage_from_payload(response, fallback_prompt_tokens=prompt_tokens, content=content)
        return GenerationResult(
            content=content,
            model_name=getattr(response, "model", options.model_name),
            response_id=getattr(response, "id", None),
            finish_reason=getattr(response.choices[0], "finish_reason", None),
            usage=usage,
        )

    async def stream_generate(
        self,
        *,
        messages: list[dict[str, str]],
        options: GenerationOptions,
        cancel_event: asyncio.Event | None = None,
    ):
        prompt_tokens = self.token_counter.count_messages(messages)
        aggregated_parts: list[str] = []
        response_id: str | None = None
        model_name: str | None = None
        final_usage: UsageInfo | None = None

        async def operation() -> Any:
            client = self._client()
            return await client.chat.completions.create(
                model=options.model_name,
                messages=messages,
                temperature=options.temperature,
                top_p=options.top_p,
                max_tokens=options.max_tokens,
                frequency_penalty=options.frequency_penalty,
                presence_penalty=options.presence_penalty,
                stream=True,
                stream_options={"include_usage": True},
            )

        stream = await self._call_with_retries(operation)
        async for chunk in stream:
            if cancel_event and cancel_event.is_set():
                break
            response_id = response_id or getattr(chunk, "id", None)
            model_name = model_name or getattr(chunk, "model", None)
            choice = chunk.choices[0] if getattr(chunk, "choices", None) else None
            delta = getattr(getattr(choice, "delta", None), "content", None) or ""
            if delta:
                aggregated_parts.append(delta)
                yield StreamChunk(delta=delta, response_id=response_id, model_name=model_name, is_final=False)
            usage_payload = getattr(chunk, "usage", None)
            if usage_payload is not None:
                final_usage = self._usage_from_payload(
                    chunk,
                    fallback_prompt_tokens=prompt_tokens,
                    content="".join(aggregated_parts),
                )
            if getattr(choice, "finish_reason", None):
                break

        final_text = "".join(aggregated_parts)
        usage = final_usage or UsageInfo(
            prompt_tokens=prompt_tokens,
            completion_tokens=self.token_counter.count_text(final_text),
            total_tokens=prompt_tokens + self.token_counter.count_text(final_text),
        )
        yield StreamChunk(
            delta="",
            response_id=response_id,
            model_name=model_name or options.model_name,
            finish_reason="stop",
            usage=usage,
            is_final=True,
        )

    async def _call_with_retries(self, operation):
        attempts = self.settings.llm_max_retries + 1
        last_error: Exception | None = None
        for attempt in range(1, attempts + 1):
            try:
                return await operation()
            except Exception as exc:  # pragma: no cover - exercised via tests with fake exception classes
                last_error = exc
                if self._is_authentication_error(exc):
                    raise LLMProviderAuthenticationError("OpenAI API authentication failed.") from exc
                if self._is_rate_limit_error(exc) and attempt >= attempts:
                    raise LLMProviderRateLimitError("The language model provider is temporarily rate limited.") from exc
                if not self._is_retryable_error(exc) or attempt >= attempts:
                    raise LLMProviderError("The language model provider request failed.") from exc
                await asyncio.sleep(self.settings.llm_retry_backoff_seconds * attempt)
        raise LLMProviderError("The language model provider request failed.") from last_error

    def _client(self):
        if self._sdk_client is not None:
            return self._sdk_client
        if self.client_factory is not None:
            self._sdk_client = self.client_factory()
            return self._sdk_client
        if not self.settings.openai_api_key:
            raise LLMProviderAuthenticationError("OPENAI_API_KEY is not configured.")
        try:
            from openai import AsyncOpenAI
        except ImportError as exc:  # pragma: no cover - depends on local environment
            raise LLMProviderError("The OpenAI SDK is not installed. Add the 'openai' package to run chat generation.") from exc

        kwargs: dict[str, Any] = {
            "api_key": self.settings.openai_api_key,
            "timeout": self.settings.llm_timeout_seconds,
            "max_retries": self.settings.llm_max_retries,
        }
        if self.settings.openai_base_url:
            kwargs["base_url"] = self.settings.openai_base_url
        if self.settings.openai_organization:
            kwargs["organization"] = self.settings.openai_organization
        if self.settings.openai_project:
            kwargs["project"] = self.settings.openai_project
        self._sdk_client = AsyncOpenAI(**kwargs)
        return self._sdk_client

    def _usage_from_payload(self, payload: Any, *, fallback_prompt_tokens: int, content: str) -> UsageInfo:
        usage = getattr(payload, "usage", None)
        if usage is None:
            completion_tokens = self.token_counter.count_text(content)
            return UsageInfo(
                prompt_tokens=fallback_prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=fallback_prompt_tokens + completion_tokens,
            )
        prompt_tokens = int(getattr(usage, "prompt_tokens", fallback_prompt_tokens) or fallback_prompt_tokens)
        completion_tokens = int(getattr(usage, "completion_tokens", self.token_counter.count_text(content)) or 0)
        total_tokens = int(getattr(usage, "total_tokens", prompt_tokens + completion_tokens) or 0)
        return UsageInfo(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
        )

    @staticmethod
    def _is_retryable_error(exc: Exception) -> bool:
        name = exc.__class__.__name__.lower()
        return any(token in name for token in ("timeout", "connection", "apierror", "servererror", "ratelimit"))

    @staticmethod
    def _is_authentication_error(exc: Exception) -> bool:
        name = exc.__class__.__name__.lower()
        return "authentication" in name or "permission" in name

    @staticmethod
    def _is_rate_limit_error(exc: Exception) -> bool:
        return "ratelimit" in exc.__class__.__name__.lower()
