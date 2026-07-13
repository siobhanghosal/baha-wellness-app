from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
from logging.config import dictConfig
from typing import Any

from baha_companion.config.settings import AppSettings
from baha_companion.middleware.request_context import get_conversation_id, get_request_id, get_user_id


class ContextFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = get_request_id() or "-"
        record.user_id = get_user_id() or "-"
        record.conversation_id = get_conversation_id() or "-"
        return True


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
            "user_id": getattr(record, "user_id", "-"),
            "conversation_id": getattr(record, "conversation_id", "-"),
        }
        for attribute in (
            "method",
            "path",
            "status_code",
            "latency_ms",
            "response_size",
            "warning",
            "error_code",
            "details",
        ):
            value = getattr(record, attribute, None)
            if value is not None:
                payload[attribute] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def configure_logging(settings: AppSettings) -> None:
    dictConfig(
        {
            "version": 1,
            "disable_existing_loggers": False,
            "filters": {"context": {"()": ContextFilter}},
            "formatters": {
                "json": {"()": JsonFormatter},
                "plain": {
                    "format": (
                        "%(asctime)s %(levelname)s [%(name)s] "
                        "[request_id=%(request_id)s user_id=%(user_id)s conversation_id=%(conversation_id)s] "
                        "%(message)s"
                    )
                },
            },
            "handlers": {
                "default": {
                    "class": "logging.StreamHandler",
                    "formatter": "json" if settings.log_json else "plain",
                    "filters": ["context"],
                }
            },
            "root": {"level": settings.log_level.upper(), "handlers": ["default"]},
        }
    )
