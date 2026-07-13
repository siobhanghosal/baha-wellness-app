from __future__ import annotations

from datetime import timedelta
from uuid import uuid4

import pytest

from baha_companion.authentication.notifications import AuthenticationNotificationService
from baha_companion.authentication.repository import AuthenticationRepository
from baha_companion.authentication.schemas import LoginRequest, RefreshTokenRequest, RegisterRequest
from baha_companion.authentication.security import now_utc
from baha_companion.authentication.service import AuthenticationService
from baha_companion.common.exceptions import AuthenticationError, AuthorizationError, ConflictError
from baha_companion.users.repository import UserRepository


def build_auth_service(db_session, test_settings) -> tuple[AuthenticationService, UserRepository]:
    user_repository = UserRepository(db_session)
    service = AuthenticationService(
        settings=test_settings,
        auth_repository=AuthenticationRepository(db_session),
        user_repository=user_repository,
        notification_service=AuthenticationNotificationService(),
    )
    return service, user_repository


async def test_authentication_service_lifecycle(db_session, test_settings):
    service, user_repository = build_auth_service(db_session, test_settings)

    registration = await service.register(
        RegisterRequest(
            email="service-auth@example.com",
            password="strong-password-123",
            full_name="Service Auth",
        ),
        user_agent="pytest",
        ip_address="127.0.0.1",
        device_name="Desktop",
    )
    assert registration.session_id
    assert registration.debug_email_verification_token

    user = await user_repository.get_by_email("service-auth@example.com")
    assert user is not None

    sessions = await service.list_sessions(user)
    assert len(sessions) == 1

    login = await service.login(
        LoginRequest(
            email="service-auth@example.com",
            password="strong-password-123",
            device_name="Phone",
        ),
        user_agent="pytest",
        ip_address="127.0.0.2",
    )
    assert login.session_id != registration.session_id

    refreshed = await service.refresh(
        RefreshTokenRequest(device_name="Refreshed Browser"),
        refresh_token=login.refresh_token,
        user_agent="pytest",
        ip_address="127.0.0.3",
    )
    assert refreshed.session_id != login.session_id

    await service.logout(refreshed.refresh_token)

    verification = await service.request_email_verification(
        user=user,
        user_agent="pytest",
        ip_address="127.0.0.1",
    )
    assert verification.debug_token
    await service.verify_email(token=verification.debug_token)

    password_reset = await service.request_password_reset(
        email=user.email,
        user_agent="pytest",
        ip_address="127.0.0.1",
    )
    assert password_reset.debug_token
    await service.confirm_password_reset(
        token=password_reset.debug_token,
        new_password="new-strong-password-456",
    )

    await service.logout_all_devices(user)


async def test_authentication_service_guard_paths(db_session, test_settings):
    service, user_repository = build_auth_service(db_session, test_settings)

    await service.register(
        RegisterRequest(
            email="guard@example.com",
            password="strong-password-123",
            full_name="Guard User",
        ),
        user_agent="pytest",
        ip_address="127.0.0.1",
    )

    with pytest.raises(ConflictError):
        await service.register(
            RegisterRequest(
                email="guard@example.com",
                password="strong-password-123",
                full_name="Guard User",
            ),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    with pytest.raises(AuthenticationError):
        await service.login(
            LoginRequest(email="guard@example.com", password="wrong-password-123"),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    with pytest.raises(AuthenticationError):
        await service.login(
            LoginRequest(email="missing@example.com", password="strong-password-123"),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    user = await user_repository.get_by_email("guard@example.com")
    assert user is not None

    user.locked_until = now_utc() + timedelta(minutes=5)
    await db_session.flush()
    with pytest.raises(AuthenticationError):
        await service.login(
            LoginRequest(email="guard@example.com", password="strong-password-123"),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    user.locked_until = None
    user.is_active = False
    await db_session.flush()
    with pytest.raises(AuthenticationError):
        await service.login(
            LoginRequest(email="guard@example.com", password="strong-password-123"),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    user.is_active = True
    test_settings.require_email_verification_for_login = True
    await db_session.flush()
    with pytest.raises(AuthorizationError):
        await service.login(
            LoginRequest(email="guard@example.com", password="strong-password-123"),
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    with pytest.raises(AuthenticationError):
        await service.refresh(
            RefreshTokenRequest(),
            refresh_token="invalid-refresh-token",
            user_agent="pytest",
            ip_address="127.0.0.1",
        )

    with pytest.raises(AuthenticationError):
        await service.revoke_session(user=user, session_id=uuid4())

    with pytest.raises(AuthenticationError):
        await service.confirm_password_reset(token="invalid-token", new_password="new-strong-password-456")

    with pytest.raises(AuthenticationError):
        await service.verify_email(token="invalid-token")

