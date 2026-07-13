from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Request, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.api.dependencies import get_authentication_service
from baha_companion.authentication.cookies import apply_auth_cookies, clear_auth_cookies, resolve_refresh_token
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.authentication.schemas import (
    ActionAcceptedResponse,
    EmailVerificationConfirmRequest,
    LoginRequest,
    LogoutRequest,
    PasswordResetConfirmRequest,
    PasswordResetRequest,
    RefreshTokenRequest,
    RegisterRequest,
    SessionRead,
    TokenPairResponse,
)
from baha_companion.authentication.service import AuthenticationService
from baha_companion.common.exceptions import AppError
from baha_companion.config import AppSettings, get_settings
from baha_companion.database.session import get_session
from baha_companion.middleware.rate_limit import settings_rate_limit_dependency
from baha_companion.users.models import User

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenPairResponse, status_code=status.HTTP_201_CREATED)
async def register(
    request: RegisterRequest,
    response: Response,
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="register",
                attempts_setting="auth_rate_limit_attempts",
                window_setting="auth_rate_limit_window_seconds",
            )
        ),
    ],
) -> TokenPairResponse:
    auth_response = await service.register(
        request,
        user_agent=http_request.headers.get("User-Agent"),
        ip_address=http_request.client.host if http_request.client else None,
    )
    auth_response.csrf_token = apply_auth_cookies(response, settings=settings, tokens=auth_response)
    await session.commit()
    return auth_response


@router.post("/login", response_model=TokenPairResponse)
async def login(
    request: LoginRequest,
    response: Response,
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="login",
                attempts_setting="auth_rate_limit_attempts",
                window_setting="auth_rate_limit_window_seconds",
            )
        ),
    ],
) -> TokenPairResponse:
    try:
        auth_response = await service.login(
            request,
            user_agent=http_request.headers.get("User-Agent"),
            ip_address=http_request.client.host if http_request.client else None,
        )
    except AppError:
        await session.commit()
        raise
    auth_response.csrf_token = apply_auth_cookies(response, settings=settings, tokens=auth_response)
    await session.commit()
    return auth_response


@router.post("/refresh", response_model=TokenPairResponse)
async def refresh_tokens(
    request: RefreshTokenRequest,
    response: Response,
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
) -> TokenPairResponse:
    refresh_token = resolve_refresh_token(http_request, request.refresh_token, settings)
    try:
        auth_response = await service.refresh(
            request,
            refresh_token=refresh_token,
            user_agent=http_request.headers.get("User-Agent"),
            ip_address=http_request.client.host if http_request.client else None,
        )
    except AppError:
        await session.commit()
        raise
    auth_response.csrf_token = apply_auth_cookies(response, settings=settings, tokens=auth_response)
    await session.commit()
    return auth_response


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    request: LogoutRequest,
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
) -> Response:
    refresh_token = resolve_refresh_token(http_request, request.refresh_token, settings)
    await service.logout(refresh_token)
    cleared_response = Response(status_code=204)
    clear_auth_cookies(cleared_response, settings)
    await session.commit()
    return cleared_response


@router.post("/logout-all", status_code=status.HTTP_204_NO_CONTENT)
async def logout_all_devices(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
) -> Response:
    await service.logout_all_devices(current_user)
    cleared_response = Response(status_code=204)
    clear_auth_cookies(cleared_response, settings)
    await session.commit()
    return cleared_response


@router.get("/sessions", response_model=list[SessionRead])
async def list_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
) -> list[SessionRead]:
    return await service.list_sessions(current_user)


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_session(
    session_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    settings: Annotated[AppSettings, Depends(get_settings)],
) -> Response:
    await service.revoke_session(user=current_user, session_id=session_id)
    cleared_response = Response(status_code=204)
    clear_auth_cookies(cleared_response, settings)
    await session.commit()
    return cleared_response


@router.post("/password-reset/request", response_model=ActionAcceptedResponse, status_code=status.HTTP_202_ACCEPTED)
async def request_password_reset(
    request: PasswordResetRequest,
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
    _: Annotated[
        None,
        Depends(
            settings_rate_limit_dependency(
                name="password_reset",
                attempts_setting="auth_rate_limit_attempts",
                window_setting="auth_rate_limit_window_seconds",
            )
        ),
    ],
) -> ActionAcceptedResponse:
    response = await service.request_password_reset(
        email=request.email,
        user_agent=http_request.headers.get("User-Agent"),
        ip_address=http_request.client.host if http_request.client else None,
    )
    await session.commit()
    return response


@router.post("/password-reset/confirm", status_code=status.HTTP_204_NO_CONTENT)
async def confirm_password_reset(
    request: PasswordResetConfirmRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
) -> Response:
    await service.confirm_password_reset(token=request.token, new_password=request.new_password)
    await session.commit()
    return Response(status_code=204)


@router.post("/email-verification/request", response_model=ActionAcceptedResponse, status_code=status.HTTP_202_ACCEPTED)
async def request_email_verification(
    http_request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
) -> ActionAcceptedResponse:
    response = await service.request_email_verification(
        user=current_user,
        user_agent=http_request.headers.get("User-Agent"),
        ip_address=http_request.client.host if http_request.client else None,
    )
    await session.commit()
    return response


@router.post("/email-verification/confirm", status_code=status.HTTP_204_NO_CONTENT)
async def confirm_email_verification(
    request: EmailVerificationConfirmRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
    service: Annotated[AuthenticationService, Depends(get_authentication_service)],
) -> Response:
    await service.verify_email(token=request.token)
    await session.commit()
    return Response(status_code=204)
