from __future__ import annotations

from collections.abc import AsyncIterator
from dataclasses import dataclass
import json
import re
from typing import Any, Literal

import httpx
from pydantic import BaseModel, Field, ValidationError

from baha_rag.config import Settings
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


@dataclass(frozen=True)
class BuddyReplyPlan:
    condition: str
    strategy: Literal["safety_local", "openai_conversational", "openai_grounded"]
    evidence: list[SearchResult]
    response: ChatResponse | None = None
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
        history = history or []
        if self.settings.buddy_chat_mode == "generic_demo":
            return BuddyGenerationResult(
                response=ChatResponse(
                    answer=self.text_reply_to_answer(
                        condition=self._resolve_condition(request.message),
                        perspective=request.audience,
                        query=request.message,
                        reply_text=(
                            "I’m here with you. Tell me a little more about what is going on, "
                            "or ask about sleep, stress, school, mood, or friendships."
                        ),
                        evidence=[],
                    ),
                    retrieved=[],
                ),
                backend_used="generic_demo",
            )

        plan = await self.prepare_reply(
            request=request,
            retriever=retriever,
        )
        if plan.response is not None:
            return BuddyGenerationResult(
                response=plan.response,
                backend_used=plan.strategy,
                fallback_reason=plan.fallback_reason,
            )

        if not self.settings.buddy_openai_api_key.strip():
            raise ValueError("BUDDY_OPENAI_API_KEY is not configured.")

        grounded_draft: BuddyDraftAnswer | None = None
        if plan.strategy == "openai_grounded":
            grounded_draft = await self._generate_structured_with_openai(
                request=request,
                condition=plan.condition,
                evidence=plan.evidence,
                history=history,
                grounded=True,
            )
            if grounded_draft is not None and grounded_draft.answerable_from_corpus:
                return BuddyGenerationResult(
                    response=ChatResponse(
                        answer=self._draft_to_answer(
                            condition=plan.condition,
                            perspective=request.audience,
                            query=request.message,
                            evidence=plan.evidence,
                            draft=grounded_draft,
                        ),
                        retrieved=plan.evidence,
                    ),
                    backend_used="openai_grounded",
                    fallback_reason=plan.fallback_reason,
                )

        conversational_draft = await self._generate_structured_with_openai(
            request=request,
            condition=plan.condition,
            evidence=[],
            history=history,
            grounded=False,
        )
        if conversational_draft is not None:
            fallback_reason = plan.fallback_reason
            if grounded_draft is None and plan.strategy == "openai_grounded":
                fallback_reason = fallback_reason or "invalid_grounded_model_output"
            if grounded_draft is not None and not grounded_draft.answerable_from_corpus:
                fallback_reason = fallback_reason or "grounded_answer_unavailable"
            return BuddyGenerationResult(
                response=ChatResponse(
                    answer=self._draft_to_answer(
                        condition=plan.condition,
                        perspective=request.audience,
                        query=request.message,
                        evidence=[],
                        draft=conversational_draft,
                    ),
                    retrieved=plan.evidence if plan.strategy == "openai_grounded" else [],
                ),
                backend_used="openai_conversational",
                fallback_reason=fallback_reason,
            )

        return BuddyGenerationResult(
            response=ChatResponse(
                answer=self._out_of_scope_answer(
                    condition=plan.condition,
                    perspective=request.audience,
                    query=request.message,
                    emergency=False,
                ),
                retrieved=plan.evidence,
            ),
            backend_used="local_fallback",
            fallback_reason=plan.fallback_reason or "invalid_model_output",
        )

    async def prepare_reply(
        self,
        *,
        request: ChatRequest,
        retriever: Any,
    ) -> BuddyReplyPlan:
        safety = assess_safety(request.message)
        condition = self._resolve_condition(request.message)
        if safety.emergency_indicators:
            return BuddyReplyPlan(
                condition="Safety",
                strategy="safety_local",
                evidence=[],
                response=ChatResponse(
                    answer=self._emergency_answer(
                        perspective=request.audience,
                        query=request.message,
                    ),
                    retrieved=[],
                ),
            )

        if not self._should_ground_with_retrieval(
            message=request.message,
            condition=condition,
        ):
            return BuddyReplyPlan(
                condition=condition,
                strategy="openai_conversational",
                evidence=[],
            )

        results = await retriever.search(
            request.message,
            top_k=request.top_k,
            filters=request.filters,
        )
        if not results:
            return BuddyReplyPlan(
                condition=condition,
                strategy="openai_conversational",
                evidence=[],
                fallback_reason="no_retrieval_results",
            )

        if (
            results[0].confidence < self.settings.buddy_min_retrieval_confidence
            and not self._has_usable_grounding_signal(results)
        ):
            return BuddyReplyPlan(
                condition=condition,
                strategy="openai_conversational",
                evidence=results,
                fallback_reason="low_retrieval_confidence",
            )

        return BuddyReplyPlan(
            condition=condition,
            strategy="openai_grounded",
            evidence=results,
        )

    async def stream_reply_text(
        self,
        *,
        request: ChatRequest,
        plan: BuddyReplyPlan,
        history: list[dict[str, str]] | None = None,
    ) -> AsyncIterator[str]:
        history = history or []
        if plan.strategy == "openai_grounded":
            async for delta in self._stream_openai_reply_text(
                request=request,
                condition=plan.condition,
                evidence=plan.evidence,
                history=history,
                grounded=True,
            ):
                yield delta
            return

        async for delta in self._stream_openai_reply_text(
            request=request,
            condition=plan.condition,
            evidence=[],
            history=history,
            grounded=False,
        ):
            yield delta

    def assistant_text_from_answer(self, answer: EvidenceAnswer) -> str:
        return " ".join(
            part.strip()
            for part in (
                answer.what_it_is,
                answer.what_to_do,
                answer.when_to_seek_help,
            )
            if part.strip()
        )

    def text_reply_to_answer(
        self,
        *,
        condition: str,
        perspective: Perspective,
        query: str,
        reply_text: str,
        evidence: list[SearchResult],
    ) -> EvidenceAnswer:
        safety = assess_safety(query)
        return EvidenceAnswer(
            perspective=perspective,
            condition=condition,
            what_it_is=reply_text.strip(),
            how_to_identify_it=(
                "This reply was delivered in conversational chat mode and may combine emotional support with concise guidance."
            ),
            what_to_do=reply_text.strip(),
            when_to_seek_help=(
                "Tell a trusted adult right away and contact local emergency help immediately if there is self-harm risk, suicidal thoughts, abuse, overdose, or immediate danger."
                if safety.emergency_indicators
                else "If this keeps getting worse, feels too heavy to manage alone, or starts affecting your safety or daily life, talk to a trusted adult or qualified professional."
            ),
            safety_note=SAFETY_NOTE,
            evidence_sources=self._dedupe_citations(evidence),
            confidence=(
                round(
                    sum(item.confidence for item in evidence[:5])
                    / max(len(evidence[:5]), 1),
                    4,
                )
                if evidence
                else 0.55
            ),
        )

    def _has_usable_grounding_signal(self, results: list[SearchResult]) -> bool:
        lexical_hits = sum(1 for item in results[:4] if item.lexical_score > 0)
        strong_dense_hit = any(item.dense_score >= 0.35 for item in results[:3])
        return lexical_hits >= 2 or strong_dense_hit

    def _conversation_mode(self, message: str) -> str:
        lowered = " ".join(message.lower().split())
        stripped = lowered.strip(" .!?")
        if stripped in {
            "hi",
            "hello",
            "hey",
            "hey there",
            "yo",
            "good morning",
            "good afternoon",
            "good evening",
            "thanks",
            "thank you",
            "ok",
            "okay",
        }:
            return "social"

        supportive_phrases = (
            "i feel",
            "i'm feeling",
            "i am feeling",
            "i'm tired",
            "i am tired",
            "rough day",
            "bad day",
            "i feel alone",
            "i'm overwhelmed",
            "i am overwhelmed",
            "i'm stressed",
            "i am stressed",
            "nobody gets me",
            "no one gets me",
            "i'm done",
            "i am done",
            "i hate this",
            "i can't do this",
        )
        if "?" not in message and any(phrase in lowered for phrase in supportive_phrases):
            return "supportive"

        return "grounded"

    def _should_ground_with_retrieval(self, *, message: str, condition: str) -> bool:
        if condition == "General Wellbeing":
            return False
        lowered = message.lower()
        guidance_phrases = (
            "how can i",
            "how do i",
            "what can i do",
            "what should i do",
            "any tips",
            "help me",
            "improve",
            "manage",
            "cope",
            "deal with",
            "handle",
            "support",
            "why am i",
            "how to",
        )
        if any(phrase in lowered for phrase in guidance_phrases):
            return True
        return "?" in message and self._seems_within_baha_scope(message)

    def _resolve_condition(self, message: str) -> str:
        lowered = message.lower()
        keyword_map = (
            (("sleep", "tired", "insomnia", "bedtime", "wake up"), "Sleep"),
            (("stress", "overwhelmed", "pressure", "burnout"), "Stress"),
            (("anxious", "anxiety", "panic", "worried", "nervous"), "Anxiety"),
            (("sad", "down", "empty", "crying", "upset"), "Low Mood"),
            (("friend", "friendship", "lonely", "left out", "group chat"), "Friendships"),
            (("phone", "screen", "social media", "gaming", "internet"), "Digital Wellbeing"),
            (("school", "exam", "study", "homework", "focus"), "School Pressure"),
        )
        for terms, label in keyword_map:
            if any(term in lowered for term in terms):
                return label
        return next(iter(find_conditions(message)), "General Wellbeing")

    def _seems_within_baha_scope(self, message: str) -> bool:
        lowered = message.lower()
        domain_terms = (
            "sleep",
            "stress",
            "school",
            "exam",
            "study",
            "focus",
            "mood",
            "friend",
            "friendship",
            "lonely",
            "anxiety",
            "worried",
            "panic",
            "sad",
            "down",
            "energy",
            "routine",
            "phone",
            "screen",
            "social media",
            "gaming",
            "wellbeing",
            "health",
            "overwhelmed",
            "tired",
            "bullying",
            "pressure",
        )
        first_person_support = (
            "i feel",
            "i'm",
            "i am",
            "my sleep",
            "my stress",
            "my mood",
            "my friends",
            "my family",
            "my school",
        )
        return any(term in lowered for term in domain_terms) or any(
            phrase in lowered for phrase in first_person_support
        )

    async def _generate_structured_with_openai(
        self,
        *,
        request: ChatRequest,
        condition: str,
        evidence: list[SearchResult],
        history: list[dict[str, str]],
        grounded: bool,
    ) -> BuddyDraftAnswer | None:
        payload = {
            "model": self.settings.buddy_openai_model,
            "instructions": (
                self._openai_grounded_system_prompt()
                if grounded
                else self._openai_conversational_system_prompt()
            ),
            "input": self._openai_input_block(
                request=request,
                condition=condition,
                evidence=evidence,
                history=history,
                grounded=grounded,
            ),
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "buddy_draft_answer",
                    "schema": self._openai_output_schema(),
                }
            },
            "max_output_tokens": 240,
            "reasoning": {"effort": "minimal"},
        }
        if self._http_client is not None:
            client = self._http_client
            response = await client.post(
                "/responses",
                headers={
                    "Authorization": (
                        f"Bearer {self.settings.buddy_openai_api_key}"
                    ),
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        else:
            async with httpx.AsyncClient(
                base_url=self.settings.buddy_openai_base_url.rstrip("/"),
                timeout=self.settings.buddy_openai_timeout_seconds,
            ) as client:
                response = await client.post(
                    "/responses",
                    headers={
                        "Authorization": (
                            f"Bearer {self.settings.buddy_openai_api_key}"
                        ),
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )
        response.raise_for_status()
        body = response.json()
        content = self._extract_openai_output_text(body)
        if not content:
            return None
        try:
            return BuddyDraftAnswer.model_validate_json(content)
        except ValidationError:
            return None

    async def _stream_openai_reply_text(
        self,
        *,
        request: ChatRequest,
        condition: str,
        evidence: list[SearchResult],
        history: list[dict[str, str]],
        grounded: bool,
    ) -> AsyncIterator[str]:
        payload = {
            "model": self.settings.buddy_openai_model,
            "instructions": (
                self._openai_grounded_text_system_prompt()
                if grounded
                else self._openai_conversational_text_system_prompt()
            ),
            "input": self._openai_input_block(
                request=request,
                condition=condition,
                evidence=evidence,
                history=history,
                grounded=grounded,
            ),
            "stream": True,
            "max_output_tokens": 240,
            "reasoning": {"effort": "minimal"},
            "text": {
                "format": {"type": "text"},
                "verbosity": "low",
            },
        }

        if self._http_client is not None:
            async with self._http_client.stream(
                "POST",
                "/responses",
                headers={
                    "Authorization": f"Bearer {self.settings.buddy_openai_api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            ) as response:
                response.raise_for_status()
                async for delta in self._iter_openai_stream_text(response):
                    yield delta
            return

        async with httpx.AsyncClient(
            base_url=self.settings.buddy_openai_base_url.rstrip("/"),
            timeout=self.settings.buddy_openai_timeout_seconds,
        ) as client:
            async with client.stream(
                "POST",
                "/responses",
                headers={
                    "Authorization": f"Bearer {self.settings.buddy_openai_api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            ) as response:
                response.raise_for_status()
                async for delta in self._iter_openai_stream_text(response):
                    yield delta

    async def _iter_openai_stream_text(
        self,
        response: httpx.Response,
    ) -> AsyncIterator[str]:
        saw_delta = False
        fallback_text = ""
        async for raw_line in response.aiter_lines():
            line = raw_line.strip()
            if not line or not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if not data or data == "[DONE]":
                continue
            try:
                event = json.loads(data)
            except json.JSONDecodeError:
                continue
            if event.get("type") == "error":
                message = (
                    event.get("error", {}).get("message")
                    or event.get("message")
                    or "OpenAI streaming request failed."
                )
                raise ValueError(str(message))
            delta = self._extract_openai_stream_delta(event)
            if delta:
                saw_delta = True
                yield delta
                continue
            fallback_candidate = self._extract_openai_stream_completed_text(event)
            if fallback_candidate:
                fallback_text = fallback_candidate
        if not saw_delta and fallback_text:
            yield fallback_text

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

    def _emergency_answer(
        self,
        *,
        perspective: Perspective,
        query: str,
    ) -> EvidenceAnswer:
        return EvidenceAnswer(
            perspective=perspective,
            condition="Safety",
            what_it_is=(
                "I’m really glad you reached out. Your safety matters most right now."
            ),
            how_to_identify_it=(
                "This sounds urgent, so the safest next step is to involve a real person near you immediately."
            ),
            what_to_do=(
                "Please tell a trusted adult near you right now, or call local emergency services or an appropriate crisis line immediately."
            ),
            when_to_seek_help=(
                "Do not stay with this alone. Get immediate help now."
            ),
            safety_note=SAFETY_NOTE,
            evidence_sources=[],
            confidence=1.0,
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
                "I can stay with you here, but I don’t have enough reliable BAHA material to answer that specific question well."
            ),
            how_to_identify_it=(
                "I don’t want to guess or make things up. I’m better at wellbeing topics like stress, sleep, school pressure, friendships, routines, and mood."
            ),
            what_to_do=(
                "If you want, ask it in a wellbeing way, or just tell me what’s been going on and I can help you think it through more gently."
            ),
            when_to_seek_help=when_to_seek_help,
            safety_note=SAFETY_NOTE,
            evidence_sources=[],
            confidence=0.0,
        )

    def _sanitize_history(
        self,
        history: list[dict[str, str]],
        *,
        limit: int | None = None,
    ) -> list[dict[str, str]]:
        sanitized: list[dict[str, str]] = []
        selected = history[-limit:] if limit is not None else history
        for item in selected:
            role = item.get("role")
            content = " ".join((item.get("content") or "").split()).strip()
            if role not in {"user", "assistant"} or not content:
                continue
            sanitized.append({"role": role, "content": content})
        return sanitized

    def _session_memory_block(self, history: list[dict[str, str]]) -> str:
        sanitized = self._sanitize_history(
            history,
            limit=max(self.settings.buddy_history_window * 3, 18),
        )
        if not sanitized:
            return "(no established session context yet)"
        user_messages = [
            item["content"] for item in sanitized if item["role"] == "user"
        ]
        if not user_messages:
            return "(no user-specific context yet)"

        contexts = self._remembered_contexts(user_messages)
        factors = self._remembered_wellbeing_factors(user_messages)
        facts = self._remembered_user_facts(user_messages)
        latest_user_line = self._clip_snippet(user_messages[-1], max_words=18)

        lines = [f"Latest user concern: {latest_user_line}"]
        if contexts:
            lines.append(
                "Remembered life context from earlier in this session: "
                + ", ".join(contexts)
            )
        if factors:
            lines.append(
                "Repeated wellbeing themes mentioned so far: "
                + ", ".join(factors)
            )
        if facts:
            lines.extend(f"Remembered fact: {fact}" for fact in facts[:4])
        lines.append(
            "If the user asks what they mentioned earlier, answer from this remembered context and the visible conversation history directly."
        )
        return "\n".join(lines)

    def _remembered_contexts(self, user_messages: list[str]) -> list[str]:
        context_map = (
            ("work", ("work", "job", "office", "boss", "coworker", "shift")),
            (
                "school",
                ("school", "class", "exam", "college", "teacher", "homework"),
            ),
            (
                "friends",
                ("friend", "friends", "friendship", "group chat", "left out"),
            ),
            ("family", ("family", "parent", "parents", "mom", "dad", "home")),
        )
        remembered: list[str] = []
        lowered_messages = [message.lower() for message in user_messages]
        for label, terms in context_map:
            if any(any(term in message for term in terms) for message in lowered_messages):
                remembered.append(label)
        return remembered

    def _remembered_wellbeing_factors(self, user_messages: list[str]) -> list[str]:
        factor_order = (
            "Sleep",
            "Stress",
            "Anxiety",
            "Low Mood",
            "Friendships",
            "Digital Wellbeing",
            "School Pressure",
        )
        seen: list[str] = []
        for message in user_messages:
            condition = self._resolve_condition(message)
            if condition in factor_order and condition not in seen:
                seen.append(condition)
        return seen

    def _remembered_user_facts(self, user_messages: list[str]) -> list[str]:
        facts: list[str] = []
        fact_patterns = (
            (
                re.compile(r"\btrouble at work\b", re.IGNORECASE),
                "The user said they were having trouble at work.",
            ),
            (
                re.compile(r"\btrouble at school\b", re.IGNORECASE),
                "The user said they were having trouble at school.",
            ),
            (
                re.compile(r"\b(can't|cannot|couldn't|could not)\s+sleep\b", re.IGNORECASE),
                "The user said sleep has been difficult.",
            ),
            (
                re.compile(r"\b(feel|feeling)\s+overwhelmed\b", re.IGNORECASE),
                "The user said they felt overwhelmed.",
            ),
            (
                re.compile(r"\b(feel|feeling)\s+stressed\b", re.IGNORECASE),
                "The user said they felt stressed.",
            ),
        )
        joined = "\n".join(user_messages)
        for pattern, statement in fact_patterns:
            if pattern.search(joined):
                facts.append(statement)
        return facts

    def _openai_grounded_system_prompt(self) -> str:
        return (
            "You are BAHA Buddy, a retrieval-grounded wellbeing assistant inside the BAHA product. "
            "You are not a therapist, you do not diagnose, and you must not invent facts. "
            "Only answer using the approved evidence snippets provided in the user input. "
            "If the evidence is relevant but incomplete, answer conservatively and stay close to the snippets. "
            "If the evidence is not enough to give grounded factual advice, set answerable_from_corpus to false instead of inventing detail. "
            "Pay attention to remembered session context and conversation history so your reply stays continuous across turns. "
            "If the user asks what they mentioned earlier, answer directly from the visible session context instead of ignoring it. "
            "Write in a warm, natural, concise way for a young user. "
            "Default to short paragraphs, not essays or bullet-heavy lists, unless the evidence strongly requires a short list. "
            "Keep each field compact and conversational. "
            "Return only valid JSON with the exact keys: "
            "answerable_from_corpus, what_it_is, how_to_identify_it, what_to_do, when_to_seek_help. "
            "Do not wrap the JSON in markdown fences or add any extra prose."
        )

    def _openai_conversational_system_prompt(self) -> str:
        return (
            "You are BAHA Buddy, a warm wellbeing companion inside the BAHA product. "
            "You can have natural conversation, acknowledge feelings, and offer gentle wellbeing-oriented support. "
            "You are not a therapist and you do not diagnose. "
            "If the user asks about something unrelated to youth wellbeing, answer briefly and gently steer back toward wellbeing support. "
            "Use remembered session context so the conversation feels continuous and attentive. "
            "If the user asks what they said earlier, answer from the remembered context and visible history directly. "
            "Keep the tone concise, natural, and human, not robotic. "
            "Return only valid JSON with the exact keys: "
            "answerable_from_corpus, what_it_is, how_to_identify_it, what_to_do, when_to_seek_help. "
            "Set answerable_from_corpus to true for this conversational mode. "
            "Do not wrap the JSON in markdown fences or add any extra prose."
        )

    def _openai_grounded_text_system_prompt(self) -> str:
        return (
            "You are BAHA Buddy. Reply in a warm, natural, concise way. "
            "Use only the approved evidence provided for factual advice. "
            "Do not diagnose or invent facts. "
            "Use remembered session context so the reply stays continuous across turns. "
            "If the evidence is limited, say that simply and stay conservative. "
            "Write 3 to 6 short sentences total, as a normal chat reply."
        )

    def _openai_conversational_text_system_prompt(self) -> str:
        return (
            "You are BAHA Buddy. Reply like a calm, supportive, natural chat companion. "
            "You are not a therapist and you do not diagnose. "
            "You can have light conversation, acknowledge feelings, and offer gentle wellbeing-oriented next steps. "
            "Use remembered session context so the user feels heard across multiple turns. "
            "If the question is outside your main wellbeing role, answer briefly and redirect kindly. "
            "Keep the reply concise, human, and no more than 4 short sentences."
        )

    def _openai_input_block(
        self,
        *,
        request: ChatRequest,
        condition: str,
        evidence: list[SearchResult],
        history: list[dict[str, str]],
        grounded: bool,
    ) -> str:
        evidence_block = (
            "Use only the following approved evidence snippets:\n\n"
            f"{self._openai_evidence_block(evidence)}"
            if grounded
            else "No external evidence snippets are supplied for this reply. Rely on brief, supportive, non-diagnostic conversation only."
        )
        return (
            f"Audience: {request.audience}\n"
            f"Detected topic: {condition}\n"
            f"User question: {request.message}\n"
            "Remembered session context:\n"
            f"{self._session_memory_block(history)}\n\n"
            "Conversation so far:\n"
            f"{self._history_block(history)}\n\n"
            "Response style:\n"
            "- sound calm, warm, and human\n"
            "- keep it concise\n"
            "- prefer 2 to 4 sentences total worth of content per field, not essays\n"
            "- no diagnosis\n"
            f"- {'no invented facts beyond the evidence' if grounded else 'no diagnosis and no pretending to know private details'}\n"
            f"- {'if the evidence is weak, set answerable_from_corpus to false' if grounded else 'keep the support general and emotionally intelligent'}\n\n"
            f"{evidence_block}"
        )

    def _history_block(self, history: list[dict[str, str]]) -> str:
        sanitized = self._sanitize_history(
            history,
            limit=self.settings.buddy_history_window,
        )
        if not sanitized:
            return "(no prior conversation)"
        return "\n".join(
            f"{item['role'].title()}: {item['content']}" for item in sanitized
        )

    def _openai_evidence_block(self, evidence: list[SearchResult]) -> str:
        lines: list[str] = []
        for index, item in enumerate(evidence[:3], start=1):
            citation = item.citations[0] if item.citations else None
            title = citation.title if citation else "Approved evidence"
            organization = citation.organization if citation else item.metadata.organization
            snippet = self._clip_snippet(item.text, max_words=48)
            lines.append(
                (
                    f"[{index}] Title: {title}\n"
                    f"Organization: {organization}\n"
                    f"Confidence: {item.confidence:.2f}\n"
                    f"Snippet: {snippet}"
                )
            )
        return "\n\n".join(lines)

    def _clip_snippet(self, text: str, max_words: int = 85) -> str:
        cleaned = re.sub(r"\s+", " ", text).strip()
        words = cleaned.split(" ")
        if len(words) <= max_words:
            return cleaned
        return " ".join(words[:max_words]).rstrip(" ,;:") + "..."

    def _extract_openai_output_text(self, payload: dict[str, Any]) -> str:
        output = payload.get("output", [])
        texts: list[str] = []
        for item in output:
            if item.get("type") != "message":
                continue
            for content in item.get("content", []):
                if content.get("type") == "output_text" and content.get("text"):
                    texts.append(str(content["text"]).strip())
        return "\n".join(text for text in texts if text)

    def _extract_openai_stream_delta(self, event: dict[str, Any]) -> str:
        if event.get("type") == "response.output_text.delta":
            return str(event.get("delta") or "")
        delta = event.get("delta")
        if isinstance(delta, str):
            return delta
        output_text = event.get("output_text")
        if isinstance(output_text, str):
            return output_text
        return ""

    def _extract_openai_stream_completed_text(self, event: dict[str, Any]) -> str:
        if event.get("type") == "response.output_text.done":
            return str(event.get("text") or "").strip()
        if event.get("type") == "response.output_item.done":
            item = event.get("item", {})
            if item.get("type") != "message":
                return ""
            texts: list[str] = []
            for content in item.get("content", []):
                if content.get("type") == "output_text" and content.get("text"):
                    texts.append(str(content["text"]).strip())
            return " ".join(text for text in texts if text)
        if event.get("type") == "response.completed":
            return self._extract_openai_output_text(
                event.get("response", {}) if isinstance(event.get("response"), dict) else {}
            ).strip()
        return ""

    def _openai_output_schema(self) -> dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "answerable_from_corpus": {"type": "boolean"},
                "what_it_is": {"type": "string"},
                "how_to_identify_it": {"type": "string"},
                "what_to_do": {"type": "string"},
                "when_to_seek_help": {"type": "string"},
            },
            "required": [
                "answerable_from_corpus",
                "what_it_is",
                "how_to_identify_it",
                "what_to_do",
                "when_to_seek_help",
            ],
            "additionalProperties": False,
        }

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
