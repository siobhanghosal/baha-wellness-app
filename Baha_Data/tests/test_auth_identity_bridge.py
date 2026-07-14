from uuid import uuid4

import pytest
from fastapi import HTTPException

from baha_rag import auth
from baha_rag.config import Settings
from baha_rag.identity import ActorContext


def _actor(*, external_auth_id: str | None = None) -> ActorContext:
    return ActorContext(
        user_id=uuid4(),
        external_auth_id=external_auth_id,
        display_name="Demo User",
        roles=["student"],
        student_profile_id=uuid4(),
        guardian_id=None,
        teacher_profile_id=None,
        age_cohort="13_14",
        school_id=uuid4(),
        school_name="BAHA Pilot School",
        user_metadata={},
        student_metadata={},
    )


@pytest.mark.asyncio
async def test_get_actor_context_links_token_subject_from_email_match(monkeypatch: pytest.MonkeyPatch) -> None:
    linked_actor = _actor(external_auth_id="supabase-user-123")
    initial_actor = _actor(external_auth_id=None)
    user_id = initial_actor.user_id
    linked_actor = ActorContext(
        user_id=user_id,
        external_auth_id="supabase-user-123",
        display_name=initial_actor.display_name,
        roles=initial_actor.roles,
        student_profile_id=initial_actor.student_profile_id,
        guardian_id=initial_actor.guardian_id,
        teacher_profile_id=initial_actor.teacher_profile_id,
        age_cohort=initial_actor.age_cohort,
        school_id=initial_actor.school_id,
        school_name=initial_actor.school_name,
        user_metadata=initial_actor.user_metadata,
        student_metadata=initial_actor.student_metadata,
    )

    class FakeRepository:
        def __init__(self, _session: object) -> None:
            self.bound: tuple[str, str] | None = None

        async def get_actor_context_by_user_id(self, user_id: object) -> ActorContext | None:
            if user_id == linked_actor.user_id:
                return linked_actor
            return None

        async def get_actor_context_by_external_auth_id(self, external_auth_id: str) -> ActorContext | None:
            if external_auth_id == "supabase-user-123" and self.bound is not None:
                return linked_actor
            return None

        async def count_active_users_by_email(self, email: str) -> int:
            assert email == "student.demo@baha.local"
            return 1

        async def get_actor_context_by_email(self, email: str) -> ActorContext | None:
            assert email == "student.demo@baha.local"
            return initial_actor

        async def bind_external_auth_id(self, *, user_id: object, external_auth_id: str) -> bool:
            self.bound = (str(user_id), external_auth_id)
            return user_id == linked_actor.user_id and external_auth_id == "supabase-user-123"

    async def fake_identity_from_authorization(_authorization: str | None, _settings: Settings) -> auth.TokenIdentity:
        return auth.TokenIdentity(subject="supabase-user-123", email="student.demo@baha.local")

    monkeypatch.setattr(auth, "MobileAppRepository", FakeRepository)
    monkeypatch.setattr(auth, "_identity_from_authorization", fake_identity_from_authorization)

    actor = await auth.get_actor_context(
        session=object(),
        settings=Settings(),
        authorization="Bearer token",
    )

    assert actor.user_id == linked_actor.user_id
    assert actor.external_auth_id == "supabase-user-123"


@pytest.mark.asyncio
async def test_get_actor_context_rejects_duplicate_email_auto_linking(monkeypatch: pytest.MonkeyPatch) -> None:
    class FakeRepository:
        def __init__(self, _session: object) -> None:
            pass

        async def get_actor_context_by_user_id(self, user_id: object) -> ActorContext | None:
            return None

        async def get_actor_context_by_external_auth_id(self, external_auth_id: str) -> ActorContext | None:
            return None

        async def count_active_users_by_email(self, email: str) -> int:
            assert email == "student.demo@baha.local"
            return 2

        async def get_actor_context_by_email(self, email: str) -> ActorContext | None:
            raise AssertionError("email lookup should not run when duplicates exist")

        async def bind_external_auth_id(self, *, user_id: object, external_auth_id: str) -> bool:
            raise AssertionError("binding should not run when duplicates exist")

    async def fake_identity_from_authorization(_authorization: str | None, _settings: Settings) -> auth.TokenIdentity:
        return auth.TokenIdentity(subject="supabase-user-123", email="student.demo@baha.local")

    monkeypatch.setattr(auth, "MobileAppRepository", FakeRepository)
    monkeypatch.setattr(auth, "_identity_from_authorization", fake_identity_from_authorization)

    with pytest.raises(HTTPException) as exc_info:
        await auth.get_actor_context(
            session=object(),
            settings=Settings(),
            authorization="Bearer token",
        )

    assert exc_info.value.status_code == 409
    assert exc_info.value.detail == "Multiple active BAHA users share this email; manual identity linking is required"
