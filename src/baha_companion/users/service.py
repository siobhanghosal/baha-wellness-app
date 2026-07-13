from __future__ import annotations

from uuid import UUID

from baha_companion.common.exceptions import NotFoundError
from baha_companion.users.models import User
from baha_companion.users.repository import UserRepository


class UserService:
    def __init__(self, repository: UserRepository) -> None:
        self.repository = repository

    async def get_user(self, user_id: UUID | str) -> User:
        user = await self.repository.get_by_id(user_id)
        if user is None:
            raise NotFoundError("User not found.")
        return user

    async def update_profile(self, user: User, *, full_name: str | None) -> User:
        return await self.repository.update_profile(user, full_name=full_name)
