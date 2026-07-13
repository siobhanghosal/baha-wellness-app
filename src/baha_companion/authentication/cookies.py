from __future__ import annotations

import secrets

from fastapi import Request, Response

from baha_companion.authentication.schemas import TokenPairResponse
from baha_companion.common.exceptions import SecurityError
from baha_companion.config import AppSettings


def generate_csrf_token() -> str:
    return secrets.token_urlsafe(32)


def apply_auth_cookies(response: Response, *, settings: AppSettings, tokens: TokenPairResponse) -> str | None:
    if not settings.enable_cookie_auth:
        return None

    csrf_token = generate_csrf_token()
    response.set_cookie(
        settings.refresh_cookie_name,
        tokens.refresh_token,
        max_age=settings.refresh_token_ttl_days * 24 * 60 * 60,
        httponly=True,
        secure=settings.secure_cookies,
        samesite=settings.cookie_samesite,
        domain=settings.cookie_domain,
        path=settings.cookie_path,
    )
    response.set_cookie(
        settings.csrf_cookie_name,
        csrf_token,
        max_age=settings.refresh_token_ttl_days * 24 * 60 * 60,
        httponly=False,
        secure=settings.secure_cookies,
        samesite=settings.cookie_samesite,
        domain=settings.cookie_domain,
        path=settings.cookie_path,
    )
    return csrf_token


def clear_auth_cookies(response: Response, settings: AppSettings) -> None:
    response.delete_cookie(settings.refresh_cookie_name, domain=settings.cookie_domain, path=settings.cookie_path)
    response.delete_cookie(settings.csrf_cookie_name, domain=settings.cookie_domain, path=settings.cookie_path)


def resolve_refresh_token(request: Request, explicit_token: str | None, settings: AppSettings) -> str:
    if explicit_token:
        return explicit_token
    token = request.cookies.get(settings.refresh_cookie_name)
    if token is None:
        raise SecurityError("Refresh token is required.")
    validate_csrf(request, settings)
    return token


def validate_csrf(request: Request, settings: AppSettings) -> None:
    cookie_token = request.cookies.get(settings.csrf_cookie_name)
    if cookie_token is None:
        return
    header_token = request.headers.get(settings.csrf_header_name)
    if not header_token or header_token != cookie_token:
        raise SecurityError("CSRF token validation failed.")
