from __future__ import annotations

import math
import re
from collections import Counter
from datetime import UTC, date, datetime
from typing import Iterable


TOKEN_RE = re.compile(r"[a-z0-9]+")
STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "help",
    "how",
    "i",
    "in",
    "is",
    "me",
    "of",
    "on",
    "or",
    "the",
    "to",
    "what",
    "with",
}

PRIORITY_ORGANISATIONS = {
    "priority_1": {"baha", "aha", "iap", "nimhans"},
    "priority_2": {"unicef", "ncert", "cbse", "mohfw", "nmhp", "ncpcr", "aiims", "icmr"},
    "priority_3": {
        "who",
        "unesco",
        "cdc",
        "nih",
        "nice",
        "nhs",
        "aap",
        "samhsa",
        "pubmed",
        "europe pmc",
        "semantic scholar",
    },
}

PRIORITY_SCORES = {"priority_1": 1.0, "priority_2": 0.7, "priority_3": 0.45, "unknown": 0.25}
EVIDENCE_SCORES = {
    "guideline": 1.0,
    "systematic_review": 0.95,
    "meta_analysis": 0.95,
    "randomized_trial": 0.9,
    "peer_reviewed": 0.82,
    "observational_study": 0.7,
    "consensus": 0.6,
    "educational_content": 0.5,
    "unknown": 0.3,
}


def tokenize(text: str) -> list[str]:
    return TOKEN_RE.findall(text.lower())


def significant_terms(text: str, *, limit: int = 12) -> list[str]:
    counts = Counter(token for token in tokenize(text) if token not in STOPWORDS and len(token) > 2)
    return [token for token, _count in counts.most_common(limit)]


def normalize_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = " ".join(value.strip().split()).lower()
    return cleaned or None


def normalize_score_map(scores: dict[str, float]) -> dict[str, float]:
    positive = [score for score in scores.values() if score > 0]
    if not positive:
        return {key: 0.0 for key in scores}
    minimum = min(positive)
    maximum = max(positive)
    if math.isclose(minimum, maximum):
        return {key: 1.0 if score > 0 else 0.0 for key, score in scores.items()}
    return {
        key: round((score - minimum) / (maximum - minimum), 6) if score > 0 else 0.0
        for key, score in scores.items()
    }


def cosine_similarity(left: list[float], right: list[float]) -> float:
    dot = sum(a * b for a, b in zip(left, right, strict=False))
    left_norm = math.sqrt(sum(item * item for item in left))
    right_norm = math.sqrt(sum(item * item for item in right))
    if math.isclose(left_norm, 0.0) or math.isclose(right_norm, 0.0):
        return 0.0
    return dot / (left_norm * right_norm)


def inner_product(left: list[float], right: list[float]) -> float:
    return sum(a * b for a, b in zip(left, right, strict=False))


def l2_similarity(left: list[float], right: list[float]) -> float:
    distance = math.sqrt(sum((a - b) ** 2 for a, b in zip(left, right, strict=False)))
    return 1.0 / (1.0 + distance)


def similarity(metric: str, left: list[float], right: list[float]) -> float:
    if metric == "inner_product":
        return inner_product(left, right)
    if metric == "l2":
        return l2_similarity(left, right)
    return cosine_similarity(left, right)


def organization_priority(organisation: str | None, priority_level: str | None) -> str:
    organization_name = normalize_text(organisation) or ""
    for priority, values in PRIORITY_ORGANISATIONS.items():
        if organization_name in values:
            return priority
    normalized_priority = normalize_text(priority_level)
    if normalized_priority in PRIORITY_SCORES:
        return normalized_priority
    return "unknown"


def priority_score(organisation: str | None, priority_level: str | None) -> float:
    return PRIORITY_SCORES[organization_priority(organisation, priority_level)]


def evidence_score(evidence_level: str | None) -> float:
    return EVIDENCE_SCORES.get(normalize_text(evidence_level) or "unknown", EVIDENCE_SCORES["unknown"])


def recency_score(publication_date: date | None, *, now: datetime | None = None) -> float:
    if publication_date is None:
        return 0.0
    current = now or datetime.now(UTC)
    age_days = max(0, (current.date() - publication_date).days)
    if age_days <= 365:
        return 1.0
    if age_days <= 365 * 2:
        return 0.8
    if age_days <= 365 * 5:
        return 0.5
    return 0.2


def jaccard_similarity(left_tokens: Iterable[str], right_tokens: Iterable[str]) -> float:
    left_set = set(left_tokens)
    right_set = set(right_tokens)
    if not left_set or not right_set:
        return 0.0
    return len(left_set & right_set) / len(left_set | right_set)


def title_case_match(query_terms: list[str], title: str) -> float:
    title_tokens = tokenize(title)
    if not query_terms or not title_tokens:
        return 0.0
    overlap = sum(1 for term in query_terms if term in title_tokens)
    return overlap / len(query_terms)
