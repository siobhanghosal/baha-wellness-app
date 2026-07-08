from __future__ import annotations

from dataclasses import dataclass


DIAGNOSTIC_TERMS = (
    "diagnose me",
    "diagnosis",
    "do i have",
    "does my child have",
    "is this depression",
    "is this adhd",
)

EMERGENCY_TERMS = (
    "suicide",
    "kill myself",
    "end my life",
    "self harm",
    "self-harm",
    "overdose",
    "can't stay safe",
    "cannot stay safe",
    "hurt myself",
    "hurt someone",
)

SAFETY_NOTE = (
    "This information is educational and is not a diagnosis or treatment plan. "
    "For personal concerns, consult a qualified health professional. If there is "
    "immediate danger, self-harm, suicidal thoughts, overdose, or risk of harm to "
    "someone else, contact local emergency services or an appropriate crisis service now."
)


@dataclass(frozen=True)
class SafetyAssessment:
    diagnostic_request: bool
    emergency_indicators: bool
    guidance: str


def assess_safety(text: str) -> SafetyAssessment:
    lowered = text.lower()
    diagnostic_request = any(term in lowered for term in DIAGNOSTIC_TERMS)
    emergency_indicators = any(term in lowered for term in EMERGENCY_TERMS)
    if emergency_indicators:
        guidance = (
            "Emergency indicators are present. Provide immediate safety guidance, "
            "encourage contacting emergency services or crisis support, and avoid risk prediction."
        )
    elif diagnostic_request:
        guidance = (
            "The user may be asking for diagnosis. Provide educational information, "
            "encourage professional assessment, and avoid diagnostic conclusions."
        )
    else:
        guidance = "Provide educational, evidence-cited wellbeing information."
    return SafetyAssessment(diagnostic_request, emergency_indicators, guidance)


def safe_join_evidence(points: list[str], fallback: str) -> str:
    clean = [point.strip() for point in points if point and point.strip()]
    return " ".join(clean) if clean else fallback
