from __future__ import annotations

from uuid import UUID

from fastapi import Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.config import Settings, get_settings
from baha_rag.db.mobile_repository import MobileAppRepository
from baha_rag.db.session import get_session
from baha_rag.identity import ActorContext


class TokenIdentity:
    def __init__(self, subject: str, email: str | None = None) -> None:
        self.subject = subject
        self.email = email


def _parse_user_id(raw_user_id: str) -> UUID:
    try:
        return UUID(raw_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid X-BAHA-User-Id header") from exc


async def get_actor_context(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
    authorization: str | None = Header(default=None),
    x_baha_user_id: str | None = Header(default=None),
    x_baha_external_auth_id: str | None = Header(default=None),
) -> ActorContext:
    token_identity = await _identity_from_authorization(authorization, settings)

    if not x_baha_user_id and not x_baha_external_auth_id and token_identity is None:
        raise HTTPException(
            status_code=401,
            detail="Provide a valid bearer token or development identity headers for mobile endpoints",
        )

    repository = MobileAppRepository(session)
    actor = None
    if x_baha_user_id:
        actor = await repository.get_actor_context_by_user_id(_parse_user_id(x_baha_user_id))
    elif x_baha_external_auth_id:
        actor = await repository.get_actor_context_by_external_auth_id(x_baha_external_auth_id)
    elif token_identity:
        actor = await repository.get_actor_context_by_external_auth_id(token_identity.subject)
        if actor is None and token_identity.email:
            actor = await repository.get_actor_context_by_email(token_identity.email)

    if actor is None:
        raise HTTPException(status_code=401, detail="No active BAHA user found for the provided identity")
    return actor


async def _identity_from_authorization(
    authorization: str | None,
    settings: Settings,
) -> TokenIdentity | None:
    if not authorization:
        return None
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Authorization header must use Bearer token format")

    try:
        import jwt
    except ModuleNotFoundError as exc:
        raise HTTPException(status_code=500, detail="JWT verification dependency is not installed") from exc

    decode_kwargs = {
        "algorithms": ["RS256", "HS256"],
    }
    if settings.auth_audience:
        decode_kwargs["audience"] = settings.auth_audience
    else:
        decode_kwargs["options"] = {"verify_aud": False}
    if settings.auth_issuer:
        decode_kwargs["issuer"] = settings.auth_issuer

    try:
        if settings.auth_jwks_url:
            signing_key = jwt.PyJWKClient(settings.auth_jwks_url).get_signing_key_from_jwt(token).key
            payload = jwt.decode(token, signing_key, **decode_kwargs)
        elif settings.auth_jwt_secret:
            payload = jwt.decode(token, settings.auth_jwt_secret, **decode_kwargs)
        elif settings.allow_dev_identity_headers:
            return None
        else:
            raise HTTPException(status_code=500, detail="Bearer token verification is not configured")
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Bearer token verification failed") from exc

    subject = payload.get("sub")
    if not subject:
        raise HTTPException(status_code=401, detail="Bearer token is missing a subject claim")
    email = payload.get("email")
    return TokenIdentity(subject=str(subject), email=str(email) if email else None)
