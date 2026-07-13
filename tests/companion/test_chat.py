from __future__ import annotations


async def test_conversation_and_messages_are_persisted(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    create_response = await client.post(
        "/api/v1/chat/conversations",
        headers=headers,
        json={
            "initial_message": "I want help building a journaling routine.",
            "summary": "Routine planning chat",
            "metadata": {"source": "ios"},
        },
    )
    assert create_response.status_code == 201
    conversation = create_response.json()
    assert conversation["message_count"] == 1
    assert conversation["summary"] == "Routine planning chat"
    assert conversation["messages"][0]["token_count"] >= 1

    add_message_response = await client.post(
        f"/api/v1/chat/conversations/{conversation['id']}/messages",
        headers=headers,
        json={"content": "Can you save this as part of my conversation?", "metadata": {"source": "web"}},
    )
    assert add_message_response.status_code == 201
    assert add_message_response.json()["sequence_number"] == 2

    list_messages = await client.get(
        f"/api/v1/chat/conversations/{conversation['id']}/messages?page=1&page_size=10",
        headers=headers,
    )
    assert list_messages.status_code == 200
    assert list_messages.json()["meta"]["total_items"] == 2


async def test_conversation_pagination_filtering_and_update(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}

    for index in range(3):
        response = await client.post(
            "/api/v1/chat/conversations",
            headers=headers,
            json={"title": f"Conversation {index}", "initial_message": f"Message {index}"},
        )
        assert response.status_code == 201

    listing = await client.get("/api/v1/chat/conversations?page=1&page_size=2", headers=headers)
    assert listing.status_code == 200
    assert len(listing.json()["items"]) == 2
    assert listing.json()["meta"]["total_items"] == 3

    conversation_id = listing.json()["items"][0]["id"]
    update = await client.patch(
        f"/api/v1/chat/conversations/{conversation_id}",
        headers=headers,
        json={"title": "Updated title", "status": "archived"},
    )
    assert update.status_code == 200
    assert update.json()["title"] == "Updated title"
    assert update.json()["status"] == "archived"

    archived = await client.get(
        "/api/v1/chat/conversations?page=1&page_size=10&status=archived",
        headers=headers,
    )
    assert archived.status_code == 200
    assert archived.json()["items"][0]["status"] == "archived"


async def test_soft_deleted_conversation_is_hidden(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}
    create = await client.post(
        "/api/v1/chat/conversations",
        headers=headers,
        json={"title": "Delete me", "initial_message": "Temporary note"},
    )
    conversation_id = create.json()["id"]

    delete_response = await client.delete(
        f"/api/v1/chat/conversations/{conversation_id}",
        headers=headers,
    )
    assert delete_response.status_code == 204

    get_response = await client.get(
        f"/api/v1/chat/conversations/{conversation_id}",
        headers=headers,
    )
    assert get_response.status_code == 404


async def test_streaming_placeholders_exist(client, registered_user_tokens):
    headers = {"Authorization": f"Bearer {registered_user_tokens['access_token']}"}
    create = await client.post(
        "/api/v1/chat/conversations",
        headers=headers,
        json={"title": "Streaming", "initial_message": "Hello"},
    )
    conversation_id = create.json()["id"]

    stream_response = await client.get(f"/api/v1/chat/conversations/{conversation_id}/stream")
    assert stream_response.status_code == 200
    assert "text/event-stream" in stream_response.headers["content-type"]
    assert "placeholder" in stream_response.text
