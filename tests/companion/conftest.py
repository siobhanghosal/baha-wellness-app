from __future__ import annotations

from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from baha_companion.app import create_app
from baha_companion.embeddings.config import get_embedding_settings
from baha_companion.config.settings import TestingSettings, get_settings
from baha_companion.database.base import Base
from baha_companion.database.session import get_session
from baha_companion.llm.config import get_llm_settings
from baha_companion.llm.streaming import get_stream_manager
from baha_companion.middleware.rate_limit import get_rate_limiter
from baha_companion.retrieval.config import get_retrieval_settings


@pytest.fixture
def test_settings() -> TestingSettings:
    return TestingSettings(
        environment="testing",
        database_url="sqlite+aiosqlite:///:memory:",
        auth_secret_key="test-secret-key-with-32-bytes-minimum",
        allowed_cors_origins=["http://testserver"],
        trusted_hosts=["testserver", "localhost", "127.0.0.1"],
        enable_cookie_auth=True,
        secure_cookies=False,
        expose_debug_tokens=True,
        require_email_verification_for_login=False,
    )


@pytest.fixture(autouse=True)
def clear_embedding_settings_cache():
    get_embedding_settings.cache_clear()
    get_retrieval_settings.cache_clear()
    get_llm_settings.cache_clear()
    get_stream_manager().reset()
    yield
    get_embedding_settings.cache_clear()
    get_retrieval_settings.cache_clear()
    get_llm_settings.cache_clear()
    get_stream_manager().reset()


@pytest_asyncio.fixture
async def engine(test_settings: TestingSettings):
    engine = create_async_engine(
        test_settings.database_url,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def session_factory(engine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


@pytest_asyncio.fixture
async def db_session(session_factory: async_sessionmaker[AsyncSession]) -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def app(test_settings: TestingSettings, session_factory: async_sessionmaker[AsyncSession]):
    get_rate_limiter().reset()
    app = create_app(test_settings)

    async def override_get_session() -> AsyncIterator[AsyncSession]:
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_session] = override_get_session
    app.dependency_overrides[get_settings] = lambda: test_settings
    yield app


@pytest_asyncio.fixture
async def client(app) -> AsyncIterator[AsyncClient]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://testserver") as api_client:
        yield api_client


@pytest_asyncio.fixture
async def registered_user_tokens(client: AsyncClient) -> dict:
    register_response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "full_name": "Student User",
        },
    )
    assert register_response.status_code == 201
    return register_response.json()
