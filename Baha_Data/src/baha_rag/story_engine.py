from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any

import httpx

from baha_rag.config import Settings
from baha_rag.gameplay import GameLocationDefinition
from baha_rag.schemas import SearchResult


@dataclass(frozen=True)
class StorySceneDraft:
    title: str
    body: str
    prompt: str


@dataclass(frozen=True)
class StoryOutcomeDraft:
    message: str


class OpenAIStoryEngine:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    @property
    def enabled(self) -> bool:
        return bool(self._settings.openai_api_key)

    async def generate_scene(
        self,
        *,
        player_fingerprint: str,
        player_name: str,
        age_years: int,
        pet: str,
        avatar: dict[str, Any],
        location: GameLocationDefinition,
        chapter: int,
        friendship_level: int,
        memories: list[str],
        last_choice: str | None,
        recent_location_events: list[dict[str, Any]],
        recent_global_events: list[dict[str, Any]],
        evidence: list[SearchResult],
    ) -> StorySceneDraft | None:
        if not self.enabled:
            return None
        payload = {
            "model": self._settings.openai_story_model,
            "instructions": (
                "You are the live story narrator for an endless, highly personalized "
                "roleplaying story for one child aged 9-12. Every reply should feel "
                "fresh, specific, and unique to this child, never like a repeated template. "
                "Use the child's name, their pet, recurring details, NPC memories, recent "
                "events, and the presentation style to make the story feel truly theirs. "
                "Match the reading level and social tone to the child's age. "
                "Write in warm, playful language with short sentences. "
                "Keep the moment open-ended so the child can type anything next. "
                "The story can be magical, social, funny, brave, or surprising, but it must "
                "always stay emotionally safe and age-appropriate. "
                "Do not mention game systems, chapters, scores, or that you are an AI. "
                "Do not present multiple choice options. Do not sound like a worksheet. "
                "Body should be 3 or 4 short sentences and should naturally continue from "
                "what already happened. Prompt should be one inviting question. "
                "Avoid repetition across turns, avoid generic filler, avoid scary detail, "
                "and avoid diagnosis, therapy language, or shame. "
                "Return JSON only with keys title, body, prompt."
            ),
            "input": json.dumps(
                {
                    "task": "Generate the next story turn in an ongoing personalized roleplaying story.",
                    "player_fingerprint": player_fingerprint,
                    "player_name": player_name,
                    "age_years": age_years,
                    "pet": pet,
                    "presentation_style": _presentation_style(avatar),
                    "location_id": location.location_id,
                    "location_name": location.display_name,
                    "npc_id": location.npc_id,
                    "chapter": chapter,
                    "friendship_level": friendship_level,
                    "location_seed": location.body,
                    "location_prompt_seed": location.prompt,
                    "last_choice": last_choice,
                    "npc_memories": memories[:6],
                    "recent_location_events": _recent_event_notes(recent_location_events),
                    "recent_global_events": _recent_event_notes(recent_global_events),
                    "evidence_notes": _evidence_notes(evidence),
                },
                ensure_ascii=False,
            ),
            "temperature": 0.95,
            "max_output_tokens": 260,
        }
        response = await self._create_response(payload)
        if response is None:
            return None
        data = _parse_json_output(response)
        if data is None:
            return None
        title = _clean_text(data.get("title"))
        body = _clean_text(data.get("body"))
        prompt = _clean_text(data.get("prompt"))
        if not title or not body or not prompt:
            return None
        return StorySceneDraft(title=title, body=body, prompt=prompt)

    async def generate_outcome(
        self,
        *,
        player_fingerprint: str,
        player_name: str,
        age_years: int,
        pet: str,
        avatar: dict[str, Any],
        location: GameLocationDefinition,
        chapter: int,
        answer: str,
        memories: list[str],
        recent_location_events: list[dict[str, Any]],
        recent_global_events: list[dict[str, Any]],
        evidence: list[SearchResult],
    ) -> StoryOutcomeDraft | None:
        if not self.enabled:
            return None
        payload = {
            "model": self._settings.openai_story_model,
            "instructions": (
                "You are replying to a child's custom action inside an endless, "
                "personalized roleplaying story for ages 9-12. Respond like a warm, "
                "imaginative story guide, almost like a kid-safe ChatGPT narrator. "
                "Make the reply feel specific to this exact child, their history, and "
                "their words. Let their action matter. Show a clear consequence, one new "
                "detail, and a natural opening into what happens next. "
                "Match the tone and reading level to the child's age. "
                "Use clear words, short sentences, and a tone that feels alive and personal. "
                "Write 3 or 4 short sentences. Do not offer options. Do not analyze the child. "
                "Do not repeat the child's words back in a dull way. Do not mention chapters "
                "or game systems. Keep it safe, emotionally warm, and open-ended. "
                "Return JSON only with the key message."
            ),
            "input": json.dumps(
                {
                    "task": "Continue the story after the child's action in a way that feels unique and alive.",
                    "player_fingerprint": player_fingerprint,
                    "player_name": player_name,
                    "age_years": age_years,
                    "pet": pet,
                    "presentation_style": _presentation_style(avatar),
                    "location_id": location.location_id,
                    "location_name": location.display_name,
                    "npc_id": location.npc_id,
                    "chapter": chapter,
                    "answer": answer,
                    "location_seed": location.body,
                    "npc_memories": memories[:6],
                    "recent_location_events": _recent_event_notes(recent_location_events),
                    "recent_global_events": _recent_event_notes(recent_global_events),
                    "evidence_notes": _evidence_notes(evidence),
                },
                ensure_ascii=False,
            ),
            "temperature": 1.0,
            "max_output_tokens": 220,
        }
        response = await self._create_response(payload)
        if response is None:
            return None
        data = _parse_json_output(response)
        if data is None:
            return None
        message = _clean_text(data.get("message"))
        if not message:
            return None
        return StoryOutcomeDraft(message=message)

    async def _create_response(self, payload: dict[str, Any]) -> dict[str, Any] | None:
        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        timeout = httpx.Timeout(6.0, connect=3.0)
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(
                    self._settings.openai_api_base,
                    headers=headers,
                    json=payload,
                )
                response.raise_for_status()
        except (httpx.HTTPError, ValueError):
            return None
        try:
            decoded = response.json()
        except ValueError:
            return None
        return decoded if isinstance(decoded, dict) else None


