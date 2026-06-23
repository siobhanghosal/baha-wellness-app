from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TaxonomyEntry:
    category: str
    condition: str
    topics: tuple[str, ...]
    severity_defaults: tuple[str, ...] = ("low", "moderate", "high", "emergency")


TAXONOMY: tuple[TaxonomyEntry, ...] = (
    TaxonomyEntry("Emotional", "Anxiety", ("worry", "fear", "panic", "avoidance")),
    TaxonomyEntry("Emotional", "Depression", ("low mood", "withdrawal", "hopelessness")),
    TaxonomyEntry("Emotional", "Loneliness", ("connection", "social support")),
    TaxonomyEntry("Emotional", "Stress", ("coping", "pressure", "relaxation")),
    TaxonomyEntry("Emotional", "Burnout", ("exhaustion", "school pressure")),
    TaxonomyEntry("Emotional", "Grief", ("loss", "bereavement")),
    TaxonomyEntry("Academic", "Exam Stress", ("exams", "study skills", "pressure")),
    TaxonomyEntry("Academic", "Performance Anxiety", ("performance", "evaluation")),
    TaxonomyEntry("Academic", "School Avoidance", ("attendance", "avoidance")),
    TaxonomyEntry("Social", "Bullying", ("peer harm", "school safety")),
    TaxonomyEntry("Social", "Cyberbullying", ("online harm", "digital safety")),
    TaxonomyEntry("Social", "Peer Pressure", ("decision making", "boundaries")),
    TaxonomyEntry("Social", "Social Isolation", ("belonging", "withdrawal")),
    TaxonomyEntry("Behavioral", "Anger", ("emotion regulation", "conflict")),
    TaxonomyEntry("Behavioral", "Aggression", ("harm", "discipline", "safety")),
    TaxonomyEntry("Behavioral", "Risk Taking", ("impulsivity", "safety")),
    TaxonomyEntry("Neurodevelopmental", "ADHD", ("attention", "impulsivity", "hyperactivity")),
    TaxonomyEntry("Neurodevelopmental", "Autism", ("communication", "sensory needs")),
    TaxonomyEntry("Neurodevelopmental", "Learning Difficulties", ("learning support", "screening")),
    TaxonomyEntry("Lifestyle", "Sleep Disorders", ("sleep hygiene", "fatigue")),
    TaxonomyEntry("Lifestyle", "Gaming Addiction", ("gaming", "digital wellbeing")),
    TaxonomyEntry("Lifestyle", "Internet Addiction", ("internet use", "screen time")),
    TaxonomyEntry("Lifestyle", "Physical Inactivity", ("movement", "exercise")),
    TaxonomyEntry("High Risk", "Self Harm", ("injury", "coping", "safety")),
    TaxonomyEntry("High Risk", "Suicide Risk", ("suicidal thoughts", "crisis", "emergency")),
    TaxonomyEntry("High Risk", "Substance Abuse", ("alcohol", "tobacco", "drugs")),
)

CONDITIONS = tuple(entry.condition for entry in TAXONOMY)


def find_conditions(text: str) -> list[str]:
    lowered = text.lower()
    matches: list[str] = []
    for entry in TAXONOMY:
        terms = (entry.condition, *entry.topics)
        if any(term.lower() in lowered for term in terms):
            matches.append(entry.condition)
    return sorted(set(matches))
