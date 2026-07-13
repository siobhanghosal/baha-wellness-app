from __future__ import annotations

from io import BytesIO

from starlette.datastructures import Headers, UploadFile

from baha_companion.common.uploads import validate_upload


async def test_update_user_profile(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}
    response = await client.patch("/api/v1/users/me", headers=headers, json={"full_name": " Updated   User "})
    assert response.status_code == 200
    assert response.json()["full_name"] == "Updated User"


async def test_validation_errors_use_standard_shape(client):
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "bad-email", "password": "short"},
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "validation_error"


def test_file_upload_validation():
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
