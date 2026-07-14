from uuid import uuid4

from baha_rag.identity import ActorContext


def test_actor_context_primary_role_maps_to_mobile_audience() -> None:
    actor = ActorContext(
        user_id=uuid4(),
        external_auth_id="auth-user-1",
        display_name="Student Test",
        roles=["guardian", "student"],
        student_profile_id=uuid4(),
        guardian_id=uuid4(),
        teacher_profile_id=None,
        age_cohort="13_14",
        school_id=uuid4(),
        school_name="BAHA Pilot School",
        user_metadata={},
        student_metadata={},
    )

    assert actor.primary_role == "student"
    assert actor.app_audience == "student"


def test_actor_context_guardian_maps_to_parent_audience() -> None:
    actor = ActorContext(
        user_id=uuid4(),
        external_auth_id=None,
        display_name="Parent Test",
        roles=["guardian"],
        student_profile_id=None,
        guardian_id=uuid4(),
        teacher_profile_id=None,
        age_cohort=None,
        school_id=None,
        school_name=None,
        user_metadata={},
        student_metadata={},
    )

    assert actor.primary_role == "guardian"
    assert actor.app_audience == "parent"
