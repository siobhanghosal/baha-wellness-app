from __future__ import annotations

import asyncio
import sys
from datetime import date
from types import SimpleNamespace
from uuid import UUID, uuid4

import pytest

from baha_companion.api.dependencies import get_llm_client, get_retrieval_service
from baha_companion.chat.models import MessageSender
from baha_companion.chat.repository import ChatRepository
from baha_companion.chat.service import ChatService
from baha_companion.llm.client import (
    GenerationOptions,
    GenerationResult,
    LLMProviderAuthenticationError,
    LLMProviderError,
    LLMProviderRateLimitError,
    OpenAIChatClient,
    StreamChunk,
    UsageInfo,
)
from baha_companion.llm.config import LLMSettings
from baha_companion.llm.context_composer import ContextComposer
from baha_companion.llm.cost_tracker import CostTracker, UsageSnapshot
from baha_companion.llm.prompt_builder import PromptBuilder, PromptProfile
from baha_companion.llm.response_validator import ResponseValidator
from baha_companion.llm.service import LLMService
from baha_companion.llm.streaming import get_stream_manager
from baha_companion.llm.token_counter import TokenCounter
from baha_companion.common.exceptions import NotFoundError
from baha_companion.users.repository import UserRepository


def sample_retrieval_item(*, title: str = "Exam Stress Support", knowledge_object_id: str | None = None, score: float = 0.93):
    return {
        "knowledge_object_id": knowledge_object_id or str(uuid4()),
        "title": title,
        "summary": "Students benefit from breathing routines, journaling, and consistent sleep support.",
        "body": (
            "Guidance suggests using short breathing exercises, study breaks, journaling, and support from "
            "trusted adults during exam periods."
        ),
        "topic": "stress",
        "subtopic": "exam stress",
        "audience": "student",
        "age_group": "13-16",
        "organisation": "NIMHANS",
        "priority": "priority_1",
        "evidence_level": "guideline",
        "publication_date": date(2025, 1, 10),
        "country": "India",
        "language": "English",
        "final_score": score,
        "similarity_score": score,
        "metadata_score": 0.8,
        "bm25_score": 0.7,
        "vector_score": 0.85,
        "priority_score": 1.0,
        "reranker_score": 0.6,
        "recency_bonus": 0.2,
        "evidence_bonus": 0.8,
    }


class FakeRetrievalService:
    async def retrieve(self, *, query: str, filters, top_k: int | None = None, debug: bool = False):
        return {
            "query": query,
            "understanding": {
                "topic": filters.topic or "stress",
                "subtopic": filters.subtopic or "exam stress",
                "audience": filters.audience or "student",
                "age_group": filters.age_group or "13-16",
                "gender": filters.gender or "female",
                "organisation": filters.organisation or "NIMHANS",
                "country": filters.country or "India",
                "evidence_level": filters.evidence_level or "guideline",
                "language": filters.language or "English",
                "keywords": ["exams", "stress"],
                "intent": "support",
            },
            "filters": {},
            "items": [sample_retrieval_item()],
            "top_k": top_k or 5,
        }


class FakeLLMClient:
    def __init__(self, *, content: str = "Try a short breathing reset before study blocks [S1].", stream_chunks=None):
        self.content = content
        self.stream_chunks = stream_chunks or ["Try ", "a short ", "breathing reset [S1]."]

    async def generate(self, *, messages, options: GenerationOptions):
        return GenerationResult(
            content=self.content,
            model_name=options.model_name,
            response_id="resp_fake_123",
            finish_reason="stop",
            usage=UsageInfo(prompt_tokens=120, completion_tokens=24, total_tokens=144),
        )

    async def stream_generate(self, *, messages, options: GenerationOptions, cancel_event=None):
        for delta in self.stream_chunks:
            if cancel_event and cancel_event.is_set():
                break
            yield StreamChunk(delta=delta, response_id="stream_resp_1", model_name=options.model_name)
        yield StreamChunk(
            delta="",
            response_id="stream_resp_1",
            model_name=options.model_name,
            finish_reason="stop",
            usage=UsageInfo(prompt_tokens=90, completion_tokens=18, total_tokens=108),
            is_final=True,
        )


