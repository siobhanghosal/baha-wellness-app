from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.authentication.models import (
    EmailVerificationToken,
    LoginAttempt,
    PasswordResetToken,
    RefreshToken,
)


class AuthenticationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create_refresh_token(
        self,
        *,
        user_id: UUID,
        jti: str,
        token_hash: str,
        expires_at: datetime,
        idle_expires_at: datetime,
        device_name: str | None,
        user_agent: str | None,
        ip_address: str | None,
    ) -> RefreshToken:
        token = RefreshToken(
            user_id=user_id,
            jti=jti,
            token_hash=token_hash,
            expires_at=expires_at,
            idle_expires_at=idle_expires_at,
            device_name=device_name,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        self.session.add(token)
        await self.session.flush()
        await self.session.refresh(token)
        return token

    async def get_refresh_token_by_jti(
        self,
        jti: str,
        *,
        include_deleted: bool = False,
    ) -> RefreshToken | None:
        result = await self.session.execute(
            select(RefreshToken)
            .where(RefreshToken.jti == jti)
            .execution_options(include_deleted=include_deleted)
        )
        return result.scalar_one_or_none()

    async def list_active_sessions(self, *, user_id: UUID) -> list[RefreshToken]:
        result = await self.session.execute(
            select(RefreshToken)
            .where(
                RefreshToken.user_id == user_id,
                RefreshToken.revoked_at.is_(None),
            )
            .order_by(RefreshToken.created_at.desc())
        )
        return list(result.scalars().all())

    async def revoke_refresh_token(
        self,
        token: RefreshToken,
        *,
        when: datetime,
        reason: str,
    ) -> RefreshToken:
        token.revoked_at = when
        token.revoked_reason = reason
        token.is_current = False
        await self.session.flush()
        return token

    async def revoke_all_user_sessions(self, *, user_id: UUID, when: datetime, reason: str) -> None:
        await self.session.execute(
            update(RefreshToken)
            .where(
                RefreshToken.user_id == user_id,
                RefreshToken.revoked_at.is_(None),
            )
            .values(revoked_at=when, revoked_reason=reason, is_current=False)
        )

    async def touch_refresh_token(
        self,
        token: RefreshToken,
        *,
        when: datetime,
        idle_expires_at: datetime,
        ip_address: str | None,
        user_agent: str | None,
    ) -> RefreshToken:
        token.last_used_at = when
        token.idle_expires_at = idle_expires_at
        token.ip_address = ip_address
        token.user_agent = user_agent
        await self.session.flush()
        return token

    async def create_password_reset_token(
        self,
        *,
        user_id: UUID,
        token_hash: str,
        expires_at: datetime,
        user_agent: str | None,
        ip_address: str | None,
    ) -> PasswordResetToken:
        token = PasswordResetToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        self.session.add(token)
        await self.session.flush()
        return token

    async def get_password_reset_token(self, token_hash: str) -> PasswordResetToken | None:
        result = await self.session.execute(
            select(PasswordResetToken).where(PasswordResetToken.token_hash == token_hash)
        )
        return result.scalar_one_or_none()

    async def invalidate_password_reset_tokens(self, *, user_id: UUID, when: datetime) -> None:
        await self.session.execute(
            update(PasswordResetToken)
            .where(PasswordResetToken.user_id == user_id, PasswordResetToken.used_at.is_(None))
            .values(used_at=when)
        )

    async def create_email_verification_token(
        self,
        *,
        user_id: UUID,
        token_hash: str,
        expires_at: datetime,
        user_agent: str | None,
        ip_address: str | None,
    ) -> EmailVerificationToken:
        token = EmailVerificationToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        self.session.add(token)
        await self.session.flush()
        return token

    async def get_email_verification_token(self, token_hash: str) -> EmailVerificationToken | None:
        result = await self.session.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.token_hash == token_hash)
        )
        return result.scalar_one_or_none()

    async def invalidate_email_verification_tokens(self, *, user_id: UUID, when: datetime) -> None:
        await self.session.execute(
            update(EmailVerificationToken)
            .where(EmailVerificationToken.user_id == user_id, EmailVerificationToken.used_at.is_(None))
            .values(used_at=when)
        )

    async def create_login_attempt(
        self,
        *,
        user_id: UUID | None,
        email: str,
        ip_address: str | None,
        user_agent: str | None,
        successful: bool,
        attempted_at: datetime,
        failure_count: int = 1,
    ) -> LoginAttempt:
        attempt = LoginAttempt(
            user_id=user_id,
            email=email,
            ip_address=ip_address,
            user_agent=user_agent,
            successful=successful,
            attempted_at=attempted_at,
            failure_count=failure_count,
        )
        self.session.add(attempt)
        await self.session.flush()
        return attempt

    async def count_recent_failed_login_attempts(
        self,
        *,
        email: str,
        ip_address: str | None,
        attempted_after: datetime,
    ) -> int:
        filters = [
            LoginAttempt.email == email,
            LoginAttempt.successful.is_(False),
            LoginAttempt.attempted_at >= attempted_after,
        ]
        if ip_address is not None:
            filters.append(LoginAttempt.ip_address == ip_address)
        result = await self.session.execute(select(func.count(LoginAttempt.id)).where(*filters))
        return int(result.scalar_one())

    async def purge_expired_tokens(self, *, now: datetime) -> None:
        await self.session.execute(
            update(RefreshToken)
            .where(RefreshToken.revoked_at.is_(None), RefreshToken.expires_at < now)
            .values(revoked_at=now, revoked_reason="expired", is_current=False)
        )
