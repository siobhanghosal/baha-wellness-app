from __future__ import annotations

import re


CONTROL_CHARACTER_PATTERN = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]")
WHITESPACE_PATTERN = re.compile(r"\s+")


def strip_control_characters(value: str) -> str:
    return CONTROL_CHARACTER_PATTERN.sub("", value)


def normalize_whitespace(value: str) -> str:
    return WHITESPACE_PATTERN.sub(" ", value).strip()


def sanitize_text(value: str) -> str:
    return normalize_whitespace(strip_control_characters(value))


def sanitize_optional_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = sanitize_text(value)
    return cleaned or None


def normalize_email(value: str) -> str:
    return sanitize_text(value).lower()
