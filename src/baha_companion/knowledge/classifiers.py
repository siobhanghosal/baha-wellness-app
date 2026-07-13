from __future__ import annotations

import math
import re
from collections import Counter

from baha_companion.knowledge.types import (
    AgeGroup,
    AudienceType,
    ClinicalReviewStatus,
    EvidenceLevel,
    GenderGroup,
    PriorityLevel,
)


TOPIC_KEYWORDS: dict[str, tuple[str, ...]] = {
    "anxiety": ("anxiety", "panic", "worry"),
    "depression": ("depression", "depressive", "low mood"),
    "stress": ("stress", "burnout", "pressure"),
    "bullying": ("bullying", "bullied", "victimisation"),
    "cyberbullying": ("cyberbullying", "online bullying", "digital abuse"),
    "adhd": ("adhd", "attention deficit", "hyperactivity"),
    "autism": ("autism", "asd", "autistic"),
    "substance abuse": ("substance", "drug use", "addiction", "misuse"),
    "alcohol": ("alcohol", "drinking"),
    "smoking": ("smoking", "cigarette"),
    "vaping": ("vaping", "e-cigarette", "vape"),
    "sleep": ("sleep", "insomnia", "sleep hygiene"),
    "nutrition": ("nutrition", "diet", "healthy eating"),
    "exercise": ("exercise", "physical activity", "fitness"),
    "friendship": ("friendship", "peer support"),
    "self esteem": ("self esteem", "self-worth", "confidence"),
    "academic stress": ("academic stress", "exam stress", "school stress"),
    "social media": ("social media", "instagram", "tiktok"),
    "gaming": ("gaming", "video game", "screen time"),
    "body image": ("body image", "appearance", "weight concern"),
    "grief": ("grief", "bereavement", "loss"),
    "family relationships": ("family", "parent-child", "caregiver"),
    "emotion regulation": ("emotion regulation", "emotional clarity", "alexithymia"),
    "resilience": ("resilience", "coping", "protective factor"),
    "digital safety": ("digital safety", "online safety", "internet safety"),
}


STOPWORDS = {
    "the",
    "and",
    "for",
    "with",
    "that",
    "this",
    "from",
    "into",
    "have",
    "your",
    "their",
    "about",
    "when",
    "what",
    "will",
    "been",
    "more",
    "than",
}


PRIORITY_PATTERNS = {
    PriorityLevel.PRIORITY_1: ("baha", "aha", "iap", "nimhans"),
    PriorityLevel.PRIORITY_2: ("unicef", "ncert", "cbse", "mohfw", "nmhp", "ncpcr", "aiims", "icmr"),
    PriorityLevel.PRIORITY_3: ("who", "unesco", "cdc", "nih", "nice", "nhs", "aap", "samhsa", "pubmed", "europe pmc", "semantic scholar"),
}


class TopicClassifier:
    def classify(self, text: str, *, metadata_topic: str | None = None, metadata_subtopic: str | None = None) -> tuple[str, str | None, float]:
        lowered = text.lower()
        if metadata_topic:
            return metadata_topic.lower(), metadata_subtopic.lower() if metadata_subtopic else None, 0.98

        best_topic = "general wellness"
        best_score = 0.2
        best_subtopic: str | None = None
        for topic, keywords in TOPIC_KEYWORDS.items():
            score = sum(lowered.count(keyword) for keyword in keywords)
            if score > best_score:
                best_topic = topic
                best_score = float(score)
                best_subtopic = keywords[0]
        confidence = min(0.99, 0.35 + math.log1p(best_score) / 3)
        return best_topic, best_subtopic, round(confidence, 2)

    def extract_keywords(self, text: str, *, topic: str, subtopic: str | None = None) -> list[str]:
        tokens = re.findall(r"[a-zA-Z][a-zA-Z\-]{2,}", text.lower())
        counts = Counter(token for token in tokens if token not in STOPWORDS)
        ranked = [keyword for keyword, _count in counts.most_common(8)]
        seeds = [topic]
        if subtopic:
            seeds.append(subtopic)
        return list(dict.fromkeys([seed for seed in seeds if seed] + ranked))[:10]


