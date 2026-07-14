from __future__ import annotations

from baha_rag.schemas import Citation, ConditionKnowledge, SearchResult


FIELD_TERMS = {
    "definition": ("definition", "defined", "refers to", "is a"),
    "symptoms": ("symptom", "sign", "present", "complain"),
    "risk_factors": ("risk factor", "risk", "associated with", "vulnerable"),
    "protective_factors": ("protective", "resilience", "support", "connected"),
    "parent_signs": ("parent", "caregiver", "home", "family"),
    "teacher_signs": ("teacher", "school", "classroom", "attendance"),
    "assessment_methods": ("assessment", "screen", "questionnaire", "evaluate"),
    "recommended_interventions": ("intervention", "recommend", "support", "strategy"),
    "classroom_support": ("classroom", "teacher", "school support", "accommodation"),
    "family_support": ("family", "parent", "caregiver", "home support"),
    "escalation_indicators": ("refer", "escalate", "specialist", "urgent"),
    "emergency_indicators": ("suicide", "self-harm", "overdose", "danger", "emergency"),
    "approved_resources": ("resource", "helpline", "guideline", "support service"),
}


class ConditionProfileExtractor:
    def extract(self, condition: str, evidence: list[SearchResult]) -> ConditionKnowledge:
        buckets = {field: [] for field in FIELD_TERMS}
        for result in evidence:
            for sentence in self._sentences(result.text):
                lowered = sentence.lower()
                for field, terms in FIELD_TERMS.items():
                    if any(term in lowered for term in terms):
                        buckets[field].append(sentence)
        return ConditionKnowledge(
            condition=condition,
            definition=self._first_or_empty(buckets["definition"]),
            symptoms=buckets["symptoms"][:8],
            risk_factors=buckets["risk_factors"][:8],
            protective_factors=buckets["protective_factors"][:8],
            parent_signs=buckets["parent_signs"][:8],
            teacher_signs=buckets["teacher_signs"][:8],
            assessment_methods=buckets["assessment_methods"][:8],
            recommended_interventions=buckets["recommended_interventions"][:8],
            classroom_support=buckets["classroom_support"][:8],
            family_support=buckets["family_support"][:8],
            escalation_indicators=buckets["escalation_indicators"][:8],
            emergency_indicators=buckets["emergency_indicators"][:8],
            approved_resources=buckets["approved_resources"][:8],
            evidence_sources=self._citations(evidence),
        )

    def _sentences(self, text: str) -> list[str]:
        return [sentence.strip() + "." for sentence in text.replace("\n", " ").split(".") if sentence.strip()]

    def _first_or_empty(self, values: list[str]) -> str:
        return values[0] if values else ""

    def _citations(self, evidence: list[SearchResult]) -> list[Citation]:
        citations = []
        seen = set()
        for result in evidence:
            for citation in result.citations:
                key = (citation.title, citation.organization, citation.url)
                if key in seen:
                    continue
                seen.add(key)
                citations.append(citation)
        return citations
