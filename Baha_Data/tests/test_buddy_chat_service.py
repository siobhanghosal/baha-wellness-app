import asyncio
import json
from uuid import uuid4

import httpx

from baha_rag.config import Settings
from baha_rag.generation.buddy import BuddyChatService
from baha_rag.schemas import ChatRequest, ChunkMetadata, Citation, SearchResult


class _FakeRetriever:
    def __init__(self, results: list[SearchResult]) -> None:
        self._results = results

    async def search(
        self,
        query: str,
        *,
        top_k: int,
        filters: dict[str, str],
    ) -> list[SearchResult]:
        return self._results


def _sample_result(
    *,
    confidence: float = 0.78,
    dense_score: float = 0.71,
    lexical_score: float = 0.65,
) -> SearchResult:
    return SearchResult(
        chunk_id=uuid4(),
        document_id=uuid4(),
        text=(
            "Students can reduce exam stress by using smaller study blocks, sleep routines, "
            "and support from trusted adults when pressure becomes overwhelming."
        ),
        metadata=ChunkMetadata(
            topic="exam_stress",
            subtopic="study_support",
            audience="adolescent",
            source="BAHA Demo Source",
            organization="BAHA",
        ),
        citations=[
            Citation(
                title="BAHA Student Stress Guide",
                organization="BAHA",
                url="https://example.com/stress-guide",
            )
        ],
        dense_score=dense_score,
        lexical_score=lexical_score,
        confidence=confidence,
    )


def _openai_json_response(
    *,
    what_it_is: str = "That sounds like a lot. We can take it one step at a time.",
    how_to_identify_it: str = "Notice what part feels biggest right now and how it is affecting your day.",
    what_to_do: str = "Try one small next step first, and reach out to a trusted adult if it keeps building.",
    when_to_seek_help: str = "Seek extra help if it starts feeling unsafe or too heavy to manage alone.",
    answerable_from_corpus: bool = True,
) -> dict[str, object]:
    return {
        "model": "gpt-5-nano",
        "output": [
            {
                "type": "message",
                "content": [
                    {
                        "type": "output_text",
                        "text": json.dumps(
                            {
                                "answerable_from_corpus": answerable_from_corpus,
                                "what_it_is": what_it_is,
                                "how_to_identify_it": how_to_identify_it,
                                "what_to_do": what_to_do,
                                "when_to_seek_help": when_to_seek_help,
                            }
                        ),
                    }
                ],
            }
        ],
    }


def test_buddy_chat_service_keeps_emergency_handling_local() -> None:
    async def run() -> None:
        service = BuddyChatService(Settings(buddy_generation_backend="openai"))
        result = await service.generate(
            request=ChatRequest(
                message="I want to hurt myself.",
                audience="adolescent",
            ),
            retriever=_FakeRetriever([]),
            history=[],
        )

        assert result.backend_used == "safety_local"
        assert result.response.answer.condition == "Safety"
        assert "safety matters" in result.response.answer.what_it_is.lower()

    asyncio.run(run())


def test_buddy_chat_service_uses_openai_for_greeting() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(200, json=_openai_json_response())
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(message="hello", audience="adolescent"),
                retriever=_FakeRetriever([]),
                history=[],
            )

        assert result.backend_used == "openai_conversational"
        assert result.response.retrieved == []

    asyncio.run(run())


def test_openai_input_block_adapts_language_for_younger_students() -> None:
    service = BuddyChatService(Settings(buddy_generation_backend="openai"))
    prompt = service._openai_input_block(  # noqa: SLF001 - direct prompt contract check
        request=ChatRequest(
            message="I feel stressed about school.",
            audience="adolescent",
            age_cohort="9_12",
        ),
        condition="Stress",
        evidence=[],
        history=[],
        grounded=False,
    )

    assert "Age cohort: 9_12" in prompt
    assert "Use short sentences, simple words" in prompt


def test_buddy_chat_service_uses_openai_for_supportive_venting() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(
                200,
                json=_openai_json_response(
                    what_it_is="That sounds exhausting. I’m glad you said it out loud.",
                ),
            )
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="I feel really overwhelmed and tired lately",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([]),
                history=[],
            )

        assert result.backend_used == "openai_conversational"
        assert "glad you said it out loud" in result.response.answer.what_it_is.lower()

    asyncio.run(run())


def test_buddy_chat_service_uses_grounded_openai_for_advice_question() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(
                200,
                json=_openai_json_response(
                    what_it_is="The BAHA material describes stress building around exams and expectations.",
                    how_to_identify_it="It points to overwhelm, disrupted sleep, and difficulty focusing.",
                    what_to_do="It suggests smaller study blocks, sleep support, and talking to a trusted adult if the pressure keeps growing.",
                ),
            )
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                    buddy_min_retrieval_confidence=0.45,
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="How do I handle school stress?",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([_sample_result()]),
                history=[],
            )

        assert result.backend_used == "openai_grounded"
        assert result.response.retrieved
        assert "BAHA material" in result.response.answer.what_it_is

    asyncio.run(run())


