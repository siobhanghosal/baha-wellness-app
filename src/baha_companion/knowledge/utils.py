from __future__ import annotations

import json
import re
from datetime import date, datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


DATE_PATTERNS = (
    "%Y-%m-%d",
    "%Y/%m/%d",
    "%Y %b %d",
    "%Y %B %d",
    "%b %d, %Y",
    "%B %d, %Y",
    "%Y %b %d",
    "%Y %B %d",
    "%Y %m %d",
)


def parse_publication_date(value: str | date | datetime | None) -> date | None:
    if value is None:
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.date()

    cleaned = str(value).strip()
    if not cleaned:
        return None

    iso_candidate = cleaned.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(iso_candidate).date()
    except ValueError:
        pass

    simplified = re.sub(r"[,\s]+", " ", cleaned).strip()
    for pattern in DATE_PATTERNS:
        try:
            return datetime.strptime(simplified, pattern).date()
        except ValueError:
            continue

    year_match = re.search(r"\b(19|20)\d{2}\b", cleaned)
    if year_match:
        return date(int(year_match.group(0)), 1, 1)
    return None


def infer_organization_from_path(path: Path) -> str | None:
    try:
        raw_index = path.parts.index("raw")
    except ValueError:
        return None
    if raw_index + 1 >= len(path.parts):
        return None
    return path.parts[raw_index + 1].replace("-", " ").title()


def relative_source_path(path: Path, *, workspace_root: Path) -> str:
    resolved = path.resolve()
    root = workspace_root.resolve()
    try:
        return str(resolved.relative_to(root))
    except ValueError:
        return str(resolved)


def first_non_empty(*values: Any) -> Any:
    for value in values:
        if value not in (None, "", [], {}, ()):
            return value
    return None


def extract_domain(url: str | None) -> str | None:
    if not url:
        return None
    parsed = urlparse(url)
    return parsed.netloc.lower() or None


def coerce_json_text(value: Any) -> str:
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=True, default=str)

