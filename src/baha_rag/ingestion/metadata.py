from __future__ import annotations

from datetime import date
from email.utils import parsedate_to_datetime

from baha_rag.schemas import Audience, ChunkMetadata, EvidenceLevel
from baha_rag.taxonomy import find_conditions


def parse_http_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return parsedate_to_datetime(value).date()
    except Exception:
        return None


def infer_metadata(
    *,
    text: str,
    source: str,
    organization: str,
    audience: Audience,
    country: str | None,
    evidence_level: EvidenceLevel,
    publication_date: date | None,
) -> ChunkMetadata:
    conditions = find_conditions(text)
    condition = conditions[0] if conditions else None
    lowered = text.lower()
    severity = "emergency" if any(term in lowered for term in ("suicide", "self-harm", "overdose")) else "unknown"
    return ChunkMetadata(
        condition=condition,
        topic=condition,
        subtopic=None,
        audience=audience,
        severity=severity,
        source=source,
        country=country,
        publication_date=publication_date,
        evidence_level=evidence_level,
        organization=organization,
        language="en",
    )
