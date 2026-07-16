from __future__ import annotations

from base64 import b64decode, b64encode
from dataclasses import dataclass
import hashlib
import hmac
import secrets
from uuid import UUID

from fastapi import Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.config import Settings, get_settings
from baha_rag.db.mobile_repository import MobileAppRepository
from baha_rag.db.session import get_session
from baha_rag.identity import ActorContext


@dataclass(slots=True)
class TokenIdentity:
    subject: str
    email: str | None = None
    password: str | None = None
    is_dev_identity: bool = False


_DEV_PASSWORD_ITERATIONS = 200_000


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
    x_baha_dev_password: str | None = Header(default=None),
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
        _require_dev_password_for_actor(
            actor=actor,
            password=x_baha_dev_password,
        )
    elif token_identity:
        actor = await repository.get_actor_context_by_external_auth_id(token_identity.subject)
        if actor is None and token_identity.email:
            active_user_count = await repository.count_active_users_by_email(token_identity.email)
            if active_user_count > 1:
                raise HTTPException(
                    status_code=409,
                    detail="Multiple active BAHA users share this email; manual identity linking is required",
                )
            actor = await repository.get_actor_context_by_email(token_identity.email)
            if actor is not None:
                bound = await repository.bind_external_auth_id(
                    user_id=actor.user_id,
                    external_auth_id=token_identity.subject,
                )
                if not bound:
                    raise HTTPException(
                        status_code=409,
                        detail="Unable to link bearer token identity to the matched BAHA user",
                    )
                actor = await repository.get_actor_context_by_user_id(actor.user_id)

    if actor is None:
        raise HTTPException(status_code=401, detail="No active BAHA user found for the provided identity")
    return actor


async def get_provisioning_identity(
    settings: Settings = Depends(get_settings),
    authorization: str | None = Header(default=None),
    x_baha_external_auth_id: str | None = Header(default=None),
    x_baha_auth_email: str | None = Header(default=None),
    x_baha_dev_password: str | None = Header(default=None),
) -> TokenIdentity:
    token_identity = await _identity_from_authorization(authorization, settings)
    if token_identity is not None:
        return token_identity
    if settings.allow_dev_identity_headers and x_baha_external_auth_id:
        if not x_baha_dev_password or not x_baha_dev_password.strip():
            raise HTTPException(
                status_code=401,
                detail="Password is required for development identity sign-in",
            )
        return TokenIdentity(
            subject=x_baha_external_auth_id,
            email=x_baha_auth_email,
            password=x_baha_dev_password,
            is_dev_identity=True,
        )
    raise HTTPException(
        status_code=401,
        detail="Provide a valid bearer token or a development external auth identity for auth bootstrap routes",
    )


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


def build_dev_password_metadata(password: str) -> dict[str, object]:
    salt = secrets.token_bytes(16)
    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        _DEV_PASSWORD_ITERATIONS,
    )
    return {
        "dev_auth": {
            "mode": "id_password",
            "salt_b64": b64encode(salt).decode("ascii"),
            "password_hash_b64": b64encode(password_hash).decode("ascii"),
            "iterations": _DEV_PASSWORD_ITERATIONS,
        }
    }


def verify_dev_password(password: str | None, user_metadata: dict | None) -> bool:
    if password is None or not password.strip():
        return False
    metadata = user_metadata or {}
    dev_auth = metadata.get("dev_auth")
    if not isinstance(dev_auth, dict):
        return False
    salt_b64 = dev_auth.get("salt_b64")
    password_hash_b64 = dev_auth.get("password_hash_b64")
    iterations = dev_auth.get("iterations", _DEV_PASSWORD_ITERATIONS)
    if not isinstance(salt_b64, str) or not isinstance(password_hash_b64, str):
        return False
    try:
        salt = b64decode(salt_b64)
        expected = b64decode(password_hash_b64)
        rounds = int(iterations)
    except Exception:
        return False
    candidate = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        rounds,
    )
    return hmac.compare_digest(candidate, expected)


def _require_dev_password_for_actor(
    *,
    actor: ActorContext | None,
    password: str | None,
) -> None:
    if actor is None:
        return
    if not verify_dev_password(password, actor.user_metadata):
        raise HTTPException(status_code=401, detail="Incorrect sign-in ID or password")
