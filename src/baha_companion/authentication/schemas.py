from __future__ import annotations

from datetime import datetime

from pydantic import EmailStr, Field, field_validator

from baha_companion.common.schemas import APIModel
from baha_companion.common.sanitization import normalize_email, sanitize_optional_text
from baha_companion.users.schemas import UserRead
from uuid import UUID


class RegisterRequest(APIModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=255)

    model_config = {
        "json_schema_extra": {
            "example": {
                "email": "student@example.com",
                "password": "strong-password-123",
                "full_name": "Student User",
            }
        }
    }

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email_value(cls, value: str) -> str:
        return normalize_email(value)

    @field_validator("full_name", mode="before")
    @classmethod
    def sanitize_full_name(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class LoginRequest(APIModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    device_name: str | None = Field(default=None, max_length=255)

    model_config = {
        "json_schema_extra": {
            "example": {
                "email": "student@example.com",
                "password": "strong-password-123",
                "device_name": "Chrome on MacBook Pro",
            }
        }
    }

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email_value(cls, value: str) -> str:
        return normalize_email(value)

    @field_validator("device_name", mode="before")
    @classmethod
    def sanitize_device_name(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class RefreshTokenRequest(APIModel):
    refresh_token: str | None = None
    device_name: str | None = Field(default=None, max_length=255)

    @field_validator("device_name", mode="before")
    @classmethod
    def sanitize_device_name(cls, value: str | None) -> str | None:
        return sanitize_optional_text(value)


class LogoutRequest(APIModel):
    refresh_token: str | None = None


class PasswordResetRequest(APIModel):
    email: EmailStr

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email_value(cls, value: str) -> str:
        return normalize_email(value)


class PasswordResetConfirmRequest(APIModel):
    token: str
    new_password: str = Field(min_length=8, max_length=128)


class EmailVerificationConfirmRequest(APIModel):
    token: str


class SessionRead(APIModel):
    id: UUID
    device_name: str | None = None
    user_agent: str | None = None
    ip_address: str | None = None
    created_at: datetime
    last_used_at: datetime | None = None
    expires_at: datetime
    idle_expires_at: datetime
    is_current: bool


class ActionAcceptedResponse(APIModel):
    detail: str
    debug_token: str | None = None


class TokenPairResponse(APIModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    access_token_expires_at: datetime
    refresh_token_expires_at: datetime
    csrf_token: str | None = None
    debug_email_verification_token: str | None = None
    session_id: UUID
    user: UserRead
