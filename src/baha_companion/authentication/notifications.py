from __future__ import annotations

import logging

from baha_companion.users.models import User

logger = logging.getLogger("baha_companion.auth.notifications")


class AuthenticationNotificationService:
    async def send_password_reset(self, *, user: User, token: str) -> None:
        logger.info("password_reset_requested", extra={"details": {"user_id": str(user.id), "token": token}})

    async def send_email_verification(self, *, user: User, token: str) -> None:
        logger.info("email_verification_requested", extra={"details": {"user_id": str(user.id), "token": token}})
