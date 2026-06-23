from __future__ import annotations

from dataclasses import dataclass
from uuid import UUID


ROLE_PRIORITY = ["student", "guardian", "teacher", "counselor", "baha_admin", "administrator"]
ROLE_TO_AUDIENCE = {
    "student": "student",
    "guardian": "parent",
    "teacher": "teacher",
    "counselor": "counselor",
    "baha_admin": "counselor",
    "administrator": "counselor",
}


@dataclass(slots=True)
class ActorContext:
    user_id: UUID
    external_auth_id: str | None
    display_name: str
    roles: list[str]
    student_profile_id: UUID | None
    guardian_id: UUID | None
    teacher_profile_id: UUID | None
    age_cohort: str | None
    school_id: UUID | None

    @property
    def primary_role(self) -> str:
        for role in ROLE_PRIORITY:
            if role in self.roles:
                return role
        return self.roles[0] if self.roles else "student"

    @property
    def app_audience(self) -> str:
        return ROLE_TO_AUDIENCE.get(self.primary_role, "student")
