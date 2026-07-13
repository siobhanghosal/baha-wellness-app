from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.database import session as session_module


async def test_get_session_yields_async_session(monkeypatch, session_factory):
    monkeypatch.setattr(session_module, "get_session_factory", lambda: session_factory)

    session_generator = session_module.get_session()
    session = await anext(session_generator)

    assert isinstance(session, AsyncSession)

    await session_generator.aclose()
