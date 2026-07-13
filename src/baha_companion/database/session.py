from __future__ import annotations

from collections.abc import AsyncIterator
from functools import lru_cache

from sqlalchemy import event, text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from baha_companion.config import get_settings


@lru_cache
def get_engine() -> AsyncEngine:
    settings = get_settings()
    engine_kwargs = {
        "echo": settings.database_echo,
    }
    if not settings.database_url.startswith("sqlite"):
        engine_kwargs.update(
            {
                "pool_pre_ping": True,
                "pool_timeout": settings.database_pool_timeout_seconds,
                "pool_recycle": settings.database_pool_recycle_seconds,
                "pool_size": settings.database_pool_size,
                "max_overflow": settings.database_max_overflow,
            }
        )
    engine = create_async_engine(
        settings.database_url,
        **engine_kwargs,
    )
    if settings.database_url.startswith("sqlite"):
        @event.listens_for(engine.sync_engine, "connect")
        def _set_sqlite_pragma(dbapi_connection, _connection_record) -> None:
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    return engine


@lru_cache
def get_session_factory() -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(get_engine(), expire_on_commit=False, autoflush=False)


async def get_session() -> AsyncIterator[AsyncSession]:
    async with get_session_factory()() as session:
        yield session


async def ping_database(session: AsyncSession) -> None:
    await session.execute(text("select 1"))
