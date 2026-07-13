from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import jwt
from jwt import InvalidTokenError
from passlib.context import CryptContext

from baha_companion.common.exceptions import AuthenticationError
from baha_companion.config import AppSettings


password_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


def now_utc() -> datetime:
    return datetime.now(UTC)


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_context.verify(password, password_hash)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_access_token(*, user_id: UUID | str, settings: AppSettings) -> tuple[str, datetime]:
    expires_at = now_utc() + timedelta(minutes=settings.access_token_ttl_minutes)
    payload = {
        "sub": str(user_id),
        "type": "access",
        "iss": settings.auth_issuer,
        "aud": settings.auth_audience,
        "iat": int(now_utc().timestamp()),
        "exp": expires_at,
    }
    return jwt.encode(payload, settings.auth_secret_key, algorithm=settings.auth_algorithm), expires_at


def create_refresh_token(*, user_id: UUID | str, settings: AppSettings) -> tuple[str, datetime, datetime, str]:
    issued_at = now_utc()
    expires_at = now_utc() + timedelta(days=settings.refresh_token_ttl_days)
    idle_expires_at = issued_at + timedelta(minutes=settings.refresh_token_idle_minutes)
    jti = str(uuid4())
    payload = {
        "sub": str(user_id),
        "jti": jti,
        "type": "refresh",
        "iss": settings.auth_issuer,
        "aud": settings.auth_audience,
        "iat": int(issued_at.timestamp()),
        "exp": expires_at,
    }
    return (
        jwt.encode(payload, settings.auth_secret_key, algorithm=settings.auth_algorithm),
        expires_at,
        idle_expires_at,
        jti,
    )


def decode_token(*, token: str, settings: AppSettings, expected_type: str) -> dict:
    try:
        payload = jwt.decode(
            token,
            settings.auth_secret_key,
            algorithms=[settings.auth_algorithm],
            audience=settings.auth_audience,
            issuer=settings.auth_issuer,
            options={"require": ["sub", "type", "exp", "iat", "iss", "aud"]},
        )
    except InvalidTokenError as exc:
        raise AuthenticationError("Invalid or expired token.") from exc

    if payload.get("type") != expected_type:
        raise AuthenticationError("Token type is invalid.")
    return payload


def generate_opaque_token() -> str:
    return secrets.token_urlsafe(48)
