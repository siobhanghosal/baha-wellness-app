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

    async def search(self, query: str, *, top_k: int, filters: dict[str, str]) -> list[SearchResult]:
        return self._results


def _sample_result(*, confidence: float = 0.78) -> SearchResult:
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
        dense_score=0.71,
        lexical_score=0.65,
        confidence=confidence,
    )


def test_buddy_chat_service_uses_ollama_when_grounded_output_is_valid() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(
                200,
                json={
                    "message": {
                        "role": "assistant",
                        "content": json.dumps(
                            {
                                "answerable_from_corpus": True,
                                "what_it_is": "The retrieved BAHA material describes exam stress as pressure that can build up around workload, sleep, and expectations.",
                                "how_to_identify_it": "The same material points to overwhelmed feelings, sleep disruption, and trouble staying steady with school routines.",
                                "what_to_do": "It suggests smaller study blocks, sleep support, and reaching out to a trusted adult when the pressure keeps building.",
                                "when_to_seek_help": "Seek extra support when stress keeps getting worse, starts affecting daily life, or feels too heavy to manage alone.",
                            }
                        ),
                    }
                },
            )
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="http://ollama.local",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="ollama",
                    buddy_ollama_base_url="http://ollama.local",
                    buddy_min_retrieval_confidence=0.45,
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="I feel stressed about exams and can't focus.",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([_sample_result()]),
                history=[{"role": "user", "content": "I feel behind in school."}],
            )

        assert result.backend_used == "ollama"
        assert result.response.answer.what_to_do.startswith("It suggests")
        assert result.response.answer.confidence > 0
        assert result.response.retrieved

    asyncio.run(run())


def test_buddy_chat_service_returns_scope_guard_for_low_confidence_retrieval() -> None:
    async def run() -> None:
        service = BuddyChatService(
            Settings(
                buddy_generation_backend="ollama",
                buddy_min_retrieval_confidence=0.9,
            ),
        )
        result = await service.generate(
            request=ChatRequest(
                message="Tell me about a random celebrity scandal.",
                audience="adolescent",
            ),
            retriever=_FakeRetriever([_sample_result(confidence=0.32)]),
            history=[],
        )

        assert result.backend_used == "scope_guard"
        assert result.fallback_reason == "low_retrieval_confidence"
        assert "only answer using the approved BAHA material" in result.response.answer.what_it_is
        assert result.response.answer.confidence == 0.0

    asyncio.run(run())


def test_buddy_chat_service_falls_back_to_composer_when_ollama_fails() -> None:
    async def run() -> None:
        transport = httpx.MockTransport(
            lambda request: httpx.Response(503, json={"error": "model unavailable"})
        )
        async with httpx.AsyncClient(
            transport=transport,
            base_url="http://ollama.local",
        ) as client:
            service = BuddyChatService(
                Settings(
                    buddy_generation_backend="ollama",
                    buddy_ollama_base_url="http://ollama.local",
                    buddy_min_retrieval_confidence=0.45,
                ),
                http_client=client,
            )
            result = await service.generate(
                request=ChatRequest(
                    message="How can I manage exam stress better?",
                    audience="adolescent",
                ),
                retriever=_FakeRetriever([_sample_result()]),
                history=[],
            )

        assert result.backend_used == "composer"
        assert result.fallback_reason is not None
        assert "support" in result.response.answer.what_to_do.lower()
        assert result.response.retrieved

    asyncio.run(run())