class CancellingFakeLLMClient(FakeLLMClient):
    async def stream_generate(self, *, messages, options: GenerationOptions, cancel_event=None):
        if cancel_event is not None:
            cancel_event.set()
        yield StreamChunk(delta="partial", response_id="stream_resp_cancel", model_name=options.model_name)
        yield StreamChunk(
            delta="",
            response_id="stream_resp_cancel",
            model_name=options.model_name,
            finish_reason="stop",
            usage=UsageInfo(prompt_tokens=10, completion_tokens=3, total_tokens=13),
            is_final=True,
        )


def build_service(db_session, *, settings: LLMSettings | None = None, llm_client=None, retrieval_service=None):
    settings = settings or LLMSettings()
    token_counter = TokenCounter()
    return LLMService(
        chat_service=ChatService(ChatRepository(db_session)),
        retrieval_service=retrieval_service or FakeRetrievalService(),
        settings=settings,
        client=llm_client or FakeLLMClient(),
        context_composer=ContextComposer(settings=settings, token_counter=token_counter),
        prompt_builder=PromptBuilder(),
        response_validator=ResponseValidator(),
        token_counter=token_counter,
        cost_tracker=CostTracker(),
        stream_manager=get_stream_manager(),
    )


def test_context_composer_deduplicates_and_limits():
    settings = LLMSettings(llm_max_context_tokens=300, llm_context_candidate_limit=5)
    composer = ContextComposer(settings=settings, token_counter=TokenCounter())
    shared_id = str(uuid4())
    package = composer.compose(
        query="exam stress help",
        retrieved_items=[
            sample_retrieval_item(knowledge_object_id=shared_id, score=0.99),
            sample_retrieval_item(knowledge_object_id=shared_id, score=0.50),
            sample_retrieval_item(title="Second Source", score=0.88),
        ],
    )
    assert len(package.entries) >= 1
    assert len({entry.knowledge_object_id for entry in package.entries}) == len(package.entries)
    assert package.total_tokens <= settings.llm_max_context_tokens


def test_prompt_builder_uses_profile_and_recent_messages():
    builder = PromptBuilder()
    profile = builder.infer_profile(
        explicit_profile=None,
        audience="student",
        age_group="13-16",
        gender="female",
    )
    assert profile == PromptProfile.AGE_13_16_FEMALE

    context_package = ContextComposer(LLMSettings()).compose(
        query="exam stress help",
        retrieved_items=[sample_retrieval_item()],
    )
    recent_message = SimpleNamespace(role=MessageSender.USER, content="I'm worried about exams.")
    messages = builder.build(
        profile=profile,
        question="What should I do?",
        conversation_summary="Conversation about school pressure.",
        recent_messages=[recent_message],
        context_package=context_package,
    )
    assert messages[0]["role"] == "system"
    assert "girls ages 13-16" in messages[0]["content"]
    assert messages[1]["content"] == "I'm worried about exams."
    assert "[S1]" in messages[-1]["content"]


def test_response_validator_adds_citations_and_handles_weak_evidence():
    validator = ResponseValidator()
    weak_settings = LLMSettings(llm_max_context_tokens=300)
    weak_composer = ContextComposer(weak_settings)
    weak_item = sample_retrieval_item(score=0.05)
    weak_item["priority"] = "priority_4"
    weak_item["evidence_level"] = "expert opinion"
    context = weak_composer.compose(
        query="support",
        retrieved_items=[weak_item],
    )
    validated = validator.validate(
        content="Take a short break and talk to a trusted adult.",
        context_package=context,
        require_citations=True,
    )
    assert validated.citations
    assert any(issue.code == "missing_citations" for issue in validated.issues)
    assert any(issue.code == "insufficient_evidence" for issue in validated.issues)
    assert "don't have enough strong evidence" in validated.content.lower()


