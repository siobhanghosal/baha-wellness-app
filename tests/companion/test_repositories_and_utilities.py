from __future__ import annotations

from datetime import UTC, datetime, timedelta
from io import BytesIO
from uuid import uuid4

import pytest
from fastapi import HTTPException, UploadFile
from httpx import ASGITransport, AsyncClient
from starlette.datastructures import Headers

from baha_companion.authentication.cookies import apply_auth_cookies, clear_auth_cookies, resolve_refresh_token
from baha_companion.authentication.notifications import AuthenticationNotificationService
from baha_companion.authentication.repository import AuthenticationRepository
from baha_companion.authentication.schemas import TokenPairResponse
from baha_companion.authentication.security import create_access_token
from baha_companion.chat.models import ConversationStatus, MessageSender
from baha_companion.chat.repository import ChatRepository
from baha_companion.chat.service import ChatService
from baha_companion.common.exceptions import AppError, NotFoundError, ValidationError
from baha_companion.common.sanitization import normalize_email, sanitize_optional_text, strip_control_characters
from baha_companion.common.uploads import validate_upload
from baha_companion.database.session import ping_database
from baha_companion.middleware.rate_limit import InMemoryRateLimiter, RateLimitRule, client_ip
from baha_companion.users.repository import UserRepository
from baha_companion.users.schemas import UserRead
from baha_companion.users.service import UserService


async def test_user_auth_and_chat_repositories_round_trip(db_session):
    user_repository = UserRepository(db_session)
    auth_repository = AuthenticationRepository(db_session)
    chat_repository = ChatRepository(db_session)
    now = datetime.now(UTC)

    user = await user_repository.create(
        email="repo@example.com",
        full_name="Repository User",
        password_hash="hashed-password",
    )
    assert await user_repository.get_by_email("REPO@example.com")
    assert await user_repository.get_by_id(user.id)

    await user_repository.update_last_login(user, now)
    await user_repository.update_profile(user, full_name="Updated Repo User")
    await user_repository.set_password(user, "next-password-hash", now)
    await user_repository.mark_email_verified(user, now)
    await user_repository.increment_failed_logins(
        user,
        failed_attempts=5,
        lock_after=5,
        locked_until=now + timedelta(minutes=10),
    )
    await user_repository.reset_failed_logins(user)

    refresh_token = await auth_repository.create_refresh_token(
        user_id=user.id,
        jti="repo-session",
        token_hash="refresh-hash",
        expires_at=now + timedelta(days=1),
        idle_expires_at=now + timedelta(hours=12),
        device_name="Desktop",
        user_agent="pytest",
        ip_address="127.0.0.1",
    )
    assert await auth_repository.get_refresh_token_by_jti("repo-session")
    assert len(await auth_repository.list_active_sessions(user_id=user.id)) == 1
    await auth_repository.touch_refresh_token(
        refresh_token,
        when=now,
        idle_expires_at=now + timedelta(hours=6),
        ip_address="127.0.0.2",
        user_agent="pytest-updated",
    )

    password_reset = await auth_repository.create_password_reset_token(
        user_id=user.id,
        token_hash="reset-hash",
        expires_at=now + timedelta(minutes=30),
        user_agent="pytest",
        ip_address="127.0.0.1",
    )
    assert await auth_repository.get_password_reset_token("reset-hash") == password_reset
    await auth_repository.invalidate_password_reset_tokens(user_id=user.id, when=now)

    email_verification = await auth_repository.create_email_verification_token(
        user_id=user.id,
        token_hash="verify-hash",
        expires_at=now + timedelta(hours=1),
        user_agent="pytest",
        ip_address="127.0.0.1",
    )
    assert await auth_repository.get_email_verification_token("verify-hash") == email_verification
    await auth_repository.invalidate_email_verification_tokens(user_id=user.id, when=now)

    await auth_repository.create_login_attempt(
        user_id=user.id,
        email=user.email,
        ip_address="127.0.0.1",
        user_agent="pytest",
        successful=False,
        attempted_at=now,
        failure_count=2,
    )
    await auth_repository.create_login_attempt(
        user_id=user.id,
        email=user.email,
        ip_address="127.0.0.1",
        user_agent="pytest",
        successful=True,
        attempted_at=now,
    )
    failed_attempts = await auth_repository.count_recent_failed_login_attempts(
        email=user.email,
        ip_address="127.0.0.1",
        attempted_after=now - timedelta(minutes=5),
    )
    assert failed_attempts == 1

    conversation = await chat_repository.create_conversation(
        user_id=user.id,
        title=None,
        summary="Seed summary",
        metadata={"source": "repo-test"},
    )
    assert conversation.summary == "Seed summary"

    listed = await chat_repository.list_conversations(
        user_id=user.id,
        pagination=type("Pagination", (), {"offset": 0, "page_size": 10, "page": 1})(),
        sort_by="created_at",
        sort_direction="asc",
    )
    assert listed.meta.total_items == 1

    stored = await chat_repository.get_conversation(conversation_id=conversation.id, user_id=user.id)
    assert stored is not None

    message = await chat_repository.create_message(
        conversation_id=conversation.id,
        user_id=user.id,
        role=MessageSender.USER,
        content="Repository test message",
        markdown=True,
        token_count=3,
        latency=42,
        citations=[{"source": "docs"}],
        metadata={"origin": "unit"},
        llm_response_id="llm-placeholder",
    )
    assert message.sequence_number == 1

    messages = await chat_repository.list_messages(
        conversation_id=conversation.id,
        user_id=user.id,
        pagination=type("Pagination", (), {"offset": 0, "page_size": 10, "page": 1})(),
    )
    assert messages.meta.total_items == 1

    await chat_repository.update_conversation(
        conversation,
        title="Renamed",
        summary="Updated summary",
        status=ConversationStatus.ARCHIVED,
        metadata={"source": "updated"},
    )
    deleted = await chat_repository.soft_delete_conversation(conversation)
    assert deleted.deleted_at is not None

    await auth_repository.revoke_refresh_token(refresh_token, when=now, reason="manual_test")
    await auth_repository.revoke_all_user_sessions(user_id=user.id, when=now, reason="all_devices")
    await auth_repository.purge_expired_tokens(now=now + timedelta(days=2))


