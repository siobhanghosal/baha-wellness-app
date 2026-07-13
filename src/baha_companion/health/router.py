from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.config import AppSettings, get_settings
from baha_companion.database.session import get_session
from baha_companion.health.service import HealthService

router = APIRouter(tags=["Health"])


def get_health_service(
    settings: Annotated[AppSettings, Depends(get_settings)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> HealthService:
    return HealthService(settings, session)


@router.get("/", summary="Service metadata")
async def root(settings: Annotated[AppSettings, Depends(get_settings)]) -> dict[str, str]:
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "docs": settings.docs_url or "disabled",
    }


@router.get("/health/live", summary="Liveness probe")
async def liveness() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/health/ready", summary="Readiness probe")
async def readiness(
    service: Annotated[HealthService, Depends(get_health_service)],
) -> dict[str, str]:
    return await service.readiness()