def test_cost_tracker_estimates_pricing():
    tracker = CostTracker()
    settings = LLMSettings()
    cost = tracker.estimate(
        usage=UsageSnapshot(prompt_tokens=1000, completion_tokens=500, total_tokens=1500),
        model=settings.active_model,
    )
    assert cost.prompt_cost > 0
    assert cost.completion_cost > 0
    assert cost.total_cost == round(cost.prompt_cost + cost.completion_cost, 8)


async def test_openai_client_retries_transient_errors():
    class APITimeoutError(Exception):
        pass

    class FakeCompletions:
        def __init__(self) -> None:
            self.calls = 0

        async def create(self, **kwargs):
            self.calls += 1
            if self.calls == 1:
                raise APITimeoutError("temporary timeout")
            return SimpleNamespace(
                id="resp_retry_ok",
                model=kwargs["model"],
                choices=[SimpleNamespace(message=SimpleNamespace(content="Retry worked [S1]."), finish_reason="stop")],
                usage=SimpleNamespace(prompt_tokens=30, completion_tokens=10, total_tokens=40),
            )

    completions = FakeCompletions()
    sdk = SimpleNamespace(chat=SimpleNamespace(completions=completions))
    client = OpenAIChatClient(
        LLMSettings(llm_max_retries=1, llm_retry_backoff_seconds=0),
        client_factory=lambda: sdk,
    )
    result = await client.generate(
        messages=[{"role": "user", "content": "Help"}],
        options=GenerationOptions(
            model_name="gpt-4o-mini",
            temperature=0.2,
            top_p=0.9,
            max_tokens=200,
            frequency_penalty=0.0,
            presence_penalty=0.0,
        ),
    )
    assert completions.calls == 2
    assert result.content == "Retry worked [S1]."


async def test_openai_client_streaming_and_provider_error_paths(monkeypatch):
    class FakeAsyncStream:
        def __init__(self, chunks):
            self._chunks = chunks

        def __aiter__(self):
            self._iterator = iter(self._chunks)
            return self

        async def __anext__(self):
            try:
                return next(self._iterator)
            except StopIteration as exc:
                raise StopAsyncIteration from exc

    class FakeCompletions:
        async def create(self, **kwargs):
            return FakeAsyncStream(
                [
                    SimpleNamespace(
                        id="stream_1",
                        model=kwargs["model"],
                        choices=[SimpleNamespace(delta=SimpleNamespace(content="Hello "), finish_reason=None)],
                        usage=None,
                    ),
                    SimpleNamespace(
                        id="stream_1",
                        model=kwargs["model"],
                        choices=[SimpleNamespace(delta=SimpleNamespace(content="world [S1]."), finish_reason="stop")],
                        usage=SimpleNamespace(prompt_tokens=20, completion_tokens=6, total_tokens=26),
                    ),
                ]
            )

    sdk = SimpleNamespace(chat=SimpleNamespace(completions=FakeCompletions()))
    client = OpenAIChatClient(LLMSettings(), client_factory=lambda: sdk)
    chunks = [
        chunk
        async for chunk in client.stream_generate(
            messages=[{"role": "user", "content": "Hello"}],
            options=GenerationOptions(
                model_name="gpt-4o-mini",
                temperature=0.2,
                top_p=0.9,
                max_tokens=200,
                frequency_penalty=0.0,
                presence_penalty=0.0,
            ),
            cancel_event=asyncio.Event(),
        )
    ]
    assert chunks[0].delta == "Hello "
    assert chunks[-1].is_final is True
    assert chunks[-1].usage.total_tokens == 26

    with pytest.raises(LLMProviderAuthenticationError):
        OpenAIChatClient(LLMSettings())._client()

    class PermissionDeniedError(Exception):
        pass

    class RateLimitError(Exception):
        pass

    auth_client = OpenAIChatClient(LLMSettings(llm_max_retries=0), client_factory=lambda: None)

    async def permission_operation():
        raise PermissionDeniedError("denied")

    with pytest.raises(LLMProviderAuthenticationError):
        await auth_client._call_with_retries(permission_operation)

    async def rate_limit_operation():
        raise RateLimitError("slow down")

    rate_limit_client = OpenAIChatClient(LLMSettings(llm_max_retries=0), client_factory=lambda: None)
    with pytest.raises(LLMProviderRateLimitError):
        await rate_limit_client._call_with_retries(rate_limit_operation)

    async def fatal_operation():
        raise RuntimeError("boom")

    with pytest.raises(LLMProviderError):
        await rate_limit_client._call_with_retries(fatal_operation)

    class FakeAsyncOpenAI:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    monkeypatch.setitem(sys.modules, "openai", SimpleNamespace(AsyncOpenAI=FakeAsyncOpenAI))
    configured_client = OpenAIChatClient(
        LLMSettings(
            openai_api_key="test-key",
            openai_base_url="https://example.invalid",
            openai_organization="org_test",
            openai_project="proj_test",
        )
    )
    sdk_instance = configured_client._client()
    assert sdk_instance.kwargs["base_url"] == "https://example.invalid"
    assert sdk_instance.kwargs["organization"] == "org_test"
    assert sdk_instance.kwargs["project"] == "proj_test"


