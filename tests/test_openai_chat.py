from __future__ import annotations

from uuid import uuid4

import httpx

from baha_rag.config import Settings
from baha_rag.generation.openai_chat import OpenAIChatService
from baha_rag.schemas import ChatMessage, ChunkMetadata, Citation, SearchResult


def make_result(text: str) -> SearchResult:
    return SearchResult(
        chunk_id=uuid4(),
        document_id=uuid4(),
        text=text,
        metadata=ChunkMetadata(
            source="who.int",
            organization="WHO",
            topic="stress",
            condition="stress",
        ),
        citations=[
            Citation(
                title="WHO adolescent stress guide",
                organization="WHO",
                url="https://www.who.int/example",
            )
        ],
        dense_score=0.82,
        lexical_score=0.73,
        confidence=0.91,
    )


async def test_openai_chat_service_sends_grounded_prompt() -> None:
    captured: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["path"] = request.url.path
        captured["authorization"] = request.headers.get("Authorization")
        captured["payload"] = request.read().decode("utf-8")
        return httpx.Response(
            200,
            json={
                "model": "gpt-5.4-nano",
                "output": [
                    {
                        "type": "message",
                        "content": [
                            {
                                "type": "output_text",
                                "text": "Parents can reduce stress by listening calmly and helping plan routines [1].",
                            }
                        ],
                    }
                ],
            },
        )

    settings = Settings(openai_api_key="test-key", openai_chat_model="gpt-5.4-nano")
    async with httpx.AsyncClient(
        transport=httpx.MockTransport(handler),
        base_url="https://api.openai.com/v1",
    ) as client:
        answer = await OpenAIChatService(settings, client=client).generate(
            query="How can a parent help with exam stress?",
            perspective="parent",
            condition="stress",
            evidence=[make_result("Supportive family routines can reduce adolescent stress during exams.")],
            history=[ChatMessage(role="user", content="My child is anxious about tests.")],
        )

    assert captured["path"] == "/v1/responses"
    assert captured["authorization"] == "Bearer test-key"
    payload = str(captured["payload"])
    assert "Approved evidence excerpts" in payload
    assert "My child is anxious about tests." in payload
    assert "Supportive family routines can reduce adolescent stress during exams." in payload
    assert answer.model == "gpt-5.4-nano"
    assert answer.citations[0].title == "WHO adolescent stress guide"
    assert "listening calmly" in answer.message


async def test_openai_chat_service_returns_fallback_without_evidence() -> None:
    settings = Settings(openai_api_key="test-key", openai_chat_model="gpt-5.4-nano")
    answer = await OpenAIChatService(settings).generate(
        query="What should I do?",
        perspective="adolescent",
        condition="General Wellbeing",
        evidence=[],
        history=[],
    )

    assert answer.citations == []
    assert answer.confidence == 0.0
    assert "could not find approved evidence" in answer.message