async def test_services_and_session_helpers(db_session, test_settings, monkeypatch):
    user_repository = UserRepository(db_session)
    user_service = UserService(user_repository)
    chat_service = ChatService(ChatRepository(db_session))
    notification_service = AuthenticationNotificationService()
    user = await user_repository.create(
        email="service@example.com",
        full_name="Service User",
        password_hash="hash",
    )

    assert ChatService._derive_title(None) is None
    assert chat_service.estimate_token_count("one two three") == 3

    with pytest.raises(NotFoundError):
        await user_service.get_user(uuid4())

    with pytest.raises(NotFoundError):
        await chat_service.get_conversation(conversation_id=uuid4(), user_id=user.id)

    await notification_service.send_password_reset(user=user, token="token-1")
    await notification_service.send_email_verification(user=user, token="token-2")
    await ping_database(db_session)

    import baha_companion.database.session as session_module

    session_module.get_engine.cache_clear()
    session_module.get_session_factory.cache_clear()
    monkeypatch.setattr(session_module, "get_settings", lambda: test_settings)
    sqlite_engine = session_module.get_engine()
    await sqlite_engine.dispose()

    captured: dict[str, object] = {}

    class DummyEngine:
        sync_engine = object()

    def fake_create_async_engine(database_url: str, **kwargs):
        captured["database_url"] = database_url
        captured["kwargs"] = kwargs
        return DummyEngine()

    postgres_settings = test_settings.model_copy(
        update={"database_url": "postgresql+asyncpg://postgres:postgres@localhost:5432/baha"}
    )
    session_module.get_engine.cache_clear()
    session_module.get_session_factory.cache_clear()
    monkeypatch.setattr(session_module, "get_settings", lambda: postgres_settings)
    monkeypatch.setattr(session_module, "create_async_engine", fake_create_async_engine)
    engine = session_module.get_engine()
    assert isinstance(engine, DummyEngine)
    assert captured["database_url"] == postgres_settings.database_url
    assert captured["kwargs"]["pool_size"] == postgres_settings.database_pool_size
    session_module.get_engine.cache_clear()
    session_module.get_session_factory.cache_clear()


