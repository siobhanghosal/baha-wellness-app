from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.users.models import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email.lower()))
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: UUID | str) -> User | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def create(
        self,
        *,
        email: str,
        full_name: str | None,
        password_hash: str,
        role: str = "user",
    ) -> User:
        user = User(
            email=email.lower(),
            full_name=full_name,
            password_hash=password_hash,
            role=role,
        )
        self.session.add(user)
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def update_last_login(self, user: User, when: datetime) -> User:
        user.last_login_at = when
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def update_profile(self, user: User, *, full_name: str | None) -> User:
        user.full_name = full_name
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def set_password(self, user: User, password_hash: str, changed_at: datetime) -> User:
        user.password_hash = password_hash
        user.password_changed_at = changed_at
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def mark_email_verified(self, user: User, verified_at: datetime) -> User:
        user.email_verified_at = verified_at
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def increment_failed_logins(
        self,
        user: User,
        *,
        failed_attempts: int,
        lock_after: int,
        locked_until: datetime | None,
    ) -> User:
        user.failed_login_attempts = failed_attempts
        if failed_attempts >= lock_after:
            user.locked_until = locked_until
        await self.session.flush()
        await self.session.refresh(user)
        return user

    async def reset_failed_logins(self, user: User) -> User:
        user.failed_login_attempts = 0
        user.locked_until = None
        await self.session.flush()
        await self.session.refresh(user)
        return user
