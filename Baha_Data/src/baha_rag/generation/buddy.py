from __future__ import annotations

from contextlib import asynccontextmanager
from dataclasses import dataclass
import json
from typing import Any

import httpx
from pydantic import BaseModel, Field

from baha_rag.config import Settings
from baha_rag.generation.composer import EvidenceComposer
from baha_rag.safety import SAFETY_NOTE, assess_safety
from baha_rag.schemas import ChatRequest, ChatResponse, EvidenceAnswer, Perspective, SearchResult
from baha_rag.taxonomy import find_conditions


class BuddyDraftAnswer(BaseModel):
    answerable_from_corpus: bool = True
    what_it_is: str = Field(min_length=8, max_length=1200)
    how_to_identify_it: str = Field(min_length=8, max_length=1200)
    what_to_do: str = Field(min_length=8, max_length=1200)
    when_to_seek_help: str = Field(min_length=8, max_length=1200)


@dataclass(frozen=True)
class BuddyGenerationResult:
    response: ChatResponse
    backend_used: str
    fallback_reason: str | None = None


class BuddyChatService:
    def __init__(
        self,
        settings: Settings,
        *,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self.settings = settings
        self._http_client = http_client

    async def generate(
        self,
        *,
        request: ChatRequest,
        retriever: Any,
        history: list[dict[str, str]] | None = None,
    ) -> BuddyGenerationResult:
        if self.settings.buddy_chat_mode == "generic_demo":
            return BuddyGenerationResult(
                response=ChatResponse(
                    answer=self._generic_demo_answer(
                        query=request.message,
                        perspective=request.audience,
                    ),
                    retrieved=[],
                ),
                backend_used="generic_demo",
            )

        results = await retriever.search(
            request.message,
            top_k=request.top_k,
            filters=request.filters,
        )
        condition = next(iter(find_conditions(request.message)), "General Wellbeing")
        composer = EvidenceComposer()
        fallback_answer = composer.compose(
            condition=condition,
            perspective=request.audience,
            query=request.message,
            evidence=results,
        )

        if not results:
            return BuddyGenerationResult(
                response=ChatResponse(
                    answer=self._out_of_scope_answer(
                        condition=condition,
                        perspective=request.audience,
                        query=request.message,
                        emergency=False,
                    ),
                    retrieved=[],
                ),
                backend_used="scope_guard",
                fallback_reason="no_retrieval_results",
            )

        if (
            results[0].confidence < self.settings.buddy_min_retrieval_confidence
            and not self.settings.buddy_demo_permissive_mode
        ):
            return BuddyGenerationResult(
                response=ChatResponse(
                    answer=self._out_of_scope_answer(
                        condition=condition,
                        perspective=request.audience,
                        query=request.message,
                        emergency=bool(assess_safety(request.message).emergency_indicators),
                    ),
                    retrieved=results,
                ),
                backend_used="scope_guard",
                fallback_reason="low_retrieval_confidence",
            )

        if self.settings.buddy_generation_backend != "ollama":
            return BuddyGenerationResult(
                response=ChatResponse(answer=fallback_answer, retrieved=results),
                backend_used="composer",
            )

        try:
            draft = await self._generate_with_ollama(
                request=request,
                condition=condition,
                evidence=results,
                history=history or [],
            )
        except (httpx.HTTPError, ValueError, json.JSONDecodeError) as exc:
            return BuddyGenerationResult(
                response=ChatResponse(answer=fallback_answer, retrieved=results),
                backend_used="composer",
                fallback_reason=f"ollama_unavailable:{type(exc).__name__}",
            )

        answer = self._draft_to_answer(
            condition=condition,
            perspective=request.audience,
            query=request.message,
            evidence=results,
            draft=draft,
        )
        if not draft.answerable_from_corpus:
            answer = (
                fallback_answer
                if self.settings.buddy_demo_permissive_mode
                else self._out_of_scope_answer(
                    condition=condition,
                    perspective=request.audience,
                    query=request.message,
                    emergency=bool(assess_safety(request.message).emergency_indicators),
                )
            )

        return BuddyGenerationResult(
            response=ChatResponse(answer=answer, retrieved=results),
            backend_used="ollama",
        )

    async def _generate_with_ollama(
        self,
        *,
        request: ChatRequest,
        condition: str,
        evidence: list[SearchResult],
        history: list[dict[str, str]],
    ) -> BuddyDraftAnswer:
        system_prompt = self._system_prompt()
        evidence_block = self._evidence_block(
            condition=condition,
            audience=request.audience,
            query=request.message,
            evidence=evidence,
        )
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(self._sanitize_history(history))
        messages.append(
            {
                "role": "user",
                "content": evidence_block,
            }
        )
        payload = {
            "model": self.settings.buddy_ollama_model,
            "messages": messages,
            "format": BuddyDraftAnswer.model_json_schema(),
            "stream": False,
            "think": self.settings.buddy_ollama_think,
            "keep_alive": self.settings.buddy_ollama_keep_alive,
            "options": {
                "temperature": 0.2,
                "num_predict": 420,
            },
        }
        async with self._client() as client:
            response = await client.post("/api/chat", json=payload)
            response.raise_for_status()
        body = response.json()
        content = (
            body.get("message", {}).get("content", "").strip()
            if isinstance(body, dict)
            else ""
        )
        if not content:
            raise ValueError("Ollama response did not include assistant content")
        return BuddyDraftAnswer.model_validate_json(content)

    @asynccontextmanager
    async def _client(self) -> Any:
        if self._http_client is not None:
            yield self._http_client
            return
        async with httpx.AsyncClient(
            base_url=self.settings.buddy_ollama_base_url.rstrip("/"),
            timeout=self.settings.buddy_ollama_timeout_seconds,
        ) as client:
            yield client

    def _draft_to_answer(
        self,
        *,
        condition: str,
        perspective: Perspective,
        query: str,
        evidence: list[SearchResult],
        draft: BuddyDraftAnswer,
    ) -> EvidenceAnswer:
        safety = assess_safety(query)
        citations = self._dedupe_citations(evidence)
        confidence = round(
            sum(item.confidence for item in evidence[:5]) / max(len(evidence[:5]), 1),
            4,
        )
        when_to_seek_help = draft.when_to_seek_help.strip()
        if safety.emergency_indicators:
            when_to_seek_help = (
                "Emergency indicators are present. Please tell a trusted adult near you right now, and contact local emergency services or an appropriate crisis service immediately."
            )
        return EvidenceAnswer(
            perspective=perspective,
            condition=condition,
            what_it_is=draft.what_it_is.strip(),
            how_to_identify_it=draft.how_to_identify_it.strip(),
            what_to_do=draft.what_to_do.strip(),
            when_to_seek_help=when_to_seek_help,
            safety_note=SAFETY_NOTE,
            evidence_sources=citations,
            confidence=confidence,
        )

    def _out_of_scope_answer(
        self,
        *,
        condition: str,
        perspective: Perspective,
        query: str,
        emergency: bool,
    ) -> EvidenceAnswer:
        when_to_seek_help = (
            "If there is any immediate danger, self-harm risk, abuse, overdose, or threat to someone’s safety, tell a trusted adult now and contact local emergency services immediately."
            if emergency
            else (
                "Seek urgent help immediately if there is self-harm, suicidal thoughts, abuse, overdose, or immediate danger to anyone."
            )
        )
        return EvidenceAnswer(
            perspective=perspective,
            condition=condition,
            what_it_is=(
                "I can only answer using the approved BAHA material loaded into this system. I do not have enough matching material to answer that confidently without going beyond the current corpus."
            ),
            how_to_identify_it=(
                "I should not guess or invent facts outside the approved material. If you want, ask about stress, sleep, friendships, digital habits, school pressure, check-ins, or other wellbeing topics already covered in BAHA."
            ),
            what_to_do=(
                "Please rephrase the question around a BAHA-supported wellbeing topic, or ask a counselor, teacher, parent, or other trusted adult for situation-specific guidance."
            ),
            when_to_seek_help=when_to_seek_help,
            safety_note=SAFETY_NOTE,
            evidence_sources=[],
            confidence=0.0,
        )

    def _generic_demo_answer(
        self,
        *,
        query: str,
        perspective: Perspective,
    ) -> EvidenceAnswer:
        lowered = query.lower()
        safety = assess_safety(query)

        if any(term in lowered for term in ("stress", "overwhelmed", "pressure", "burnout")):
            condition = "Stress"
            what_it_is = (
                "It sounds like things may be piling up and your mind has not had enough room to slow down."
            )
            how_to_identify_it = (
                "Common signs can be feeling tense, restless, tired, distracted, or like small tasks suddenly feel bigger than usual."
            )
            what_to_do = (
                "Try one small reset first: pause, take a few slow breaths, choose one task only, and ask yourself what would make the next 10 minutes easier."
            )
        elif any(term in lowered for term in ("sleep", "tired", "insomnia", "late at night")):
            condition = "Sleep"
            what_it_is = (
                "It sounds like your body and mind may not be getting the rest they need to fully reset."
            )
            how_to_identify_it = (
                "You might notice trouble falling asleep, waking up tired, low energy in the day, or feeling more irritable than usual."
            )
            what_to_do = (
                "A simple place to start is a calmer wind-down routine: reduce screens before bed, dim lights, and give yourself a short quiet routine at the same time each night."
            )
        elif any(term in lowered for term in ("friend", "friendship", "reply", "group chat", "left out", "lonely")):
            condition = "Friendships"
            what_it_is = (
                "It sounds like this may be about friendship pressure, expectations, or feeling unsure how to respond without making things worse."
            )
            how_to_identify_it = (
                "A sign is when you feel tense about messages, worried about disappointing people, or like you have to stay available all the time."
            )
            what_to_do = (
                "Try a calm, honest response and a small boundary. For example: say you care about the friendship, but you may not always reply immediately."
            )
        elif any(term in lowered for term in ("phone", "screen", "social media", "instagram", "youtube", "gaming", "game")):
            condition = "Digital Wellbeing"
            what_it_is = (
                "It sounds like digital habits may be affecting your mood, focus, sleep, or daily balance."
            )
            how_to_identify_it = (
                "You might notice losing track of time, feeling drained after scrolling, or staying online longer than you meant to."
            )
            what_to_do = (
                "Try changing just one habit first, like setting a stopping time, taking short breaks, or keeping one part of the day screen-light."
            )
        elif any(term in lowered for term in ("anxious", "anxiety", "worried", "panic", "nervous")):
            condition = "Anxiety"
            what_it_is = (
                "It sounds like your mind may be staying on alert, even when you want it to settle."
            )
            how_to_identify_it = (
                "That can look like racing thoughts, tightness in the body, worrying ahead of time, or finding it hard to relax."
            )
            what_to_do = (
                "Start small: slow your breathing, name what is worrying you, and focus on one manageable next step instead of the whole situation at once."
            )
        elif any(term in lowered for term in ("sad", "down", "empty", "crying", "upset")):
            condition = "Low Mood"
            what_it_is = (
                "It sounds like you may be carrying a heavy feeling that is affecting your energy or motivation."
            )
            how_to_identify_it = (
                "Signs can include wanting to withdraw, low motivation, feeling flat, or not enjoying things as much as usual."
            )
            what_to_do = (
                "Try not to handle it all alone. A small helpful step can be reaching out to one trusted person and choosing one gentle activity that feels manageable today."
            )
        else:
            condition = "General Wellbeing"
            what_it_is = (
                "It sounds like something is on your mind, and taking a moment to slow it down is a good first step."
            )
            how_to_identify_it = (
                "A useful check is to notice what you are feeling, what seems to trigger it, and whether it is affecting sleep, mood, school, or relationships."
            )
            what_to_do = (
                "Start with one small action: pause, breathe slowly, name the main issue, and decide whether you need rest, support, or one practical next step."
            )

        when_to_seek_help = (
            "Tell a trusted adult right away and contact local emergency help immediately if there is self-harm risk, suicidal thoughts, abuse, overdose, or immediate danger."
            if safety.emergency_indicators
            else "If this keeps getting worse, feels too heavy to manage alone, or starts affecting your safety, daily life, or relationships, talk to a trusted adult or qualified professional."
        )

        return EvidenceAnswer(
            perspective=perspective,
            condition=condition,
            what_it_is=what_it_is,
            how_to_identify_it=how_to_identify_it,
            what_to_do=what_to_do,
            when_to_seek_help=when_to_seek_help,
            safety_note=SAFETY_NOTE,
            evidence_sources=[],
            confidence=0.7,
        )

    def _sanitize_history(self, history: list[dict[str, str]]) -> list[dict[str, str]]:
        sanitized: list[dict[str, str]] = []
        for item in history[-self.settings.buddy_history_window :]:
            role = item.get("role")
            content = " ".join((item.get("content") or "").split()).strip()
            if role not in {"user", "assistant"} or not content:
                continue
            sanitized.append({"role": role, "content": content})
        return sanitized

    def _system_prompt(self) -> str:
        return (
            "You are BAHA Buddy, a retrieval-grounded wellbeing assistant inside the BAHA product. "
            "You are not a therapist, you do not diagnose, and you must not invent facts. "
            "Only answer using the evidence snippets provided in the final user message. "
            "If the snippets do not support the question clearly, set answerable_from_corpus to false. "
            "Do not provide medication advice, legal advice, or unsupported crisis instructions. "
            "Do not mention sources that are not in the provided evidence. "
            "Keep the tone calm, supportive, age-appropriate, and non-clinical."
        )

    def _dedupe_citations(self, evidence: list[SearchResult]) -> list[Any]:
        seen: set[tuple[str, str, str | None]] = set()
        citations = []
        for result in evidence:
            for citation in result.citations:
                key = (citation.title, citation.organization, citation.url)
                if key in seen:
                    continue
                seen.add(key)
                citations.append(citation)
        return citations

    def _evidence_block(
        self,
        *,
        condition: str,
        audience: Perspective,
        query: str,
        evidence: list[SearchResult],
    ) -> str:
        lines = [
            f"Audience: {audience}",
            f"Detected topic: {condition}",
            f"User question: {query}",
            "Use only the following approved evidence snippets:",
        ]
        for index, item in enumerate(evidence[:5], start=1):
            citation = item.citations[0] if item.citations else None
            title = citation.title if citation else "Approved evidence"
            organization = citation.organization if citation else item.metadata.organization
            snippet = " ".join(item.text.split())
            lines.append(
                (
                    f"[{index}] Title: {title}\n"
                    f"Organization: {organization}\n"
                    f"Confidence: {item.confidence:.2f}\n"
                    f"Snippet: {snippet}"
                )
            )
        lines.append(
            "Return only JSON matching the requested schema. Do not add markdown fences or extra prose."
        )
        return "\n\n".join(lines)
