from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from baha_companion.api.dependencies import get_user_service
from baha_companion.authentication.security import decode_token
from baha_companion.common.exceptions import AuthenticationError
from baha_companion.config import AppSettings, get_settings
from baha_companion.middleware.request_context import set_user_id
from baha_companion.users.models import User
from baha_companion.users.service import UserService


bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    settings: Annotated[AppSettings, Depends(get_settings)],
    user_service: Annotated[UserService, Depends(get_user_service)],
) -> User:
    if credentials is None:
        raise AuthenticationError("Not authenticated.")

    try:
        payload = decode_token(
            token=credentials.credentials,
            settings=settings,
            expected_type="access",
        )
        user = await user_service.get_user(UUID(payload["sub"]))
    except AuthenticationError as exc:
        raise AuthenticationError(str(exc)) from exc
    except Exception as exc:
        raise AuthenticationError("Authentication failed.") from exc

    if not user.is_active:
        raise AuthenticationError("User account is inactive.")
    set_user_id(str(user.id))
    return user
