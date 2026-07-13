from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.api.dependencies import get_user_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.database.session import get_session
from baha_companion.users.models import User
from baha_companion.users.schemas import UserRead, UserUpdate
from baha_companion.users.service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserRead)
async def get_me(current_user: Annotated[User, Depends(get_current_user)]) -> UserRead:
    return UserRead.model_validate(current_user)


@router.patch("/me", response_model=UserRead)
async def update_me(
    request: UserUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[UserService, Depends(get_user_service)],
) -> UserRead:
    updated_user = await service.update_profile(current_user, full_name=request.full_name)
    await session.commit()
    return UserRead.model_validate(updated_user)
