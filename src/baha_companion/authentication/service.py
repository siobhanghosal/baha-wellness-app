from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

from baha_companion.authentication.notifications import AuthenticationNotificationService
from baha_companion.authentication.repository import AuthenticationRepository
from baha_companion.authentication.schemas import (
    ActionAcceptedResponse,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    SessionRead,
    TokenPairResponse,
)
from baha_companion.authentication.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_opaque_token,
    hash_password,
    hash_token,
    now_utc,
    verify_password,
)
from baha_companion.common.exceptions import AuthenticationError, AuthorizationError, ConflictError
from baha_companion.config import AppSettings
from baha_companion.users.models import User
from baha_companion.users.repository import UserRepository
from baha_companion.users.schemas import UserRead


class AuthenticationService:
    def __init__(
        self,
        *,
        settings: AppSettings,
        auth_repository: AuthenticationRepository,
        user_repository: UserRepository,
        notification_service: AuthenticationNotificationService,
    ) -> None:
        self.settings = settings
        self.auth_repository = auth_repository
        self.user_repository = user_repository
        self.notification_service = notification_service

    async def register(
        self,
        request: RegisterRequest,
        *,
        user_agent: str | None,
        ip_address: str | None,
        device_name: str | None = None,
    ) -> TokenPairResponse:
        existing_user = await self.user_repository.get_by_email(request.email)
        if existing_user is not None:
            raise ConflictError("A user with this email already exists.")

        user = await self.user_repository.create(
            email=request.email,
            full_name=request.full_name,
            password_hash=hash_password(request.password),
        )
        verification_token = await self._create_email_verification_token(
            user,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        response = await self._issue_token_pair(
            user,
            user_agent=user_agent,
            ip_address=ip_address,
            device_name=device_name,
        )
        if self.settings.expose_debug_tokens:
            response.debug_email_verification_token = verification_token
        return response

    async def login(
        self,
        request: LoginRequest,
        *,
        user_agent: str | None,
        ip_address: str | None,
    ) -> TokenPairResponse:
        user = await self.user_repository.get_by_email(request.email)
        if user is None:
            await self._record_failed_login(email=request.email, user=None, ip_address=ip_address, user_agent=user_agent)
            raise AuthenticationError("Email or password is incorrect.")

        if user.locked_until and self._as_utc(user.locked_until) > now_utc():
            raise AuthenticationError("Account is temporarily locked due to repeated failed login attempts.")

        if not verify_password(request.password, user.password_hash):
            await self._record_failed_login(email=request.email, user=user, ip_address=ip_address, user_agent=user_agent)
            raise AuthenticationError("Email or password is incorrect.")

        if self.settings.require_email_verification_for_login and user.email_verified_at is None:
            raise AuthorizationError("Email verification is required before login.")

        if not user.is_active:
            raise AuthenticationError("User account is inactive.")

        await self.user_repository.reset_failed_logins(user)
        await self.auth_repository.create_login_attempt(
            user_id=user.id,
            email=user.email,
            ip_address=ip_address,
            user_agent=user_agent,
            successful=True,
            attempted_at=now_utc(),
        )
        return await self._issue_token_pair(
            user,
            user_agent=user_agent,
            ip_address=ip_address,
            device_name=request.device_name,
        )

    async def refresh(
        self,
        request: RefreshTokenRequest,
        *,
        refresh_token: str,
        user_agent: str | None,
        ip_address: str | None,
    ) -> TokenPairResponse:
        payload = decode_token(token=refresh_token, settings=self.settings, expected_type="refresh")
        stored_token = await self.auth_repository.get_refresh_token_by_jti(payload["jti"], include_deleted=True)
        if stored_token is None:
            raise AuthenticationError("Refresh token is not recognized.")
        if stored_token.revoked_at is not None:
            await self.auth_repository.revoke_all_user_sessions(
                user_id=stored_token.user_id,
                when=now_utc(),
                reason="refresh_token_reuse_detected",
            )
            raise AuthenticationError("Refresh token reuse detected.")
        if stored_token.token_hash != hash_token(refresh_token):
            raise AuthenticationError("Refresh token is invalid.")
        current_time = now_utc()
        if self._as_utc(stored_token.expires_at) <= current_time or self._as_utc(stored_token.idle_expires_at) <= current_time:
            await self.auth_repository.revoke_refresh_token(stored_token, when=current_time, reason="expired")
            raise AuthenticationError("Refresh token has expired.")

        user = await self.user_repository.get_by_id(UUID(payload["sub"]))
        if user is None or not user.is_active:
            raise AuthenticationError("User account is inactive.")

        await self.auth_repository.touch_refresh_token(
            stored_token,
            when=current_time,
            idle_expires_at=current_time + timedelta(minutes=self.settings.refresh_token_idle_minutes),
            ip_address=ip_address,
            user_agent=user_agent,
        )
        await self.auth_repository.revoke_refresh_token(
            stored_token,
            when=current_time,
            reason="rotated",
        )
        return await self._issue_token_pair(
            user,
            user_agent=user_agent,
            ip_address=ip_address,
            device_name=request.device_name or stored_token.device_name,
        )

    async def logout(self, refresh_token: str) -> None:
        payload = decode_token(token=refresh_token, settings=self.settings, expected_type="refresh")
        stored_token = await self.auth_repository.get_refresh_token_by_jti(payload["jti"], include_deleted=True)
        if stored_token is None or stored_token.revoked_at is not None:
            return
        await self.auth_repository.revoke_refresh_token(stored_token, when=now_utc(), reason="logout")

    async def logout_all_devices(self, user: User) -> None:
        await self.auth_repository.revoke_all_user_sessions(
            user_id=user.id,
            when=now_utc(),
            reason="logout_all_devices",
        )

    async def list_sessions(self, user: User) -> list[SessionRead]:
        tokens = await self.auth_repository.list_active_sessions(user_id=user.id)
        return [SessionRead.model_validate(token) for token in tokens]

    async def revoke_session(self, *, user: User, session_id: UUID) -> None:
        tokens = await self.auth_repository.list_active_sessions(user_id=user.id)
        token = next((item for item in tokens if item.id == session_id), None)
        if token is None:
            raise AuthenticationError("Session not found.")
        await self.auth_repository.revoke_refresh_token(token, when=now_utc(), reason="session_revoked")

    async def request_password_reset(
        self,
        *,
        email: str,
        user_agent: str | None,
        ip_address: str | None,
    ) -> ActionAcceptedResponse:
        user = await self.user_repository.get_by_email(email)
        debug_token = None
        if user is not None and user.is_active:
            token_value = generate_opaque_token()
            await self.auth_repository.invalidate_password_reset_tokens(user_id=user.id, when=now_utc())
            await self.auth_repository.create_password_reset_token(
                user_id=user.id,
                token_hash=hash_token(token_value),
                expires_at=now_utc() + timedelta(minutes=self.settings.password_reset_token_ttl_minutes),
                user_agent=user_agent,
                ip_address=ip_address,
            )
            await self.notification_service.send_password_reset(user=user, token=token_value)
            debug_token = token_value if self.settings.expose_debug_tokens else None
        return ActionAcceptedResponse(detail="If the account exists, reset instructions have been prepared.", debug_token=debug_token)

    async def confirm_password_reset(self, *, token: str, new_password: str) -> None:
        hashed_token = hash_token(token)
        record = await self.auth_repository.get_password_reset_token(hashed_token)
        current_time = now_utc()
        if record is None or record.used_at is not None or self._as_utc(record.expires_at) <= current_time:
            raise AuthenticationError("Password reset token is invalid or expired.")
        user = await self.user_repository.get_by_id(record.user_id)
        if user is None:
            raise AuthenticationError("Password reset token is invalid.")
        await self.auth_repository.invalidate_password_reset_tokens(user_id=user.id, when=current_time)
        await self.user_repository.set_password(user, hash_password(new_password), current_time)
        await self.auth_repository.revoke_all_user_sessions(
            user_id=user.id,
            when=current_time,
            reason="password_reset",
        )

    async def request_email_verification(
        self,
        *,
        user: User,
        user_agent: str | None,
        ip_address: str | None,
    ) -> ActionAcceptedResponse:
        token_value = await self._create_email_verification_token(
            user,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        return ActionAcceptedResponse(
            detail="Verification instructions have been prepared.",
            debug_token=token_value if self.settings.expose_debug_tokens else None,
        )

    async def verify_email(self, *, token: str) -> None:
        hashed_token = hash_token(token)
        record = await self.auth_repository.get_email_verification_token(hashed_token)
        current_time = now_utc()
        if record is None or record.used_at is not None or self._as_utc(record.expires_at) <= current_time:
            raise AuthenticationError("Email verification token is invalid or expired.")
        user = await self.user_repository.get_by_id(record.user_id)
        if user is None:
            raise AuthenticationError("Email verification token is invalid.")
        await self.auth_repository.invalidate_email_verification_tokens(user_id=user.id, when=current_time)
        await self.user_repository.mark_email_verified(user, current_time)

    async def _issue_token_pair(
        self,
        user: User,
        *,
        user_agent: str | None,
        ip_address: str | None,
        device_name: str | None,
    ) -> TokenPairResponse:
        current_time = now_utc()
        await self.user_repository.update_last_login(user, current_time)
        access_token, access_expires_at = create_access_token(user_id=user.id, settings=self.settings)
        refresh_token, refresh_expires_at, idle_expires_at, jti = create_refresh_token(
            user_id=user.id,
            settings=self.settings,
        )
        refresh_session = await self.auth_repository.create_refresh_token(
            user_id=user.id,
            jti=jti,
            token_hash=hash_token(refresh_token),
            expires_at=refresh_expires_at,
            idle_expires_at=idle_expires_at,
            device_name=device_name,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        return TokenPairResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            access_token_expires_at=access_expires_at,
            refresh_token_expires_at=refresh_expires_at,
            session_id=refresh_session.id,
            user=UserRead.model_validate(user),
        )

    async def _create_email_verification_token(
        self,
        user: User,
        *,
        user_agent: str | None,
        ip_address: str | None,
    ) -> str:
        token_value = generate_opaque_token()
        await self.auth_repository.invalidate_email_verification_tokens(user_id=user.id, when=now_utc())
        await self.auth_repository.create_email_verification_token(
            user_id=user.id,
            token_hash=hash_token(token_value),
            expires_at=now_utc() + timedelta(hours=self.settings.email_verification_token_ttl_hours),
            user_agent=user_agent,
            ip_address=ip_address,
        )
        await self.notification_service.send_email_verification(user=user, token=token_value)
        return token_value

    async def _record_failed_login(
        self,
        *,
        email: str,
        user: User | None,
        ip_address: str | None,
        user_agent: str | None,
    ) -> None:
        current_time = now_utc()
        recent_failures = await self.auth_repository.count_recent_failed_login_attempts(
            email=email,
            ip_address=ip_address,
            attempted_after=current_time - timedelta(minutes=self.settings.failed_login_window_minutes),
        )
        failure_count = recent_failures + 1
        await self.auth_repository.create_login_attempt(
            user_id=user.id if user else None,
            email=email,
            ip_address=ip_address,
            user_agent=user_agent,
            successful=False,
            attempted_at=current_time,
            failure_count=failure_count,
        )
        if user is not None:
            await self.user_repository.increment_failed_logins(
                user,
                failed_attempts=failure_count,
                lock_after=self.settings.max_failed_login_attempts,
                locked_until=(
                    current_time + timedelta(minutes=self.settings.login_lockout_minutes)
                    if failure_count >= self.settings.max_failed_login_attempts
                    else None
                ),
            )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        return value if value.tzinfo is not None else value.replace(tzinfo=UTC)
