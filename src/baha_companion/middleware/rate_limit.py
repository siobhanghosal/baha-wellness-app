from __future__ import annotations

import time
from collections import defaultdict, deque
from collections.abc import Callable
from dataclasses import dataclass

from fastapi import Depends, Request

from baha_companion.common.exceptions import RateLimitError
from baha_companion.config import AppSettings, get_settings


@dataclass(frozen=True)
class RateLimitRule:
    name: str
    attempts: int
    window_seconds: int


class InMemoryRateLimiter:
    def __init__(self) -> None:
        self._requests: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str, rule: RateLimitRule) -> None:
        now = time.monotonic()
        bucket = self._requests[f"{rule.name}:{key}"]
        cutoff = now - rule.window_seconds
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()
        if len(bucket) >= rule.attempts:
            raise RateLimitError(
                "Too many requests. Please try again later.",
                extra={"limit": rule.attempts, "window_seconds": rule.window_seconds},
            )
        bucket.append(now)

    def reset(self) -> None:
        self._requests.clear()


_rate_limiter = InMemoryRateLimiter()


def get_rate_limiter() -> InMemoryRateLimiter:
    return _rate_limiter


def client_ip(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def rate_limit_dependency(rule: RateLimitRule, *, key_func: Callable[[Request], str] | None = None):
    async def dependency(
        request: Request,
        limiter: InMemoryRateLimiter = Depends(get_rate_limiter),
    ) -> None:
        limiter.check((key_func or client_ip)(request), rule)

    return dependency


def settings_rate_limit_dependency(
    *,
    name: str,
    attempts_setting: str,
    window_setting: str,
    key_func: Callable[[Request], str] | None = None,
):
    async def dependency(
        request: Request,
        limiter: InMemoryRateLimiter = Depends(get_rate_limiter),
        settings: AppSettings = Depends(get_settings),
    ) -> None:
        limiter.check(
            (key_func or client_ip)(request),
            RateLimitRule(
                name=name,
                attempts=getattr(settings, attempts_setting),
                window_seconds=getattr(settings, window_setting),
            ),
        )

    return dependency
