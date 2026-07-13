from __future__ import annotations

from typing import Any


class AppError(Exception):
    """Base application exception with API-safe metadata."""

    status_code = 400
    code = "application_error"

    def __init__(
        self,
        detail: str,
        *,
        code: str | None = None,
        status_code: int | None = None,
        extra: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(detail)
        self.detail = detail
        self.code = code or self.code
        self.status_code = status_code or self.status_code
        self.extra = extra or {}


class AuthenticationError(AppError):
    status_code = 401
    code = "authentication_error"


class AuthorizationError(AppError):
    status_code = 403
    code = "authorization_error"


class ValidationError(AppError):
    status_code = 422
    code = "validation_error"


class ConflictError(AppError):
    status_code = 409
    code = "conflict_error"


class NotFoundError(AppError):
    status_code = 404
    code = "not_found"


class RateLimitError(AppError):
    status_code = 429
    code = "rate_limit_exceeded"


class SecurityError(AppError):
    status_code = 400
    code = "security_error"
