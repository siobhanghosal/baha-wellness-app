from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import EmailStr, field_validator

from baha_companion.common.sanitization import sanitize_optional_text
from baha_companion.common.schemas import APIModel


class UserRead(APIModel):
    id: UUID
    email: EmailStr
    full_name: str | None = None
    role: str
    is_active: bool
    is_superuser: bool
    email_verified_at: datetime | None = None
    last_login_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class UserUpdate(APIModel):
    full_name: str | None = None

    @field_validator("full_name", mode="before")
    @classmethod
    def sanitize_full_name(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)
