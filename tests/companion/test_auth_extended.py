from __future__ import annotations

from uuid import uuid4

from sqlalchemy import select

from baha_companion.users.models import User


async def test_logout_and_revoke_session(client, registered_user_tokens):
    second_login = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "device_name": "Tablet",
        },
    )
    assert second_login.status_code == 200
    second_tokens = second_login.json()
    headers = {"Authorization": f"Bearer {second_tokens['access_token']}"}

    sessions_response = await client.get("/api/v1/auth/sessions", headers=headers)
    assert sessions_response.status_code == 200
    assert len(sessions_response.json()) == 2

    revoke_response = await client.delete(
        f"/api/v1/auth/sessions/{second_tokens['session_id']}",
        headers=headers,
    )
    assert revoke_response.status_code == 204
    assert "baha_refresh_token=" in revoke_response.headers.get("set-cookie", "")

    revoked_refresh = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": second_tokens["refresh_token"]},
    )
    assert revoked_refresh.status_code == 401

    missing_session = await client.delete(f"/api/v1/auth/sessions/{uuid4()}", headers=headers)
    assert missing_session.status_code == 401

    logout_response = await client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": registered_user_tokens["refresh_token"]},
    )
    assert logout_response.status_code == 204
    assert "baha_csrf_token=" in logout_response.headers.get("set-cookie", "")

    original_refresh = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered_user_tokens["refresh_token"]},
    )
    assert original_refresh.status_code == 401


async def test_refresh_token_reuse_detection(client):
    register_response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "reuse@example.com",
            "password": "strong-password-123",
            "full_name": "Reuse Detector",
        },
    )
    assert register_response.status_code == 201
    registered_tokens = register_response.json()

    rotate_response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered_tokens["refresh_token"]},
    )
    assert rotate_response.status_code == 200
    rotated_tokens = rotate_response.json()

    reused_refresh = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered_tokens["refresh_token"]},
    )
    assert reused_refresh.status_code == 401

    rotated_after_reuse = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": rotated_tokens["refresh_token"]},
    )
    assert rotated_after_reuse.status_code == 401


async def test_auth_dependency_guards_and_verification_controls(app, client, db_session, test_settings):
    unauthenticated = await client.get("/api/v1/users/me")
    assert unauthenticated.status_code == 401

    invalid_token = await client.get("/api/v1/users/me", headers={"Authorization": "Bearer not-a-jwt"})
    assert invalid_token.status_code == 401

    register_response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "verify@example.com",
            "password": "strong-password-123",
            "full_name": "Verify Me",
        },
    )
    assert register_response.status_code == 201
    verification_tokens = register_response.json()

    test_settings.require_email_verification_for_login = True
    blocked_login = await client.post(
        "/api/v1/auth/login",
        json={"email": "verify@example.com", "password": "strong-password-123"},
    )
    assert blocked_login.status_code == 403

    verify_request = await client.post(
        "/api/v1/auth/email-verification/request",
        headers={"Authorization": f"Bearer {verification_tokens['access_token']}"},
    )
    assert verify_request.status_code == 202
    assert verify_request.json()["debug_token"]

    invalid_verify = await client.post(
        "/api/v1/auth/email-verification/confirm",
        json={"token": "invalid-token"},
    )
    assert invalid_verify.status_code == 401

    verify_confirm = await client.post(
        "/api/v1/auth/email-verification/confirm",
        json={"token": verify_request.json()["debug_token"]},
    )
    assert verify_confirm.status_code == 204

    user = (
        await db_session.execute(select(User).where(User.email == "verify@example.com"))
    ).scalar_one()
    user.is_active = False
    await db_session.commit()

    inactive_response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {verification_tokens['access_token']}"},
    )
    assert inactive_response.status_code == 401


async def test_password_reset_invalid_token_and_register_conflict(client, registered_user_tokens):
    invalid_reset = await client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"token": "invalid-token", "new_password": "another-strong-password-456"},
    )
    assert invalid_reset.status_code == 401

    conflict = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "full_name": "Duplicate User",
        },
    )
    assert conflict.status_code == 409