class AudienceClassifier:
    def classify(self, text: str) -> AudienceType:
        lowered = text.lower()
        if any(phrase in lowered for phrase in ("for parents", "parent guidance", "caregiver")):
            return AudienceType.PARENT
        if any(phrase in lowered for phrase in ("for teachers", "teacher guidance", "educator")):
            return AudienceType.TEACHER
        if any(phrase in lowered for phrase in ("counsellor", "counselor", "therapist")):
            return AudienceType.COUNSELLOR
        if any(phrase in lowered for phrase in ("clinician", "physician", "healthcare professional", "psychiatric outpatient")):
            return AudienceType.HEALTHCARE_PROFESSIONAL
        if any(phrase in lowered for phrase in ("administrator", "school leader", "principal")):
            return AudienceType.ADMINISTRATOR
        if any(phrase in lowered for phrase in ("student", "adolescent", "teen", "young people")):
            return AudienceType.STUDENT
        return AudienceType.GENERAL


class AgeClassifier:
    def classify(self, text: str, *, audience: AudienceType) -> AgeGroup:
        lowered = text.lower()
        if audience == AudienceType.PARENT:
            return AgeGroup.PARENT
        if audience == AudienceType.TEACHER:
            return AgeGroup.TEACHER
        if re.search(r"\b(9|10|11|12)\b", lowered) or "preteen" in lowered:
            return AgeGroup.AGES_9_12
        if any(term in lowered for term in ("13-16", "13 to 16", "middle school", "adolescent")):
            return AgeGroup.AGES_13_16
        if any(term in lowered for term in ("17-19", "17 to 19", "older teen", "college transition")):
            return AgeGroup.AGES_17_19
        if "child" in lowered:
            return AgeGroup.AGES_9_12
        if "teen" in lowered or "youth" in lowered:
            return AgeGroup.AGES_13_16
        return AgeGroup.GENERAL


class EvidenceClassifier:
    def classify(self, text: str, *, organization: str | None, metadata: dict) -> tuple[EvidenceLevel, float, ClinicalReviewStatus]:
        lowered = text.lower()
        publication_types = " ".join(metadata.get("publication_types", [])) if isinstance(metadata.get("publication_types"), list) else ""
        evidence_source = " ".join([lowered, publication_types.lower(), str(metadata.get("journal", "")).lower()])

        if "guideline" in evidence_source:
            return EvidenceLevel.CLINICAL_GUIDELINE, 0.96, ClinicalReviewStatus.PEER_REVIEWED
        if "systematic review" in evidence_source or "scoping review" in evidence_source:
            return EvidenceLevel.SYSTEMATIC_REVIEW, 0.94, ClinicalReviewStatus.PEER_REVIEWED
        if "meta-analysis" in evidence_source or "meta analysis" in evidence_source:
            return EvidenceLevel.META_ANALYSIS, 0.95, ClinicalReviewStatus.PEER_REVIEWED
        if "randomized" in evidence_source or "trial" in evidence_source or "rct" in evidence_source:
            return EvidenceLevel.RANDOMIZED_TRIAL, 0.91, ClinicalReviewStatus.PEER_REVIEWED
        if "qualitative study" in evidence_source or "cohort" in evidence_source or "observational" in evidence_source:
            return EvidenceLevel.OBSERVATIONAL_STUDY, 0.82, ClinicalReviewStatus.PEER_REVIEWED
        if organization and any(key in organization.lower() for key in ("government", "ministry", "department", "ncert", "cbse", "who", "unicef")):
            return EvidenceLevel.GOVERNMENT_POLICY, 0.88, ClinicalReviewStatus.GOVERNMENT_ISSUED
        if "consensus" in evidence_source or "expert" in evidence_source:
            return EvidenceLevel.EXPERT_CONSENSUS, 0.76, ClinicalReviewStatus.EDITORIAL_REVIEWED
        return EvidenceLevel.EDUCATIONAL_CONTENT, 0.58, ClinicalReviewStatus.UNREVIEWED


class PriorityAssigner:
    def assign(self, organization: str | None, *, document_url: str | None = None) -> PriorityLevel:
        candidate = " ".join(filter(None, [organization, document_url])).lower()
        for priority, patterns in PRIORITY_PATTERNS.items():
            if any(pattern in candidate for pattern in patterns):
                return priority
        return PriorityLevel.UNKNOWN


class DemographicClassifier:
    def classify_gender(self, text: str) -> GenderGroup:
        lowered = text.lower()
        if any(term in lowered for term in ("girls", "female adolescents", "young women")):
            return GenderGroup.FEMALE
        if any(term in lowered for term in ("boys", "male adolescents", "young men")):
            return GenderGroup.MALE
        return GenderGroup.GENERAL


class ReadingLevelClassifier:
    def classify(self, text: str) -> str:
        words = re.findall(r"\w+", text)
        sentences = max(1, len(re.findall(r"[.!?]", text)))
        average_sentence_length = len(words) / sentences
        if average_sentence_length < 14:
            return "easy"
        if average_sentence_length < 22:
            return "moderate"
        return "advanced"

