from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse

from baha_companion.api.router import api_router, root_router
from baha_companion.common.exceptions import AppError
from baha_companion.common.schemas import ErrorDetail
from baha_companion.config import AppSettings, get_settings
from baha_companion.config.logging import configure_logging
from baha_companion.middleware.request_context import RequestContextMiddleware, get_request_id
from baha_companion.middleware.security import SecurityHeadersMiddleware

logger = logging.getLogger("baha_companion.app")


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("application_startup")
    yield
    logger.info("application_shutdown")


def build_error_payload(*, code: str, message: str, request_id: str | None, details=None) -> dict:
    return {
        "error": ErrorDetail(code=code, message=message, details=details).model_dump(),
        "request_id": request_id,
        "timestamp": datetime.now(UTC).isoformat(),
    }


def resolve_request_id(request: Request) -> str | None:
    return getattr(request.state, "request_id", None) or get_request_id()


def create_app(settings: AppSettings | None = None) -> FastAPI:
    app_settings = settings or get_settings()
    configure_logging(app_settings)

    app = FastAPI(
        title=app_settings.app_name,
        version=app_settings.app_version,
        description=(
            "Production-oriented backend foundation for the BAHA Wellness Companion chatbot. "
            "This release includes authentication, session management, conversation persistence, "
            "security controls, health checks, hybrid retrieval, and GPT-4o mini orchestration with streaming."
        ),
        docs_url=app_settings.docs_url,
        redoc_url=app_settings.redoc_url,
        openapi_url=app_settings.openapi_url,
        lifespan=lifespan,
    )

    app.add_middleware(RequestContextMiddleware)
    app.add_middleware(SecurityHeadersMiddleware, settings=app_settings)
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=app_settings.trusted_hosts)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=app_settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", app_settings.csrf_header_name, "X-Request-ID"],
    )

    @app.exception_handler(AppError)
    async def handle_application_error(request: Request, exc: AppError) -> JSONResponse:
        logger.warning(
            "application_error",
            extra={"error_code": exc.code, "details": exc.extra or None},
        )
        return JSONResponse(
            status_code=exc.status_code,
            content=build_error_payload(
                code=exc.code,
                message=exc.detail,
                request_id=resolve_request_id(request),
                details=exc.extra or None,
            ),
        )

    @app.exception_handler(HTTPException)
    async def handle_http_exception(request: Request, exc: HTTPException) -> JSONResponse:
        logger.warning(
            "http_exception",
            extra={"error_code": "http_error", "details": {"status_code": exc.status_code}},
        )
        return JSONResponse(
            status_code=exc.status_code,
            content=build_error_payload(
                code="http_error",
                message=str(exc.detail),
                request_id=resolve_request_id(request),
            ),
            headers=exc.headers,
        )

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=build_error_payload(
                code="validation_error",
                message="Request validation failed.",
                details={"errors": exc.errors()},
                request_id=resolve_request_id(request),
            ),
        )

    @app.exception_handler(Exception)
    async def handle_unexpected_exception(request: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled_exception", extra={"error_code": "internal_server_error"})
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=build_error_payload(
                code="internal_server_error",
                message="An unexpected error occurred.",
                request_id=resolve_request_id(request),
            ),
        )

    app.include_router(root_router)
    app.include_router(api_router, prefix=app_settings.api_v1_prefix)
    return app
