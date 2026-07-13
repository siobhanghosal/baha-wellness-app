from __future__ import annotations

from dataclasses import dataclass
from difflib import SequenceMatcher
import re

from baha_companion.knowledge.types import KnowledgeObjectDraft


def _token_set(value: str) -> set[str]:
    return {token for token in re.findall(r"[a-z0-9]{3,}", value.lower())}


@dataclass(slots=True)
class DuplicateMatch:
    knowledge_object_id: str
    score: float
    title_similarity: float
    content_similarity: float
    semantic_similarity: float


class DuplicateDetectionService:
    def detect_duplicate(
        self,
        draft: KnowledgeObjectDraft,
        *,
        existing_objects: list[dict],
    ) -> DuplicateMatch | None:
        best_match: DuplicateMatch | None = None
        draft_title = draft.title.lower()
        draft_body = draft.body.lower()
        draft_tokens = _token_set(draft_body)
        for item in existing_objects:
            title_similarity = SequenceMatcher(None, draft_title, str(item["title"]).lower()).ratio()
            existing_body = str(item["body"]).lower()
            body_similarity = SequenceMatcher(None, draft_body[:1500], existing_body[:1500]).ratio()
            existing_tokens = _token_set(existing_body)
            semantic_similarity = self._jaccard_similarity(draft_tokens, existing_tokens)
            organization_bonus = 0.05 if item.get("organization") == draft.organization else 0.0
            publication_bonus = 0.05 if item.get("publication_date") == draft.publication_date else 0.0
            score = round(
                (title_similarity * 0.4)
                + (body_similarity * 0.35)
                + (semantic_similarity * 0.2)
                + organization_bonus
                + publication_bonus,
                3,
            )
            if score >= 0.82 and (best_match is None or score > best_match.score):
                best_match = DuplicateMatch(
                    knowledge_object_id=str(item["id"]),
                    score=score,
                    title_similarity=round(title_similarity, 3),
                    content_similarity=round(body_similarity, 3),
                    semantic_similarity=round(semantic_similarity, 3),
                )
        return best_match

    @staticmethod
    def _jaccard_similarity(left: set[str], right: set[str]) -> float:
        if not left or not right:
            return 0.0
        return len(left & right) / len(left | right)

