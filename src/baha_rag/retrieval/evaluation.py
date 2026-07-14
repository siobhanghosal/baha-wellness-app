from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from baha_rag.retrieval.hybrid import HybridRetriever


EVALUATION_QUERIES = (
    ("parent", "Signs of anxiety", "anxiety"),
    ("parent", "Child depression", "depression"),
    ("parent", "Sleep problems", "sleep"),
    ("teacher", "Bullying intervention", "bullying"),
    ("teacher", "Classroom stress", "stress"),
    ("teacher", "ADHD support", "adhd"),
    ("counselor", "Self harm assessment", "self harm"),
    ("counselor", "Suicide prevention", "suicide prevention"),
    ("counselor", "Referral guidance", "mental health"),
)


class RetrievalEvaluator:
    def __init__(self, retriever: HybridRetriever) -> None:
        self.retriever = retriever

    async def run(self, *, top_k: int = 10) -> dict[str, Any]:
        evaluations = []
        for perspective, query, expected_topic in EVALUATION_QUERIES:
            results = await self.retriever.search(query, top_k=top_k, filters={})
            topic_hits = sum(
                1
                for result in results
                if expected_topic in " ".join(
                    value or ""
                    for value in (
                        result.metadata.topic,
                        result.metadata.condition,
                        result.metadata.subtopic,
                        result.text[:500],
                    )
                ).lower()
            )
            cited = sum(1 for result in results if result.citations)
            organizations = []
            for result in results:
                if result.metadata.organization not in organizations:
                    organizations.append(result.metadata.organization)
            evaluations.append(
                {
                    "perspective": perspective,
                    "query": query,
                    "expected_topic": expected_topic,
                    "result_count": len(results),
                    "coverage_score": round(topic_hits / max(top_k, 1), 4),
                    "citation_quality": round(cited / max(len(results), 1), 4),
                    "confidence": round(
                        sum(result.confidence for result in results)
                        / max(len(results), 1),
                        4,
                    ),
                    "top_10_sources": [
                        {
                            "title": result.citations[0].title if result.citations else "",
                            "organization": result.metadata.organization,
                            "url": result.citations[0].url if result.citations else None,
                            "confidence": result.confidence,
                            "topic": result.metadata.topic,
                        }
                        for result in results
                    ],
                    "organization_coverage": organizations,
                }
            )
        return {
            "queries": evaluations,
            "average_coverage": round(
                sum(item["coverage_score"] for item in evaluations) / len(evaluations),
                4,
            ),
            "average_citation_quality": round(
                sum(item["citation_quality"] for item in evaluations) / len(evaluations),
                4,
            ),
            "average_confidence": round(
                sum(item["confidence"] for item in evaluations) / len(evaluations),
                4,
            ),
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