async def test_llm_service_direct_generate_regenerate_and_statistics(db_session):
    user_repo = UserRepository(db_session)
    user = await user_repo.create(
        email="llm-service@example.com",
        full_name="LLM Service User",
        password_hash="not-used",
    )
    service = build_service(db_session)
    response = await service.generate(
        request=SimpleNamespace(
            question="How can I handle exam stress?",
            conversation_id=None,
            title="Exam support",
            profile=PromptProfile.STUDENT,
            filters=SimpleNamespace(
                topic="stress",
                subtopic=None,
                age_group="13-16",
                audience="student",
                gender="female",
                organisation=None,
                priority=None,
                evidence_level=None,
                language=None,
                publication_date_from=None,
                publication_date_to=None,
                country=None,
                keywords=[],
                model_dump=lambda **kwargs: {"topic": "stress", "audience": "student"},
            ),
            top_k=5,
            conversation_metadata={},
            message_metadata={"source": "unit"},
            model=None,
            temperature=None,
            top_p=None,
            max_tokens=None,
            frequency_penalty=None,
            presence_penalty=None,
        ),
        user=user,
    )
    await db_session.commit()
    assert response.message.role == MessageSender.ASSISTANT

    regenerated = await service.regenerate(
        request=SimpleNamespace(
            conversation_id=response.conversation.id,
            target_message_id=None,
            profile=PromptProfile.STUDENT,
            model=None,
            temperature=None,
            top_p=None,
            max_tokens=None,
            frequency_penalty=None,
            presence_penalty=None,
        ),
        user=user,
    )
    await db_session.commit()
    assert regenerated.conversation.message_count == 3

    stats = await service.statistics(user=user)
    assert stats.total_messages == 2
    assert stats.total_cost > 0
    assert service.models().items[0].active is True


async def test_llm_service_stream_cancellation_and_error_paths(db_session):
    user_repo = UserRepository(db_session)
    user = await user_repo.create(
        email="llm-cancel@example.com",
        full_name="LLM Cancel User",
        password_hash="not-used",
    )

    disabled_service = build_service(db_session, settings=LLMSettings(llm_streaming_enabled=False))
    request = SimpleNamespace(
        question="Need help",
        conversation_id=None,
        title=None,
        profile=None,
        filters=SimpleNamespace(
            topic=None,
            subtopic=None,
            age_group=None,
            audience=None,
            gender=None,
            organisation=None,
            priority=None,
            evidence_level=None,
            language=None,
            publication_date_from=None,
            publication_date_to=None,
            country=None,
            keywords=[],
            model_dump=lambda **kwargs: {},
        ),
        top_k=5,
        conversation_metadata={},
        message_metadata={},
        model=None,
        temperature=None,
        top_p=None,
        max_tokens=None,
        frequency_penalty=None,
        presence_penalty=None,
    )
    with pytest.raises(NotFoundError):
        await disabled_service.stream(request=request, user=user)

    cancelling_service = build_service(db_session, llm_client=CancellingFakeLLMClient())
    response = await cancelling_service.stream(request=request, user=user)
    body = b""
    async for chunk in response.body_iterator:
        body += chunk
    assert b"event: cancelled" in body

    empty_conversation = await ChatRepository(db_session).create_conversation(user_id=user.id, title="Empty", metadata={})
    with pytest.raises(NotFoundError):
        await cancelling_service.regenerate(
            request=SimpleNamespace(
                conversation_id=empty_conversation.id,
                target_message_id=None,
                profile=None,
                model=None,
                temperature=None,
                top_p=None,
                max_tokens=None,
                frequency_penalty=None,
                presence_penalty=None,
            ),
            user=user,
        )

    with pytest.raises(NotFoundError):
        cancelling_service._resolve_regeneration_target(
            messages=[SimpleNamespace(id=uuid4(), role=MessageSender.ASSISTANT, content="Only assistant")],
            target_message_id=uuid4(),
        )