def test_buddy_chat_service_falls_back_to_conversation_when_retrieval_is_weak() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(200, json=_openai_json_response())
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                    buddy_min_retrieval_confidence=0.9,
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="How do I handle bullying?",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever(
                    [_sample_result(confidence=0.22, dense_score=0.02, lexical_score=0.0)]
                ),
                history=[],
            )

        assert result.backend_used == "openai_conversational"
        assert result.fallback_reason == "low_retrieval_confidence"

    asyncio.run(run())


def test_buddy_chat_service_includes_session_memory_context_in_prompt() -> None:
    async def run() -> None:
        captured_payload: dict[str, object] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_payload
            captured_payload = json.loads(request.content.decode())
            return httpx.Response(200, json=_openai_json_response())

        async with httpx.AsyncClient(
            transport=httpx.MockTransport(handler),
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                ),
                http_client=client,
            )
            await service.generate(
                request=ChatRequest(
                    message="Did I say I was having trouble at school or work?",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([]),
                history=[
                    {"role": "user", "content": "I had trouble at work today."},
                    {"role": "assistant", "content": "That sounds difficult."},
                ],
            )

        input_block = str(captured_payload.get("input") or "")
        assert "Remembered session context" in input_block
        assert "work" in input_block.lower()
        assert "trouble at work" in input_block.lower()

    asyncio.run(run())


def test_buddy_chat_service_raises_when_openai_is_not_configured() -> None:
    async def run() -> None:
        service = BuddyChatService(
            Settings(
                buddy_generation_backend="openai",
                buddy_openai_api_key="",
            ),
        )
        try:
            await service.generate(
                request=ChatRequest(message="hello", audience="adolescent"),
                retriever=_FakeRetriever([]),
                history=[],
            )
        except ValueError as error:
            assert "BUDDY_OPENAI_API_KEY" in str(error)
        else:
            raise AssertionError("Expected missing OpenAI configuration to fail")

    asyncio.run(run())


def test_buddy_chat_service_falls_back_to_conversation_when_grounded_output_is_invalid() -> None:
    async def run() -> None:
        calls = {"count": 0}

        def handler(request: httpx.Request) -> httpx.Response:
            calls["count"] += 1
            if calls["count"] == 1:
                return httpx.Response(
                    200,
                    json={
                        "model": "gpt-5-nano",
                        "output": [
                            {
                                "type": "message",
                                "content": [
                                    {
                                        "type": "output_text",
                                        "text": json.dumps(
                                            {
                                                "answerable_from_corpus": True,
                                                "what_it_is": None,
                                                "how_to_identify_it": None,
                                                "what_to_do": None,
                                                "when_to_seek_help": None,
                                            }
                                        ),
                                    }
                                ],
                            }
                        ],
                    },
                )
            return httpx.Response(200, json=_openai_json_response())

        async with httpx.AsyncClient(
            transport=httpx.MockTransport(handler),
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="How can I improve my sleep?",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([_sample_result()]),
                history=[],
            )

        assert result.backend_used == "openai_conversational"
        assert result.fallback_reason == "invalid_grounded_model_output"
        assert calls["count"] == 2

    asyncio.run(run())


def test_buddy_chat_service_raises_when_openai_request_fails() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(503, json={"error": "model unavailable"})
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="https://api.openai.com/v1",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="openai",
                    buddy_openai_api_key="test-key",
                    buddy_openai_base_url="https://api.openai.com/v1",
                ),
                http_client=client,
            )
            try:
                await service.generate(
                    request=ChatRequest(message="hello", audience="adolescent"),
                    retriever=_FakeRetriever([]),
                    history=[],
                )
            except httpx.HTTPStatusError:
                return
            raise AssertionError("Expected OpenAI request failure to propagate")

    asyncio.run(run())


def test_buddy_stream_parser_does_not_duplicate_done_text() -> None:
    class _FakeStreamResponse:
        async def aiter_lines(self):
            events = [
                'data: {"type":"response.output_text.delta","delta":"Hi"}',
                'data: {"type":"response.output_text.delta","delta":" there"}',
                'data: {"type":"response.output_text.done","text":"Hi there"}',
                'data: [DONE]',
            ]
            for item in events:
                yield item

    async def run() -> None:
        service = BuddyChatService(Settings(buddy_generation_backend="openai"))
        deltas = [
            chunk
            async for chunk in service._iter_openai_stream_text(_FakeStreamResponse())  # type: ignore[arg-type]
        ]
        assert deltas == ["Hi", " there"]

    asyncio.run(run())


def test_buddy_stream_parser_uses_completed_text_as_fallback() -> None:
    class _FakeStreamResponse:
        async def aiter_lines(self):
            events = [
                (
                    'data: {"type":"response.completed","response":{"output":['
                    '{"type":"message","content":[{"type":"output_text","text":"Hello there"}]}]}}'
                ),
                'data: [DONE]',
            ]
            for item in events:
                yield item

    async def run() -> None:
        service = BuddyChatService(Settings(buddy_generation_backend="openai"))
        deltas = [
            chunk
            async for chunk in service._iter_openai_stream_text(_FakeStreamResponse())  # type: ignore[arg-type]
        ]
        assert deltas == ["Hello there"]

    asyncio.run(run())