def _presentation_style(avatar: dict[str, Any]) -> str:
    theme = str(avatar.get("story_theme", "adventure_blue")).strip().lower()
    if theme == "princess":
        return (
            "Princess sparkle: soft pinks, gold shimmer, brave castles, ribbons, "
            "kind queens, and magical confidence."
        )
    return (
        "Adventure blue: bright blue skies, treasure maps, playful action, ocean "
        "glow, friendly heroes, and fun explorer energy."
    )


def _evidence_notes(evidence: list[SearchResult]) -> list[str]:
    notes: list[str] = []
    for item in evidence[:3]:
        text = re.sub(r"\s+", " ", item.text).strip()
        if len(text) > 160:
            text = f"{text[:157].rstrip()}..."
        topic = item.metadata.topic or item.metadata.subtopic or "wellbeing"
        notes.append(f"{topic}: {text}")
    return notes


def _recent_event_notes(events: list[dict[str, Any]]) -> list[str]:
    notes: list[str] = []
    for item in events[:8]:
        location = str(item.get("location_id", "somewhere")).strip() or "somewhere"
        chapter = item.get("chapter")
        choice_text = _clean_text(item.get("choice_text"))
        consequence = _clean_text(item.get("consequence"))
        chapter_text = f"turn {chapter}" if isinstance(chapter, int) else "recent turn"
        parts = [f"{location} {chapter_text}"]
        if choice_text:
            parts.append(f"child action: {choice_text}")
        if consequence:
            parts.append(f"result: {consequence}")
        notes.append(" | ".join(parts))
    return notes


def _parse_json_output(response: dict[str, Any]) -> dict[str, Any] | None:
    text = _response_output_text(response)
    if not text:
        return None
    normalized = text.strip()
    if normalized.startswith("```"):
        normalized = re.sub(r"^```(?:json)?\s*", "", normalized)
        normalized = re.sub(r"\s*```$", "", normalized)
    try:
        data = json.loads(normalized)
    except json.JSONDecodeError:
        start = normalized.find("{")
        end = normalized.rfind("}")
        if start == -1 or end == -1 or end <= start:
            return None
        try:
            data = json.loads(normalized[start : end + 1])
        except json.JSONDecodeError:
            return None
    return data if isinstance(data, dict) else None


def _response_output_text(response: dict[str, Any]) -> str:
    parts: list[str] = []
    for item in response.get("output", []):
        if not isinstance(item, dict) or item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if not isinstance(content, dict):
                continue
            if content.get("type") == "output_text" and isinstance(content.get("text"), str):
                parts.append(content["text"])
    return "\n".join(parts).strip()


def _clean_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return re.sub(r"\s+", " ", value).strip()
