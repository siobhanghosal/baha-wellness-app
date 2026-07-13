from __future__ import annotations

import logging
import time
from contextvars import ContextVar
from uuid import uuid4

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


_request_id_ctx_var: ContextVar[str | None] = ContextVar("request_id", default=None)
_user_id_ctx_var: ContextVar[str | None] = ContextVar("user_id", default=None)
_conversation_id_ctx_var: ContextVar[str | None] = ContextVar("conversation_id", default=None)

logger = logging.getLogger("baha_companion.http")


def get_request_id() -> str | None:
    return _request_id_ctx_var.get()


def set_user_id(user_id: str | None) -> None:
    _user_id_ctx_var.set(user_id)


def get_user_id() -> str | None:
    return _user_id_ctx_var.get()


def set_conversation_id(conversation_id: str | None) -> None:
    _conversation_id_ctx_var.set(conversation_id)


def get_conversation_id() -> str | None:
    return _conversation_id_ctx_var.get()


class RequestContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID") or str(uuid4())
        request.state.request_id = request_id
        request_token = _request_id_ctx_var.set(request_id)
        user_token = _user_id_ctx_var.set(None)
        conversation_token = _conversation_id_ctx_var.set(None)
        started_at = time.perf_counter()
        response: Response | None = None
        try:
            response = await call_next(request)
        finally:
            duration_ms = round((time.perf_counter() - started_at) * 1000, 2)
            response_size = response.headers.get("content-length", "unknown") if response is not None else "unknown"
            logger.info(
                "request_completed",
                extra={
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": getattr(response, "status_code", 500),
                    "latency_ms": duration_ms,
                    "response_size": response_size,
                },
            )
            _request_id_ctx_var.reset(request_token)
            _user_id_ctx_var.reset(user_token)
            _conversation_id_ctx_var.reset(conversation_token)

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time-Ms"] = str(duration_ms)
        return response
