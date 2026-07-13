from __future__ import annotations


async def test_register_login_refresh_and_me(client):
    register_response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "full_name": "Student User",
        },
    )
    assert register_response.status_code == 201
    tokens = register_response.json()
    assert tokens["debug_email_verification_token"]
    assert "baha_refresh_token" in register_response.headers.get("set-cookie", "")

    access_token = tokens["access_token"]
    me_response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "student@example.com"

    refresh_response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"], "device_name": "New browser"},
    )
    assert refresh_response.status_code == 200
    assert refresh_response.json()["refresh_token"] != tokens["refresh_token"]
    assert refresh_response.json()["session_id"] != tokens["session_id"]


async def test_logout_all_revokes_sessions(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    second_login = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "device_name": "Phone",
        },
    )
    assert second_login.status_code == 200

    sessions_before = await client.get("/api/v1/auth/sessions", headers=headers)
    assert sessions_before.status_code == 200
    assert len(sessions_before.json()) == 2

    logout_all = await client.post("/api/v1/auth/logout-all", headers=headers)
    assert logout_all.status_code == 204

    refresh_after_logout = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered_user_tokens["refresh_token"]},
    )
    assert refresh_after_logout.status_code == 401


async def test_password_reset_flow_revokes_existing_sessions(client, registered_user_tokens):
    reset_request = await client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "student@example.com"},
    )
    assert reset_request.status_code == 202
    debug_token = reset_request.json()["debug_token"]

    confirm_response = await client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"token": debug_token, "new_password": "new-strong-password-456"},
    )
    assert confirm_response.status_code == 204

    refresh_with_old_token = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered_user_tokens["refresh_token"]},
    )
    assert refresh_with_old_token.status_code == 401

    login_with_new_password = await client.post(
        "/api/v1/auth/login",
        json={"email": "student@example.com", "password": "new-strong-password-456"},
    )
    assert login_with_new_password.status_code == 200


async def test_email_verification_flow(client, registered_user_tokens):
    verify_token = registered_user_tokens["debug_email_verification_token"]
    confirm_response = await client.post(
        "/api/v1/auth/email-verification/confirm",
        json={"token": verify_token},
    )
    assert confirm_response.status_code == 204

    me_response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {registered_user_tokens['access_token']}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email_verified_at"] is not None


async def test_failed_login_lockout(client):
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "student@example.com",
            "password": "strong-password-123",
            "full_name": "Student User",
        },
    )

    for _ in range(5):
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "student@example.com", "password": "wrong-password-123"},
        )
        assert response.status_code == 401

    locked_response = await client.post(
        "/api/v1/auth/login",
        json={"email": "student@example.com", "password": "strong-password-123"},
    )
    assert locked_response.status_code == 401
    assert locked_response.json()["error"]["message"].startswith("Account is temporarily locked")


async def test_auth_rate_limit_returns_429(client):
    for _ in range(10):
        response = await client.post(
            "/api/v1/auth/password-reset/request",
            json={"email": "nobody@example.com"},
        )
        assert response.status_code == 202

    limited = await client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "nobody@example.com"},
    )
    assert limited.status_code == 429


async def test_cookie_refresh_requires_csrf_header(client, registered_user_tokens):
    csrf_token = registered_user_tokens["csrf_token"]

    forbidden = await client.post("/api/v1/auth/refresh", json={})
    assert forbidden.status_code == 400

    allowed = await client.post(
        "/api/v1/auth/refresh",
        json={},
        headers={"X-CSRF-Token": csrf_token},
    )
    assert allowed.status_code == 200
