from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.repository import AcquisitionRepository
from baha_rag.acquisition.topics import DISCOVERY_TOPICS


AHA = "IAP Adolescent Health Academy"
CAMPAIGN_ORGANIZATIONS = (AHA, "NIMHANS")

SOURCE_WEIGHTS: dict[str, float] = {
    "Bangalore Adolescent Health Academy": 1.00,
    AHA: 0.95,
    "Indian Academy of Pediatrics": 0.95,
    "NIMHANS": 0.90,
    "WHO": 0.85,
    "UNICEF": 0.80,
    "UNESCO": 0.80,
    "PubMed": 0.75,
    "Europe PMC": 0.75,
    "Semantic Scholar": 0.75,
    "NICE": 0.80,
    "NIMH": 0.80,
    "NIH": 0.80,
    "CDC": 0.80,
    "NHS": 0.80,
    "SAMHSA": 0.80,
    "American Academy of Pediatrics": 0.80,
    "CBSE": 0.80,
    "NCPCR": 0.80,
    "CASEL": 0.80,
    "Common Sense Media": 0.80,
    "Internet Matters": 0.78,
    "eSafety Commissioner": 0.80,
    "Attendance Works": 0.78,
    "Education Endowment Foundation": 0.80,
    "National Center for School Mental Health": 0.80,
    "American School Counselor Association": 0.78,
    "National Association of School Psychologists": 0.80,
    "OECD": 0.80,
    "World Economic Forum": 0.75,
    "SCERT Karnataka": 0.80,
    "National Institute of Open Schooling": 0.80,
}

AHA_TARGET_TERMS = (
    "aha publication",
    "adolescent today",
    "indian journal of adolescent medicine",
    "consensus guideline",
    "manual",
    "mission kishore uday",
    "mission kishor uday",
    "mission school uday",
    "awesome aya",
    "knowledge bank",
    "webinar",
    "t-teach",
    "teacher",
    "adolescent handout",
    "parent",
    "drug abuse",
    "school",
    "resource material",
    "presentation",
)

NIMHANS_TARGET_TERMS = (
    "mental health",
    "school mental health",
    "adolescent",
    "training manual",
    "manual",
    "guideline",
    "toolkit",
    "parent education",
    "teacher education",
    "research publication",
    "publication",
    "report",
    "poster",
    "resource",
)

RESTRICTED_PATH_TERMS = (
    "login",
    "member-login",
    "member-registration",
    "registration",
    "sign-in",
    "signin",
    "account",
    "password",
    "/admin",
    "wp-admin",
    "/cdn-cgi/",
)

EXPECTED_RESOURCE_TYPES = (
    "html",
    "pdf",
    "powerpoint",
    "document",
    "spreadsheet",
    "zip_archive",
)

EXPECTED_AUDIENCES = ("parent", "teacher", "counselor", "adolescent", "research", "clinical")


def source_weight(organization: str) -> float:
    return SOURCE_WEIGHTS.get(organization, 0.70)


def is_restricted_url(url: str) -> bool:
    lowered = url.lower()
    return any(term in lowered for term in RESTRICTED_PATH_TERMS)


def is_campaign_relevant(text: str, organization: str) -> bool:
    lowered = text.lower()
    terms = AHA_TARGET_TERMS if organization == AHA else NIMHANS_TARGET_TERMS
    return any(term in lowered for term in terms)


def classify_resource(text: str) -> tuple[str, str]:
    lowered = text.lower()
    if any(term in lowered for term in ("parent", "caregiver", "parenteening", "family guide")):
        return "parent", "Parent Resource"
    if any(term in lowered for term in ("teacher", "classroom", "school module", "t-teach")):
        return "teacher", "Teacher Resource"
    if any(term in lowered for term in ("counselor", "counsellor", "counselling", "counseling")):
        return "counselor", "Counselor Resource"
    if any(
        term in lowered
        for term in ("student guide", "for students", "adolescent handout", "for adolescents", "awesome aya", "youth")
    ):
        return "adolescent", "Adolescent Resource"
    if any(term in lowered for term in ("whole school", "school framework", "district guide", "school support")):
        return "school", "School Resource"
    if any(term in lowered for term in ("journal", "research", "study", "publication", "report")):
        return "research", "Research Resource"
    if any(term in lowered for term in ("consensus", "clinical", "guideline", "protocol")):
        return "clinical", "Clinical Resource"
    return "general", "General Resource"


class PriorityCampaignService:
    def __init__(self, session: AsyncSession) -> None:
        self.repository = AcquisitionRepository(session)

    async def report(self) -> dict[str, Any]:
        return await self.repository.priority_campaign_report(
            organizations=CAMPAIGN_ORGANIZATIONS,
            expected_topics=list(DISCOVERY_TOPICS),
            expected_resource_types=list(EXPECTED_RESOURCE_TYPES),
        )
