from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.config import AppSettings
from baha_companion.database.session import ping_database


class HealthService:
    def __init__(self, settings: AppSettings, session: AsyncSession) -> None:
        self.settings = settings
        self.session = session

    async def readiness(self) -> dict[str, str]:
        await ping_database(self.session)
        return {
            "status": "ok",
            "service": self.settings.app_name,
            "environment": self.settings.environment,
        }
