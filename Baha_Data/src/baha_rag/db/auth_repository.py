from __future__ import annotations

from datetime import datetime, timezone
from secrets import randbelow
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class AuthRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_account_context_by_user_id(self, user_id: UUID) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.email,
                  u.phone,
                  u.display_name,
                  u.status as account_status,
                  u.preferred_language,
                  sp.id as student_profile_id,
                  sp.student_code,
                  sp.presentation_age_cohort,
                  sp.legal_consent_band,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  tp.staff_code,
                  tp.staff_type,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status in ('active', 'inactive')
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where u.id = :user_id
                group by
                  u.id, sp.id, g.id, tp.id
                """
            ),
            {"user_id": user_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_account_context_by_external_auth_id(self, external_auth_id: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.email,
                  u.phone,
                  u.display_name,
                  u.status as account_status,
                  u.preferred_language,
                  sp.id as student_profile_id,
                  sp.student_code,
                  sp.presentation_age_cohort,
                  sp.legal_consent_band,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  tp.staff_code,
                  tp.staff_type,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status in ('active', 'inactive')
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where u.external_auth_id = :external_auth_id
                group by
                  u.id, sp.id, g.id, tp.id
                """
            ),
            {"external_auth_id": external_auth_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_account_context_by_unique_email(self, email: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.email,
                  u.phone,
                  u.display_name,
                  u.status as account_status,
                  u.preferred_language,
                  sp.id as student_profile_id,
                  sp.student_code,
                  sp.presentation_age_cohort,
                  sp.legal_consent_band,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  tp.staff_code,
                  tp.staff_type,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status in ('active', 'inactive')
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where lower(u.email) = lower(:email)
                group by
                  u.id, sp.id, g.id, tp.id
                order by u.created_at asc
                """
            ),
            {"email": email},
        )
        rows = result.mappings().all()
        if len(rows) != 1:
            return None
        return dict(rows[0])

    async def count_users_by_email(self, email: str) -> int:
        result = await self.session.execute(
            text("select count(*)::int from users where lower(email) = lower(:email)"),
            {"email": email},
        )
        return int(result.scalar_one())

    async def resolve_school_id(
        self,
        *,
        school_id: UUID | None,
        school_name: str | None,
        create_if_missing: bool,
    ) -> UUID | None:
        if school_id is not None:
            result = await self.session.execute(
                text("select id from schools where id = :school_id limit 1"),
                {"school_id": school_id},
            )
            row = result.mappings().first()
            return row["id"] if row else None

        normalized_name = (school_name or "").strip()
        if not normalized_name:
            return None

        result = await self.session.execute(
            text(
                """
                select id
                from schools
                where lower(name) = lower(:school_name)
                limit 1
                """
            ),
            {"school_name": normalized_name},
        )
        row = result.mappings().first()
        if row:
            return row["id"]

        if not create_if_missing:
            return None

        created = await self.session.execute(
            text(
                """
                insert into schools (name, status, metadata)
                values (
                  :school_name,
                  'active',
                  jsonb_build_object(
                    'created_via', 'auth_bootstrap',
                    'pending_review', true
                  )
                )
                returning id
                """
            ),
            {"school_name": normalized_name},
        )
        return created.scalar_one()

    async def upsert_user(
        self,
        *,
        user_id: UUID | None,
        external_auth_id: str,
        email: str | None,
        phone: str | None,
        display_name: str,
        preferred_language: str,
        status: str,
        metadata_json: str,
    ) -> UUID:
        if user_id is None:
            result = await self.session.execute(
                text(
                    """
                    insert into users (
                      external_auth_id,
                      email,
                      phone,
                      display_name,
                      status,
                      preferred_language,
                      metadata
                    )
                    values (
                      :external_auth_id,
                      :email,
                      :phone,
                      :display_name,
                      :status,
                      :preferred_language,
                      cast(:metadata as jsonb)
                    )
                    returning id
                    """
                ),
                {
                    "external_auth_id": external_auth_id,
                    "email": email,
                    "phone": phone,
                    "display_name": display_name,
                    "status": status,
                    "preferred_language": preferred_language,
                    "metadata": metadata_json,
                },
            )
            return result.scalar_one()

        await self.session.execute(
            text(
                """
                update users
                set
                  external_auth_id = :external_auth_id,
                  email = :email,
                  phone = :phone,
                  display_name = :display_name,
                  status = :status,
                  preferred_language = :preferred_language,
                  metadata = coalesce(users.metadata, '{}'::jsonb) || cast(:metadata as jsonb),
                  updated_at = now()
                where id = :user_id
                """
            ),
            {
                "user_id": user_id,
                "external_auth_id": external_auth_id,
                "email": email,
                "phone": phone,
                "display_name": display_name,
                "status": status,
                "preferred_language": preferred_language,
                "metadata": metadata_json,
            },
        )
        return user_id

    async def ensure_role_assignment(self, *, user_id: UUID, role_key: str, metadata_json: str = "{}") -> None:
        await self.session.execute(
            text(
                """
                insert into user_roles (user_id, role_id, status, metadata)
                select
                  :user_id,
                  r.id,
                  'active',
                  cast(:metadata as jsonb)
                from roles r
                where r.role_key = :role_key
                on conflict (user_id, role_id) do update
                set
                  status = 'active',
                  metadata = coalesce(user_roles.metadata, '{}'::jsonb) || excluded.metadata,
                  updated_at = now()
                """
            ),
            {"user_id": user_id, "role_key": role_key, "metadata": metadata_json},
        )

    async def upsert_student_profile(
        self,
        *,
        user_id: UUID,
        school_id: UUID,
        age_cohort: str,
        legal_consent_band: str,
        date_of_birth: str | None,
        gender: str,
        metadata_json: str,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into student_profiles (
                  user_id,
                  student_code,
                  school_id,
                  presentation_age_cohort,
                  legal_consent_band,
                  gender,
                  date_of_birth,
                  enrollment_status,
                  metadata
                )
                values (
                  :user_id,
                  concat('STU-', upper(substr(replace(:user_id_text, '-', ''), 1, 10))),
                  :school_id,
                  :age_cohort,
                  :legal_consent_band,
                  :gender,
                  :date_of_birth,
                  'active',
                  cast(:metadata as jsonb)
                )
                on conflict (user_id) do update
                set
                  school_id = excluded.school_id,
                  presentation_age_cohort = excluded.presentation_age_cohort,
                  legal_consent_band = excluded.legal_consent_band,
                  gender = excluded.gender,
                  date_of_birth = excluded.date_of_birth,
                  enrollment_status = 'active',
                  metadata = coalesce(student_profiles.metadata, '{}'::jsonb) || excluded.metadata,
                  updated_at = now()
                returning id
                """
            ),
            {
                "user_id": user_id,
                "user_id_text": str(user_id),
                "school_id": school_id,
                "age_cohort": age_cohort,
                "legal_consent_band": legal_consent_band,
                "date_of_birth": date_of_birth,
                "gender": gender,
                "metadata": metadata_json,
            },
        )
        return result.scalar_one()

    async def upsert_guardian_profile(
        self,
        *,
        user_id: UUID,
        guardian_type: str,
        metadata_json: str,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into guardians (user_id, guardian_type, metadata)
                values (
                  :user_id,
                  :guardian_type,
                  cast(:metadata as jsonb)
                )
                on conflict (user_id) do update
                set
                  guardian_type = excluded.guardian_type,
                  metadata = coalesce(guardians.metadata, '{}'::jsonb) || excluded.metadata,
                  updated_at = now()
                returning id
                """
            ),
            {"user_id": user_id, "guardian_type": guardian_type, "metadata": metadata_json},
        )
        return result.scalar_one()

    async def upsert_teacher_profile(
        self,
        *,
        user_id: UUID,
        school_id: UUID | None,
        staff_code: str | None,
        staff_type: str,
        metadata_json: str,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into teacher_profiles (user_id, school_id, staff_code, staff_type, metadata)
                values (
                  :user_id,
                  :school_id,
                  :staff_code,
                  :staff_type,
                  cast(:metadata as jsonb)
                )
                on conflict (user_id) do update
                set
                  school_id = excluded.school_id,
                  staff_code = excluded.staff_code,
                  staff_type = excluded.staff_type,
                  metadata = coalesce(teacher_profiles.metadata, '{}'::jsonb) || excluded.metadata,
                  updated_at = now()
                returning id
                """
            ),
            {
                "user_id": user_id,
                "school_id": school_id,
                "staff_code": staff_code,
                "staff_type": staff_type,
                "metadata": metadata_json,
            },
        )
        return result.scalar_one()

    async def create_or_refresh_approval_request(
        self,
        *,
        user_id: UUID,
        requested_role: str,
        school_id: UUID | None,
        metadata_json: str,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into approval_requests (
                  user_id,
                  requested_role,
                  school_id,
                  request_type,
                  status,
                  requested_metadata
                )
                values (
                  :user_id,
                  :requested_role,
                  :school_id,
                  'account_activation',
                  'pending',
                  cast(:metadata as jsonb)
                )
                on conflict (user_id, requested_role, request_type)
                where status = 'pending'
                do update set
                  school_id = excluded.school_id,
                  requested_metadata = excluded.requested_metadata,
                  requested_at = now(),
                  updated_at = now()
                returning id
                """
            ),
            {
                "user_id": user_id,
                "requested_role": requested_role,
                "school_id": school_id,
                "metadata": metadata_json,
            },
        )
        return result.scalar_one()

    async def get_latest_approval_request(self, *, user_id: UUID, requested_role: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  ar.id,
                  ar.user_id,
                  ar.requested_role,
                  ar.school_id,
                  ar.request_type,
                  ar.status,
                  ar.requested_metadata,
                  ar.reviewer_user_id,
                  ar.reviewer_notes,
                  ar.requested_at,
                  ar.reviewed_at
                from approval_requests ar
                where ar.user_id = :user_id
                  and ar.requested_role = :requested_role
                order by coalesce(ar.reviewed_at, ar.requested_at) desc
                limit 1
                """
            ),
            {"user_id": user_id, "requested_role": requested_role},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def list_approval_requests_for_reviewer(
        self,
        *,
        reviewer_role: str,
        reviewer_school_id: UUID | None,
        status: str,
    ) -> list[dict[str, Any]]:
        params: dict[str, Any] = {"status": status}
        where_clauses = ["ar.status = :status"]
        if reviewer_role == "administrator":
            where_clauses.append("ar.requested_role = 'teacher'")
            where_clauses.append("ar.school_id = :reviewer_school_id")
            params["reviewer_school_id"] = reviewer_school_id

        result = await self.session.execute(
            text(
                f"""
                select
                  ar.id,
                  ar.user_id,
                  ar.requested_role,
                  ar.school_id,
                  sch.name as school_name,
                  ar.request_type,
                  ar.status,
                  ar.requested_metadata,
                  ar.reviewer_user_id,
                  reviewer.display_name as reviewer_name,
                  ar.reviewer_notes,
                  ar.requested_at,
                  ar.reviewed_at,
                  u.display_name as requested_display_name,
                  u.email as requested_email
                from approval_requests ar
                join users u on u.id = ar.user_id
                left join users reviewer on reviewer.id = ar.reviewer_user_id
                left join schools sch on sch.id = ar.school_id
                where {' and '.join(where_clauses)}
                order by ar.requested_at desc
                """
            ),
            params,
        )
        return [dict(row) for row in result.mappings().all()]

    async def decide_approval_request(
        self,
        *,
        request_id: UUID,
        reviewer_user_id: UUID,
        reviewer_notes: str | None,
        status: str,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                update approval_requests
                set
                  status = :status,
                  reviewer_user_id = :reviewer_user_id,
                  reviewer_notes = :reviewer_notes,
                  reviewed_at = now(),
                  updated_at = now()
                where id = :request_id
                  and status = 'pending'
                returning user_id, requested_role, school_id, status
                """
            ),
            {
                "request_id": request_id,
                "reviewer_user_id": reviewer_user_id,
                "reviewer_notes": reviewer_notes,
                "status": status,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_approval_request_by_id(self, *, request_id: UUID) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  ar.id,
                  ar.user_id,
                  ar.requested_role,
                  ar.school_id,
                  ar.request_type,
                  ar.status,
                  ar.requested_metadata,
                  ar.reviewer_user_id,
                  ar.reviewer_notes,
                  ar.requested_at,
                  ar.reviewed_at
                from approval_requests ar
                where ar.id = :request_id
                limit 1
                """
            ),
            {"request_id": request_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def set_user_status(self, *, user_id: UUID, status: str) -> None:
        await self.session.execute(
            text(
                """
                update users
                set
                  status = :status,
                  updated_at = now()
                where id = :user_id
                """
            ),
            {"user_id": user_id, "status": status},
        )

    async def get_student_for_link(
        self,
        *,
        student_profile_id: UUID | None,
        student_code: str | None,
    ) -> dict[str, Any] | None:
        if student_profile_id is None and not student_code:
            return None
        if student_profile_id is not None:
            query = text(
                """
                select
                  sp.id as student_profile_id,
                  sp.user_id as student_user_id,
                  sp.student_code,
                  sp.presentation_age_cohort,
                  sp.legal_consent_band,
                  sp.metadata
                from student_profiles sp
                where sp.id = :student_profile_id
                limit 1
                """
            )
            params = {"student_profile_id": student_profile_id}
        else:
            query = text(
                """
                select
                  sp.id as student_profile_id,
                  sp.user_id as student_user_id,
                  sp.student_code,
                  sp.presentation_age_cohort,
                  sp.legal_consent_band,
                  sp.metadata
                from student_profiles sp
                where sp.student_code = :student_code
                limit 1
                """
            )
            params = {"student_code": student_code}
        result = await self.session.execute(
            query,
            params,
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def ensure_student_guardian_link_code(
        self,
        *,
        student_profile_id: UUID,
    ) -> str:
        result = await self.session.execute(
            text(
                """
                select metadata ->> 'guardian_link_verification_code' as guardian_link_verification_code
                from student_profiles
                where id = :student_profile_id
                limit 1
                """
            ),
            {"student_profile_id": student_profile_id},
        )
        row = result.mappings().first()
        existing_code = (
            str(row["guardian_link_verification_code"]).strip()
            if row and row["guardian_link_verification_code"]
            else ""
        )
        if existing_code:
            return existing_code

        code = f"{randbelow(1_000_000):06d}"
        await self.session.execute(
            text(
                """
                update student_profiles
                set
                  metadata = jsonb_set(
                    coalesce(metadata, '{}'::jsonb),
                    '{guardian_link_verification_code}',
                    to_jsonb(:code::text),
                    true
                  ),
                  updated_at = now()
                where id = :student_profile_id
                """
            ),
            {"student_profile_id": student_profile_id, "code": code},
        )
        return code

    async def upsert_guardian_link(
        self,
        *,
        student_profile_id: UUID,
        guardian_id: UUID,
        relationship_to_student: str,
        is_primary: bool,
        consent_authority: bool,
    ) -> None:
        if is_primary:
            await self.session.execute(
                text(
                    """
                    update student_guardian_links
                    set
                      is_primary = false,
                      updated_at = now()
                    where student_profile_id = :student_profile_id
                      and guardian_id <> :guardian_id
                    """
                ),
                {"student_profile_id": student_profile_id, "guardian_id": guardian_id},
            )
        await self.session.execute(
            text(
                """
                insert into student_guardian_links (
                  student_profile_id,
                  guardian_id,
                  relationship_to_student,
                  is_primary,
                  consent_authority,
                  status,
                  metadata
                )
                values (
                  :student_profile_id,
                  :guardian_id,
                  :relationship_to_student,
                  :is_primary,
                  :consent_authority,
                  'active',
                  '{}'::jsonb
                )
                on conflict (student_profile_id, guardian_id) do update
                set
                  relationship_to_student = excluded.relationship_to_student,
                  is_primary = excluded.is_primary,
                  consent_authority = excluded.consent_authority,
                  status = 'active',
                  updated_at = now()
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "guardian_id": guardian_id,
                "relationship_to_student": relationship_to_student,
                "is_primary": is_primary,
                "consent_authority": consent_authority,
            },
        )

    async def get_active_guardian_link(
        self,
        *,
        student_profile_id: UUID,
        guardian_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  relationship_to_student,
                  consent_authority
                from student_guardian_links
                where student_profile_id = :student_profile_id
                  and guardian_id = :guardian_id
                  and status = 'active'
                limit 1
                """
            ),
            {"student_profile_id": student_profile_id, "guardian_id": guardian_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_latest_active_consent_version(self, *, consent_type: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select id, consent_type, version_label
                from consent_versions
                where consent_type = :consent_type
                  and active = true
                order by effective_from desc
                limit 1
                """
            ),
            {"consent_type": consent_type},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def create_platform_participation_consent(
        self,
        *,
        consent_version_id: UUID,
        student_user_id: UUID,
        guardian_user_id: UUID,
        student_profile_id: UUID,
        guardian_id: UUID,
        actor_relationship: str | None,
        status: str,
    ) -> None:
        now = datetime.now(timezone.utc)
        granted_at = now if status == "granted" else None
        withdrawn_at = now if status == "withdrawn" else None
        await self.session.execute(
            text(
                """
                insert into consent_records (
                  consent_version_id,
                  subject_user_id,
                  actor_user_id,
                  student_profile_id,
                  guardian_id,
                  consent_type,
                  actor_relationship,
                  scope,
                  status,
                  granted_at,
                  withdrawn_at,
                  metadata
                )
                values (
                  :consent_version_id,
                  :student_user_id,
                  :guardian_user_id,
                  :student_profile_id,
                  :guardian_id,
                  'platform_participation',
                  :actor_relationship,
                  'general',
                  :status,
                  :granted_at,
                  :withdrawn_at,
                  jsonb_build_object('created_via', 'auth_guardian_consent')
                )
                """
            ),
            {
                "consent_version_id": consent_version_id,
                "student_user_id": student_user_id,
                "guardian_user_id": guardian_user_id,
                "student_profile_id": student_profile_id,
                "guardian_id": guardian_id,
                "actor_relationship": actor_relationship,
                "status": status,
                "granted_at": granted_at,
                "withdrawn_at": withdrawn_at,
            },
        )

    async def get_latest_platform_participation_consent(self, *, student_user_id: UUID) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  cr.status,
                  cr.granted_at,
                  cr.withdrawn_at
                from consent_records cr
                where cr.subject_user_id = :student_user_id
                  and cr.consent_type = 'platform_participation'
                order by coalesce(cr.granted_at, cr.withdrawn_at, cr.created_at) desc
                limit 1
                """
            ),
            {"student_user_id": student_user_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def create_parent_summary_sharing_consent(
        self,
        *,
        consent_version_id: UUID,
        student_user_id: UUID,
        guardian_user_id: UUID,
        student_profile_id: UUID,
        guardian_id: UUID,
        actor_relationship: str | None,
        status: str,
    ) -> None:
        now = datetime.now(timezone.utc)
        granted_at = now if status == "granted" else None
        withdrawn_at = now if status == "withdrawn" else None
        await self.session.execute(
            text(
                """
                insert into consent_records (
                  consent_version_id,
                  subject_user_id,
                  actor_user_id,
                  student_profile_id,
                  guardian_id,
                  consent_type,
                  actor_relationship,
                  scope,
                  status,
                  granted_at,
                  withdrawn_at,
                  metadata
                )
                values (
                  :consent_version_id,
                  :student_user_id,
                  :guardian_user_id,
                  :student_profile_id,
                  :guardian_id,
                  'parent_summary_sharing',
                  :actor_relationship,
                  'weekly_summaries',
                  :status,
                  :granted_at,
                  :withdrawn_at,
                  jsonb_build_object('created_via', 'auth_guardian_parent_summary_consent')
                )
                """
            ),
            {
                "consent_version_id": consent_version_id,
                "student_user_id": student_user_id,
                "guardian_user_id": guardian_user_id,
                "student_profile_id": student_profile_id,
                "guardian_id": guardian_id,
                "actor_relationship": actor_relationship,
                "status": status,
                "granted_at": granted_at,
                "withdrawn_at": withdrawn_at,
            },
        )

    async def get_latest_parent_summary_sharing_consent(
        self,
        *,
        student_profile_id: UUID,
        guardian_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  'parent_summary_sharing' as consent_type,
                  cr.consent_version_id,
                  cr.student_profile_id,
                  cr.guardian_id,
                  cr.status,
                  cr.scope,
                  cr.actor_relationship,
                  cr.granted_at,
                  cr.withdrawn_at,
                  cr.created_at
                from consent_records cr
                where cr.student_profile_id = :student_profile_id
                  and cr.guardian_id = :guardian_id
                  and cr.consent_type = 'parent_summary_sharing'
                order by coalesce(cr.granted_at, cr.withdrawn_at, cr.created_at) desc
                limit 1
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "guardian_id": guardian_id,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def count_active_guardian_links_for_student(self, *, student_profile_id: UUID) -> int:
        result = await self.session.execute(
            text(
                """
                select count(*)::int
                from student_guardian_links
                where student_profile_id = :student_profile_id
                  and status = 'active'
                """
            ),
            {"student_profile_id": student_profile_id},
        )
        return int(result.scalar_one())

    async def count_active_linked_students_for_guardian(self, *, guardian_id: UUID) -> int:
        result = await self.session.execute(
            text(
                """
                select count(*)::int
                from student_guardian_links
                where guardian_id = :guardian_id
                  and status = 'active'
                """
            ),
            {"guardian_id": guardian_id},
        )
        return int(result.scalar_one())
