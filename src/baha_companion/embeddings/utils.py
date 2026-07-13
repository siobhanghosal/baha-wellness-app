from __future__ import annotations

import hashlib
import json
import math
import re
from typing import Any

from baha_companion.knowledge.models import KnowledgeObject


def build_retrieval_summary(knowledge_object: KnowledgeObject) -> str:
    topic = _primary_topic(knowledge_object)
    parts = [
        "Evidence-based information",
        f"from {knowledge_object.details.organization}" if knowledge_object.details.organization else None,
        f"about {topic}" if topic else None,
        f"for {knowledge_object.details.audience.replace('_', ' ')}" if knowledge_object.details.audience else None,
        f"aged {knowledge_object.details.age_group}" if knowledge_object.details.age_group not in {"general", "parent", "teacher"} else None,
    ]
    details = []
    if knowledge_object.summary:
        details.append(knowledge_object.summary.split(".")[0].strip().rstrip("."))
    if knowledge_object.faqs:
        details.append("common questions and practical guidance")
    if knowledge_object.activities:
        details.append("activities and support strategies")
    sentence = " ".join(part for part in parts if part).strip()
    extras = ", ".join(item for item in details if item)
    return f"{sentence} including {extras}.".strip()


def build_retrieval_document(knowledge_object: KnowledgeObject, retrieval_summary: str) -> str:
    topic = _primary_topic(knowledge_object)
    subtopic = _primary_subtopic(knowledge_object)
    keywords = ", ".join(item.keyword for item in sorted(knowledge_object.keywords, key=lambda row: row.sort_order))
    key_points = _key_points(knowledge_object)
    body_sections = [
        f"Title: {knowledge_object.title}",
        f"Topic: {topic}" if topic else None,
        f"Subtopic: {subtopic}" if subtopic else None,
        f"Audience: {knowledge_object.details.audience}",
        f"Age Group: {knowledge_object.details.age_group}",
        f"Organization: {knowledge_object.details.organization}" if knowledge_object.details.organization else None,
        f"Retrieval Summary: {retrieval_summary}",
        f"Key Points: {key_points}",
        f"Body: {knowledge_object.body}",
        f"Keywords: {keywords}" if keywords else None,
    ]
    return "\n".join(section for section in body_sections if section)


def compute_content_hash(payload: str) -> str:
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def deterministic_embedding(text: str, *, dimensions: int) -> list[float]:
    digest = hashlib.sha256(text.encode("utf-8")).digest()
    values: list[float] = []
    for index in range(dimensions):
        byte = digest[index % len(digest)]
        values.append(round(((byte / 255.0) * 2.0) - 1.0, 6))
    return values


def vector_to_db_payload(vector: list[float]) -> str:
    return "[" + ",".join(f"{value:.6f}" for value in vector) + "]"


def vector_from_db_payload(value: Any) -> list[float]:
    if isinstance(value, list):
        return [float(item) for item in value]
    if isinstance(value, str):
        cleaned = value.strip().strip("[]")
        if not cleaned:
            return []
        return [float(item) for item in cleaned.split(",")]
    return []


def average(values: list[float | int]) -> float:
    return round(sum(values) / len(values), 2) if values else 0.0


def distribution_bucket(score: float) -> str:
    if score >= 80:
        return "high"
    if score >= 60:
        return "medium"
    return "low"


def compact_json(value: dict | list) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=True, default=str)


def _primary_topic(knowledge_object: KnowledgeObject) -> str | None:
    topic = next((item for item in knowledge_object.topics if item.is_primary), None)
    return topic.topic if topic else None


def _primary_subtopic(knowledge_object: KnowledgeObject) -> str | None:
    topic = next((item for item in knowledge_object.topics if item.is_primary), None)
    return topic.subtopic if topic else None


def _key_points(knowledge_object: KnowledgeObject) -> str:
    points: list[str] = []
    for sentence in re.split(r"(?<=[.!?])\s+", knowledge_object.summary or knowledge_object.body):
        cleaned = sentence.strip()
        if cleaned:
            points.append(cleaned.rstrip("."))
        if len(points) == 3:
            break
    for faq in knowledge_object.faqs[:2]:
        points.append(f"FAQ: {faq.question}")
    for activity in knowledge_object.activities[:2]:
        points.append(f"Activity: {activity.title}")
    return "; ".join(points[:5])


def cosine_ready_dimension(vector: list[float]) -> int:
    return int(math.sqrt(len(vector) ** 2))

