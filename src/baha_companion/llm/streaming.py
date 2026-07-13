from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from datetime import UTC, datetime
from uuid import UUID, uuid4


@dataclass(slots=True)
class StreamHandle:
    stream_id: str
    user_id: UUID
    conversation_id: UUID | None
    cancel_event: asyncio.Event
    created_at: datetime


class StreamManager:
    def __init__(self) -> None:
        self._handles: dict[str, StreamHandle] = {}

    def create(self, *, user_id: UUID, conversation_id: UUID | None) -> StreamHandle:
        handle = StreamHandle(
            stream_id=str(uuid4()),
            user_id=user_id,
            conversation_id=conversation_id,
            cancel_event=asyncio.Event(),
            created_at=datetime.now(UTC),
        )
        self._handles[handle.stream_id] = handle
        return handle

    def get(self, stream_id: str) -> StreamHandle | None:
        return self._handles.get(stream_id)

    def cancel(self, *, stream_id: str, user_id: UUID) -> bool:
        handle = self._handles.get(stream_id)
        if handle is None or handle.user_id != user_id:
            return False
        handle.cancel_event.set()
        return True

    def complete(self, stream_id: str) -> None:
        self._handles.pop(stream_id, None)

    def reset(self) -> None:
        self._handles.clear()


def sse_event(event: str, data: dict) -> bytes:
    return f"event: {event}\ndata: {json.dumps(data, default=str)}\n\n".encode("utf-8")


_stream_manager = StreamManager()


def get_stream_manager() -> StreamManager:
    return _stream_manager
