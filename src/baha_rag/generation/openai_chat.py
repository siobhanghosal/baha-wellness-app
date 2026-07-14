from __future__ import annotations

from typing import Any

import httpx

from baha_rag.config import Settings
from baha_rag.safety import SAFETY_NOTE, assess_safety
from baha_rag.schemas import ChatAnswer, ChatMessage, Citation, Perspective, SearchResult


class OpenAIChatService:
    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None) -> None:
        self.settings = settings
        self._client = client

    async def generate(
        self,
        *,
        query: str,
        perspective: Perspective,
        condition: str,
        evidence: list[SearchResult],
        history: list[ChatMessage],
    ) -> ChatAnswer:
        citations = self._dedupe_citations(evidence)
        confidence = round(sum(item.confidence for item in evidence[:5]) / max(len(evidence[:5]), 1), 4)
        if not evidence:
            return ChatAnswer(
                message=(
                    "I could not find approved evidence for that question in the current BAHA knowledge base, "
                    "so I cannot give a grounded answer yet."
                ),
                condition=condition,
                citations=[],
                confidence=0.0,
                safety_note=SAFETY_NOTE,
                model=self.settings.openai_chat_model,
            )

        if not self.settings.openai_api_key:
            raise ValueError("OPENAI_API_KEY is not configured.")

        payload = self._build_payload(
            query=query,
            perspective=perspective,
            condition=condition,
            evidence=evidence,
            history=history,
        )

        if self._client is None:
            async with httpx.AsyncClient(
                base_url=self.settings.openai_base_url.rstrip("/"),
                timeout=self.settings.openai_timeout_seconds,
            ) as client:
                data = await self._create_response(client, payload)
        else:
            data = await self._create_response(self._client, payload)

        message = self._extract_output_text(data)
        if not message:
            raise ValueError("OpenAI response did not include assistant text.")

        return ChatAnswer(
            message=message,
            condition=condition,
            citations=citations,
            confidence=confidence,
            safety_note=SAFETY_NOTE,
            model=str(data.get("model") or self.settings.openai_chat_model),
        )

    async def _create_response(self, client: httpx.AsyncClient, payload: dict[str, Any]) -> dict[str, Any]:
        response = await client.post(
            "/responses",
            headers={
                "Authorization": f"Bearer {self.settings.openai_api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        if response.is_error:
            detail = self._error_message(response)
            raise ValueError(f"OpenAI API request failed: {detail}")
        return response.json()

    def _build_payload(
        self,
        *,
        query: str,
        perspective: Perspective,
        condition: str,
        evidence: list[SearchResult],
        history: list[ChatMessage],
    ) -> dict[str, Any]:
        return {
            "model": self.settings.openai_chat_model,
            "instructions": self._system_instructions(),
            "input": self._build_user_prompt(
                query=query,
                perspective=perspective,
                condition=condition,
                evidence=evidence,
                history=history,
            ),
            "text": {
                "format": {
                    "type": "text",
                }
            },
        }

    def _system_instructions(self) -> str:
        return (
            "You are the BAHA Wellness Companion RAG chatbot. "
            "Answer only from the supplied evidence excerpts. "
            "Be supportive, clear, and concise. "
            "Do not diagnose, do not invent facts, and do not claim certainty beyond the evidence. "
            "If the evidence is incomplete, say so directly. "
            "When you use evidence, cite source numbers inline like [1] or [2]. "
            "If emergency or self-harm risk is mentioned, urge immediate local emergency or crisis support."
        )

    def _build_user_prompt(
        self,
        *,
        query: str,
        perspective: Perspective,
        condition: str,
        evidence: list[SearchResult],
        history: list[ChatMessage],
    ) -> str:
        safety = assess_safety(query)
        history_block = self._format_history(history)
        evidence_block = self._format_evidence(evidence)
        return (
            f"Audience: {perspective}\n"
            f"Detected condition/topic: {condition}\n"
            f"Safety guidance: {safety.guidance}\n\n"
            "Conversation so far:\n"
            f"{history_block}\n\n"
            "Approved evidence excerpts:\n"
            f"{evidence_block}\n\n"
            "User question:\n"
            f"{query}\n\n"
            "Write one helpful answer for the user. Keep it evidence-grounded, mention uncertainty when needed, "
            "and end with a short safety-oriented next step when appropriate."
        )

    def _format_history(self, history: list[ChatMessage]) -> str:
        if not history:
            return "(no prior conversation)"
        formatted = []
        for item in history[-6:]:
            label = "User" if item.role == "user" else "Assistant"
            formatted.append(f"{label}: {item.content.strip()}")
        return "\n".join(formatted)

    def _format_evidence(self, evidence: list[SearchResult]) -> str:
        blocks = []
        for index, item in enumerate(evidence[:6], start=1):
            citation = item.citations[0] if item.citations else Citation(
                title="Untitled source",
                organization=item.metadata.organization,
                url=None,
            )
            excerpt = " ".join(item.text.split())
            if len(excerpt) > 900:
                excerpt = excerpt[:897].rstrip() + "..."
            blocks.append(
                f"[{index}] {citation.title} | {citation.organization}"
                + (f" | {citation.url}" if citation.url else "")
                + f"\nExcerpt: {excerpt}"
            )
        return "\n\n".join(blocks)

    def _extract_output_text(self, payload: dict[str, Any]) -> str:
        output = payload.get("output", [])
        texts: list[str] = []
        for item in output:
            if item.get("type") != "message":
                continue
            for content in item.get("content", []):
                if content.get("type") == "output_text" and content.get("text"):
                    texts.append(str(content["text"]).strip())
        return "\n\n".join(text for text in texts if text)

    def _error_message(self, response: httpx.Response) -> str:
        try:
            payload = response.json()
        except ValueError:
            return response.text.strip() or f"HTTP {response.status_code}"
        error = payload.get("error")
        if isinstance(error, dict):
            message = error.get("message")
            if message:
                return str(message)
        return str(payload)

    def _dedupe_citations(self, evidence: list[SearchResult]) -> list[Citation]:
        seen = set()
        citations: list[Citation] = []
        for result in evidence:
            for citation in result.citations:
                key = (citation.title, citation.organization, citation.url)
                if key in seen:
                    continue
                seen.add(key)
                citations.append(citation)
        return citations
