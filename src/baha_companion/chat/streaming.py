from __future__ import annotations

import json
from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import APIRouter, WebSocket
from fastapi.responses import StreamingResponse

router = APIRouter(prefix="/chat", tags=["Streaming"])


async def placeholder_sse_stream(conversation_id: UUID) -> AsyncIterator[bytes]:
    payload = {
        "conversation_id": str(conversation_id),
        "status": "placeholder",
        "message": "Streaming infrastructure is ready, but AI generation is not implemented yet.",
    }
    yield f"event: ready\ndata: {json.dumps(payload)}\n\n".encode("utf-8")


@router.get("/conversations/{conversation_id}/stream")
async def stream_conversation_placeholder(conversation_id: UUID) -> StreamingResponse:
    return StreamingResponse(placeholder_sse_stream(conversation_id), media_type="text/event-stream")


@router.websocket("/ws/conversations/{conversation_id}")
async def websocket_placeholder(websocket: WebSocket, conversation_id: UUID) -> None:
    await websocket.accept()
    await websocket.send_json(
        {
            "conversation_id": str(conversation_id),
            "status": "placeholder",
            "message": "WebSocket streaming is not implemented yet.",
        }
    )
    await websocket.close(code=1000)
