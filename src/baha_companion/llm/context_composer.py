from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date
from typing import Any

from baha_companion.llm.config import LLMSettings
from baha_companion.llm.token_counter import TokenCounter


PRIORITY_ORDER = {"priority_1": 4, "priority_2": 3, "priority_3": 2, "priority_4": 1}
EVIDENCE_ORDER = {
    "systematic review": 5,
    "meta analysis": 5,
    "meta-analysis": 5,
    "guideline": 4,
    "randomized controlled trial": 4,
    "review": 3,
    "observational": 2,
    "expert opinion": 1,
}


@dataclass(slots=True)
class ContextEntry:
    source_id: str
    knowledge_object_id: str
    title: str
    summary: str
    excerpt: str
    organisation: str | None
    priority: str | None
    evidence_level: str | None
    publication_date: date | None
    score: float
    token_count: int
    citations: list[dict[str, Any]] = field(default_factory=list)


@dataclass(slots=True)
class ContextPackage:
    entries: list[ContextEntry]
    total_tokens: int
    omitted_count: int
    has_sufficient_evidence: bool

    @property
    def context_ids(self) -> list[str]:
        return [entry.knowledge_object_id for entry in self.entries]


class ContextComposer:
    def __init__(self, settings: LLMSettings, token_counter: TokenCounter | None = None) -> None:
        self.settings = settings
        self.token_counter = token_counter or TokenCounter()

    def compose(self, *, query: str, retrieved_items: list[dict[str, Any]]) -> ContextPackage:
        normalized_query_terms = self._query_terms(query)
        deduplicated = self._deduplicate(retrieved_items)
        ranked = sorted(
            deduplicated,
            key=lambda item: (
                self._priority_rank(item.get("priority")),
                self._evidence_rank(item.get("evidence_level")),
                float(item.get("final_score", 0.0)),
            ),
            reverse=True,
        )

        selected: list[ContextEntry] = []
        total_tokens = 0
        omitted_count = 0

        for index, item in enumerate(ranked[: self.settings.llm_context_candidate_limit], start=1):
            relevance = self._relevance_score(item=item, query_terms=normalized_query_terms)
            if relevance <= 0 and float(item.get("final_score", 0.0)) < self.settings.llm_min_context_score:
                omitted_count += 1
                continue

            excerpt = self._build_excerpt(item)
            token_count = self.token_counter.count_text(excerpt) + self.token_counter.count_text(item.get("summary"))
            if selected and total_tokens + token_count > self.settings.llm_max_context_tokens:
                omitted_count += 1
                continue

            selected.append(
                ContextEntry(
                    source_id=f"S{index}",
                    knowledge_object_id=item["knowledge_object_id"],
                    title=item["title"],
                    summary=item.get("summary") or "",
                    excerpt=excerpt,
                    organisation=item.get("organisation"),
                    priority=item.get("priority"),
                    evidence_level=item.get("evidence_level"),
                    publication_date=item.get("publication_date"),
                    score=round(float(item.get("final_score", 0.0)), 6),
                    token_count=token_count,
                    citations=[
                        {
                            "source_id": f"S{index}",
                            "knowledge_object_id": item["knowledge_object_id"],
                            "title": item["title"],
                            "organisation": item.get("organisation"),
                            "publication_date": item.get("publication_date"),
                            "priority": item.get("priority"),
                            "evidence_level": item.get("evidence_level"),
                        }
                    ],
                )
            )
            total_tokens += token_count

        sufficient = bool(
            selected
            and any(
                self._priority_rank(entry.priority) >= 3 or self._evidence_rank(entry.evidence_level) >= 3
                for entry in selected
            )
        )
        return ContextPackage(
            entries=selected,
            total_tokens=total_tokens,
            omitted_count=omitted_count + max(0, len(ranked) - self.settings.llm_context_candidate_limit),
            has_sufficient_evidence=sufficient,
        )

    def _deduplicate(self, items: list[dict[str, Any]]) -> list[dict[str, Any]]:
        seen: dict[tuple[str, str], dict[str, Any]] = {}
        for item in items:
            normalized_title = self._normalize_text(item.get("title"))
            normalized_body = self._normalize_text((item.get("summary") or "") + " " + (item.get("body") or ""))[:400]
            key = (item["knowledge_object_id"], normalized_title or normalized_body)
            current = seen.get(key)
            if current is None or float(item.get("final_score", 0.0)) > float(current.get("final_score", 0.0)):
                seen[key] = item
        return list(seen.values())

    def _build_excerpt(self, item: dict[str, Any]) -> str:
        summary = (item.get("summary") or "").strip()
        body = (item.get("body") or "").strip()
        merged = summary if summary else body
        if summary and body and self._normalize_text(summary) not in self._normalize_text(body):
            merged = f"{summary}\n\n{body}"
        return merged[:1200].strip()

    @staticmethod
    def _normalize_text(value: str | None) -> str:
        if not value:
            return ""
        return re.sub(r"\s+", " ", value).strip().lower()

    def _query_terms(self, query: str) -> set[str]:
        return {
            term
            for term in re.findall(r"[a-zA-Z0-9]+", query.lower())
            if len(term) >= 3
        }

    def _relevance_score(self, *, item: dict[str, Any], query_terms: set[str]) -> int:
        if not query_terms:
            return 1
        haystack = self._normalize_text(
            " ".join(
                filter(
                    None,
                    [
                        item.get("title"),
                        item.get("summary"),
                        item.get("body"),
                        item.get("topic"),
                        item.get("subtopic"),
                    ],
                )
            )
        )
        return sum(1 for term in query_terms if term in haystack)

    @staticmethod
    def _priority_rank(priority: str | None) -> int:
        if not priority:
            return 0
        return PRIORITY_ORDER.get(priority.lower(), 0)

    @staticmethod
    def _evidence_rank(evidence_level: str | None) -> int:
        if not evidence_level:
            return 0
        lowered = evidence_level.lower()
        for label, rank in EVIDENCE_ORDER.items():
            if label in lowered:
                return rank
        return 0
