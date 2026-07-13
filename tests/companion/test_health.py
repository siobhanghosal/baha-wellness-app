from __future__ import annotations


async def test_health_endpoints_and_security_headers(client):
    live_response = await client.get("/health/live")
    assert live_response.status_code == 200
    assert live_response.json()["status"] == "ok"
    assert live_response.headers["x-content-type-options"] == "nosniff"
    assert live_response.headers["x-frame-options"] == "DENY"
    assert "Content-Security-Policy" in live_response.headers

    ready_response = await client.get("/health/ready")
    assert ready_response.status_code == 200
    assert ready_response.json()["status"] == "ok"


async def test_error_format_is_consistent(client):
    response = await client.get("/api/v1/users/me")
    assert response.status_code == 401
    payload = response.json()
    assert payload["error"]["code"] == "authentication_error"
    assert payload["request_id"]
    assert payload["timestamp"]