async def test_llm_api_generation_models_statistics_and_regenerate(app, client, registered_user_tokens):
    app.dependency_overrides[get_llm_client] = lambda: FakeLLMClient()
    app.dependency_overrides[get_retrieval_service] = lambda: FakeRetrievalService()
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    create_response = await client.post(
        "/api/v1/chat",
        headers=headers,
        json={
            "question": "What can I do when exams feel overwhelming?",
            "profile": "student",
            "filters": {"topic": "stress", "audience": "student"},
        },
    )
    assert create_response.status_code == 200
    payload = create_response.json()
    assert payload["message"]["role"] == "assistant"
    assert payload["citations"][0]["source_id"] == "S1"
    assert payload["usage"]["total_tokens"] == 144
    assert payload["cost"]["total_cost"] > 0

    conversation_id = payload["conversation"]["id"]
    messages_response = await client.get(
        f"/api/v1/chat/conversations/{conversation_id}/messages?page=1&page_size=10",
        headers=headers,
    )
    assert messages_response.status_code == 200
    assert messages_response.json()["meta"]["total_items"] == 2

    models_response = await client.get("/api/v1/chat/models", headers=headers)
    assert models_response.status_code == 200
    assert models_response.json()["active_model_key"] == "gpt_4o_mini"

    stats_response = await client.get("/api/v1/chat/statistics", headers=headers)
    assert stats_response.status_code == 200
    assert stats_response.json()["total_messages"] == 1
    assert stats_response.json()["model_usage"][0]["model_key"] == "gpt_4o_mini"

    regenerate_response = await client.post(
        "/api/v1/chat/regenerate",
        headers=headers,
        json={"conversation_id": conversation_id},
    )
    assert regenerate_response.status_code == 200
    assert regenerate_response.json()["conversation"]["message_count"] == 3

    app.dependency_overrides.clear()


async def test_llm_streaming_and_stop_endpoint(app, client, registered_user_tokens):
    app.dependency_overrides[get_llm_client] = lambda: FakeLLMClient()
    app.dependency_overrides[get_retrieval_service] = lambda: FakeRetrievalService()
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    async with client.stream(
        "POST",
        "/api/v1/chat/stream",
        headers=headers,
        json={"question": "Share quick exam stress ideas.", "filters": {"topic": "stress"}},
    ) as response:
        assert response.status_code == 200
        assert "text/event-stream" in response.headers["content-type"]
        body = ""
        async for text in response.aiter_text():
            body += text
        assert "event: start" in body
        assert "event: token" in body
        assert "event: complete" in body

    stream_handle = get_stream_manager().create(
        user_id=UUID(registered_user_tokens["user"]["id"]),
        conversation_id=None,
    )
    stop_response = await client.post(
        "/api/v1/chat/stop",
        headers=headers,
        json={"stream_id": stream_handle.stream_id},
    )
    assert stop_response.status_code == 202
    assert stream_handle.cancel_event.is_set()

    app.dependency_overrides.clear()