@pytest.mark.asyncio
async def test_app_errors_cookies_sanitization_and_upload_guards(app, test_settings):
    @app.get("/app-error")
    async def app_error_route():
        raise AppError("application exploded", code="app_error", status_code=418)

    @app.get("/http-error")
    async def http_error_route():
        raise HTTPException(status_code=409, detail="conflict")

    @app.get("/unexpected-error")
    async def unexpected_error_route():
        raise RuntimeError("boom")

    async with AsyncClient(
        transport=ASGITransport(app=app, raise_app_exceptions=False),
        base_url="http://testserver",
    ) as client:
        app_error = await client.get("/app-error")
        assert app_error.status_code == 418
        assert app_error.json()["error"]["code"] == "app_error"

        http_error = await client.get("/http-error")
        assert http_error.status_code == 409
        assert http_error.json()["error"]["code"] == "http_error"

        unexpected_error = await client.get("/unexpected-error")
        assert unexpected_error.status_code == 500
        assert unexpected_error.json()["error"]["code"] == "internal_server_error"

        root_response = await client.get("/")
        assert root_response.headers["x-content-type-options"] == "nosniff"
        assert root_response.headers["x-frame-options"] == "DENY"

    access_token, access_expires_at = create_access_token(user_id=uuid4(), settings=test_settings)
    token_response = TokenPairResponse(
        access_token=access_token,
        refresh_token="refresh-token-value",
        access_token_expires_at=access_expires_at,
        refresh_token_expires_at=access_expires_at + timedelta(days=7),
        session_id=uuid4(),
        user=UserRead(
            id=uuid4(),
            email="cookie@example.com",
            full_name="Cookie User",
            role="user",
            is_active=True,
            is_superuser=False,
            email_verified_at=None,
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
            last_login_at=None,
        ),
    )

    from fastapi import Request, Response

    response = Response()
    csrf_token = apply_auth_cookies(response, settings=test_settings, tokens=token_response)
    assert csrf_token is not None

    explicit_request = Request(
        {
            "type": "http",
            "method": "POST",
            "headers": [],
            "path": "/refresh",
            "client": ("127.0.0.1", 1234),
        }
    )
    assert resolve_refresh_token(explicit_request, "explicit-token", test_settings) == "explicit-token"

    cookie_request = Request(
        {
            "type": "http",
            "method": "POST",
            "headers": [
                (b"cookie", f"{test_settings.refresh_cookie_name}=cookie-token; {test_settings.csrf_cookie_name}=csrf-token".encode()),
                (test_settings.csrf_header_name.lower().encode(), b"csrf-token"),
            ],
            "path": "/refresh",
            "client": ("127.0.0.1", 1234),
        }
    )
    assert resolve_refresh_token(cookie_request, None, test_settings) == "cookie-token"

    invalid_cookie_request = Request(
        {
            "type": "http",
            "method": "POST",
            "headers": [
                (b"cookie", f"{test_settings.refresh_cookie_name}=cookie-token; {test_settings.csrf_cookie_name}=csrf-token".encode())
            ],
            "path": "/refresh",
            "client": ("127.0.0.1", 1234),
        }
    )
    with pytest.raises(AppError):
        resolve_refresh_token(invalid_cookie_request, None, test_settings)

    clear_auth_cookies(response, test_settings)
    assert strip_control_characters("he\x00llo") == "hello"
    assert sanitize_optional_text(" \n test \t ") == "test"
    assert sanitize_optional_text(" \n\t ") is None
    assert normalize_email(" USER@Example.COM ") == "user@example.com"

    upload = UploadFile(
        file=BytesIO(b"hello"),
        filename="notes.txt",
        headers=Headers({"content-length": "5", "content-type": "text/plain"}),
    )
    validate_upload(
        upload,
        allowed_content_types={"text/plain"},
        allowed_extensions={".txt"},
        max_size_bytes=10,
    )

    with pytest.raises(ValidationError):
        validate_upload(
            UploadFile(
                file=BytesIO(b"hello"),
                filename="notes.txt",
                headers=Headers({"content-length": "5", "content-type": "application/json"}),
            ),
            allowed_content_types={"text/plain"},
            allowed_extensions={".txt"},
            max_size_bytes=10,
        )

    with pytest.raises(ValidationError):
        validate_upload(
            UploadFile(
                file=BytesIO(b"hello"),
                filename="notes.pdf",
                headers=Headers({"content-length": "5", "content-type": "text/plain"}),
            ),
            allowed_content_types={"text/plain"},
            allowed_extensions={".txt"},
            max_size_bytes=10,
        )

    with pytest.raises(ValidationError):
        validate_upload(
            UploadFile(
                file=BytesIO(b"hello"),
                filename="notes.txt",
                headers=Headers({"content-length": "50", "content-type": "text/plain"}),
            ),
            allowed_content_types={"text/plain"},
            allowed_extensions={".txt"},
            max_size_bytes=10,
        )

    limiter = InMemoryRateLimiter()
    limiter.check("user", RateLimitRule(name="unit", attempts=2, window_seconds=60))
    limiter.check("user", RateLimitRule(name="unit", attempts=2, window_seconds=60))
    with pytest.raises(AppError):
        limiter.check("user", RateLimitRule(name="unit", attempts=2, window_seconds=60))
    limiter.reset()

    forwarded_request = Request(
        {
            "type": "http",
            "method": "GET",
            "headers": [(b"x-forwarded-for", b"10.0.0.1, 10.0.0.2")],
            "path": "/",
            "client": ("127.0.0.1", 4321),
        }
    )
    assert client_ip(forwarded_request) == "10.0.0.1"
