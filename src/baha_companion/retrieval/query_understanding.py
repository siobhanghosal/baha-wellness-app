from __future__ import annotations

from baha_companion.retrieval.models import QueryUnderstanding
from baha_companion.retrieval.utils import PRIORITY_ORGANISATIONS, normalize_text, significant_terms


AUDIENCE_HINTS = {
    "student": {"student", "students", "teen", "teens", "adolescent", "adolescents", "child", "children"},
    "parent": {"parent", "parents", "caregiver", "caregivers", "family", "families"},
    "teacher": {"teacher", "teachers", "school", "educator", "educators", "classroom"},
}
AGE_GROUP_HINTS = {
    "children": {"child", "children", "kids", "kid"},
    "adolescents": {"teen", "teens", "adolescent", "adolescents"},
    "young_adults": {"college", "university", "young", "youth"},
    "general": {"adult", "adults", "general"},
}
GENDER_HINTS = {
    "female": {"girl", "girls", "female", "women", "woman"},
    "male": {"boy", "boys", "male", "men", "man"},
}
TOPIC_HINTS = {
    "anxiety": {"anxiety", "panic", "worry", "worried"},
    "stress": {"stress", "stressed", "burnout", "exam"},
    "sleep": {"sleep", "insomnia", "bedtime"},
    "bullying": {"bully", "bullying", "harassment"},
    "depression": {"depression", "depressed", "hopeless"},
}
EVIDENCE_HINTS = {
    "guideline": {"guideline", "guidelines", "recommended", "recommendation"},
    "systematic_review": {"systematic", "review", "meta-analysis", "meta"},
    "randomized_trial": {"trial", "randomized", "rct"},
}
INTENT_HINTS = {
    "symptom_lookup": {"symptom", "symptoms", "sign", "signs"},
    "support_guidance": {"help", "support", "guidance", "advice"},
    "activity_lookup": {"activity", "activities", "exercise", "exercises"},
    "definition_lookup": {"what", "define", "meaning", "explain"},
    "prevention_lookup": {"prevent", "prevention", "avoid"},
}
COUNTRY_HINTS = {
    "india": {"india", "indian"},
    "united states": {"us", "usa", "american", "america", "united states"},
    "united kingdom": {"uk", "britain", "british", "england", "united kingdom"},
}
LANGUAGE_HINTS = {
    "english": {"english"},
    "hindi": {"hindi"},
}


class QueryUnderstandingService:
    def analyze(self, query: str) -> QueryUnderstanding:
        normalized_query = normalize_text(query) or ""
        terms = set(significant_terms(normalized_query, limit=20))

        return QueryUnderstanding(
            topic=self._match_first(terms, TOPIC_HINTS),
            subtopic=None,
            audience=self._match_first(terms, AUDIENCE_HINTS),
            age_group=self._match_first(terms, AGE_GROUP_HINTS),
            gender=self._match_first(terms, GENDER_HINTS),
            organisation=self._match_organisation(normalized_query),
            country=self._match_first(terms, COUNTRY_HINTS),
            evidence_level=self._match_first(terms, EVIDENCE_HINTS),
            language=self._match_first(terms, LANGUAGE_HINTS),
            keywords=significant_terms(normalized_query),
            intent=self._match_first(terms, INTENT_HINTS),
        )

    def _match_first(self, terms: set[str], mapping: dict[str, set[str]]) -> str | None:
        for label, options in mapping.items():
            if terms & options:
                return label
        return None

    def _match_organisation(self, normalized_query: str) -> str | None:
        for organisations in PRIORITY_ORGANISATIONS.values():
            for organisation in organisations:
                if organisation in normalized_query:
                    return organisation.upper() if organisation.isupper() else organisation.title()
        return None
