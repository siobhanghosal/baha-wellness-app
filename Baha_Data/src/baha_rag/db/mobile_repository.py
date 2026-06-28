from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.identity import ActorContext


class MobileAppRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_actor_context_by_user_id(self, user_id: UUID) -> ActorContext | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.display_name,
                  sp.id as student_profile_id,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  sp.presentation_age_cohort,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status = 'active'
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where u.id = :user_id and u.status = 'active'
                group by
                  u.id, u.external_auth_id, u.display_name,
                  sp.id, g.id, tp.id, sp.presentation_age_cohort, coalesce(sp.school_id, tp.school_id)
                """
            ),
            {"user_id": user_id},
        )
        row = result.mappings().first()
        return self._row_to_actor_context(row) if row else None

    async def get_actor_context_by_external_auth_id(self, external_auth_id: str) -> ActorContext | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.display_name,
                  sp.id as student_profile_id,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  sp.presentation_age_cohort,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status = 'active'
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where u.external_auth_id = :external_auth_id and u.status = 'active'
                group by
                  u.id, u.external_auth_id, u.display_name,
                  sp.id, g.id, tp.id, sp.presentation_age_cohort, coalesce(sp.school_id, tp.school_id)
                """
            ),
            {"external_auth_id": external_auth_id},
        )
        row = result.mappings().first()
        return self._row_to_actor_context(row) if row else None

    async def get_actor_context_by_email(self, email: str) -> ActorContext | None:
        result = await self.session.execute(
            text(
                """
                select
                  u.id as user_id,
                  u.external_auth_id,
                  u.display_name,
                  sp.id as student_profile_id,
                  g.id as guardian_id,
                  tp.id as teacher_profile_id,
                  sp.presentation_age_cohort,
                  coalesce(sp.school_id, tp.school_id) as school_id,
                  array_remove(array_agg(distinct r.role_key), null) as roles
                from users u
                left join user_roles ur
                  on ur.user_id = u.id and ur.status = 'active'
                left join roles r
                  on r.id = ur.role_id
                left join student_profiles sp
                  on sp.user_id = u.id and sp.enrollment_status = 'active'
                left join guardians g
                  on g.user_id = u.id
                left join teacher_profiles tp
                  on tp.user_id = u.id
                where lower(u.email) = lower(:email) and u.status = 'active'
                group by
                  u.id, u.external_auth_id, u.display_name,
                  sp.id, g.id, tp.id, sp.presentation_age_cohort, coalesce(sp.school_id, tp.school_id)
                order by u.created_at asc
                """
            ),
            {"email": email},
        )
        rows = result.mappings().all()
        if len(rows) != 1:
            return None
        return self._row_to_actor_context(rows[0])

    async def count_active_users_by_email(self, email: str) -> int:
        result = await self.session.execute(
            text(
                """
                select count(*)::int
                from users
                where lower(email) = lower(:email)
                  and status = 'active'
                """
            ),
            {"email": email},
        )
        return int(result.scalar_one())

    async def bind_external_auth_id(
        self,
        *,
        user_id: UUID,
        external_auth_id: str,
    ) -> bool:
        result = await self.session.execute(
            text(
                """
                update users
                set
                  external_auth_id = :external_auth_id,
                  updated_at = now()
                where id = :user_id
                  and status = 'active'
                  and (
                    external_auth_id is null
                    or external_auth_id = :external_auth_id
                  )
                """
            ),
            {"user_id": user_id, "external_auth_id": external_auth_id},
        )
        return result.rowcount > 0

    async def list_student_checkin_templates(self, *, age_cohort: str | None) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  ct.id,
                  ct.template_key,
                  ct.title,
                  ct.cadence,
                  ct.age_cohort,
                  ct.metadata,
                  count(cq.id) as question_count
                from checkin_templates ct
                left join checkin_questions cq
                  on cq.template_id = ct.id
                where ct.active = true
                  and ct.audience_app = 'student'
                  and (
                    ct.age_cohort = 'all'
                    or cast(:age_cohort as text) is null
                    or ct.age_cohort = cast(:age_cohort as text)
                  )
                group by ct.id, ct.template_key, ct.title, ct.cadence, ct.age_cohort, ct.metadata
                order by
                  case when ct.age_cohort = cast(:age_cohort as text) then 0 else 1 end,
                  ct.template_key
                """
            ),
            {"age_cohort": age_cohort},
        )
        return [dict(row) for row in result.mappings().all()]

    async def get_student_checkin_template_detail(
        self,
        *,
        template_id: UUID,
        age_cohort: str | None,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  ct.id,
                  ct.template_key,
                  ct.title,
                  ct.cadence,
                  ct.age_cohort,
                  ct.metadata,
                  coalesce(
                    jsonb_agg(
                      jsonb_build_object(
                        'id', cq.id,
                        'question_key', cq.question_key,
                        'dimension', cq.dimension,
                        'question_type', cq.question_type,
                        'prompt', cq.prompt,
                        'response_config', cq.response_config,
                        'is_required', cq.is_required,
                        'ordinal', cq.ordinal,
                        'metadata', cq.metadata
                      )
                      order by cq.ordinal
                    ) filter (where cq.id is not null),
                    '[]'::jsonb
                  ) as questions
                from checkin_templates ct
                left join checkin_questions cq
                  on cq.template_id = ct.id
                where ct.id = :template_id
                  and ct.active = true
                  and ct.audience_app = 'student'
                  and (
                    ct.age_cohort = 'all'
                    or cast(:age_cohort as text) is null
                    or ct.age_cohort = cast(:age_cohort as text)
                  )
                group by ct.id, ct.template_key, ct.title, ct.cadence, ct.age_cohort, ct.metadata
                """
            ),
            {"template_id": template_id, "age_cohort": age_cohort},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def list_student_modules(
        self,
        *,
        user_id: UUID,
        student_profile_id: UUID | None,
        age_cohort: str | None,
        theme: str | None = None,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  lm.id,
                  lm.content_item_id,
                  lm.module_code,
                  ci.title,
                  lm.theme,
                  lm.age_cohort,
                  lm.estimated_minutes,
                  lm.sort_order,
                  coalesce(mp.status, 'not_started') as progress_status,
                  coalesce(mp.completion_percent, 0) as completion_percent,
                  mp.current_section_ordinal,
                  mp.current_step_ordinal,
                  mp.last_activity_at,
                  mp.id as module_progress_id,
                  coalesce(section_stats.total_sections, 0) as total_sections,
                  coalesce(step_stats.total_steps, 0) as total_steps
                from learning_modules lm
                join content_items ci
                  on ci.id = lm.content_item_id
                left join lateral (
                  select count(*)::int as total_sections
                  from learning_module_sections lms
                  where lms.module_id = lm.id
                ) section_stats on true
                left join lateral (
                  select count(*)::int as total_steps
                  from learning_module_sections lms
                  join learning_module_steps lmst
                    on lmst.section_id = lms.id
                  where lms.module_id = lm.id
                ) step_stats on true
                left join lateral (
                  select mp_inner.*
                  from module_progress mp_inner
                  where mp_inner.module_id = lm.id
                    and mp_inner.user_id = :user_id
                    and mp_inner.audience_app = 'student'
                    and (
                      (cast(:student_profile_id as uuid) is null and mp_inner.context_student_profile_id is null)
                      or mp_inner.context_student_profile_id = cast(:student_profile_id as uuid)
                    )
                  order by mp_inner.updated_at desc
                  limit 1
                ) mp on true
                where lm.active = true
                  and lm.role_track = 'student'
                  and ci.lifecycle_status = 'active'
                  and ci.review_status = 'approved'
                  and (
                    lm.age_cohort = 'all'
                    or cast(:age_cohort as text) is null
                    or lm.age_cohort = cast(:age_cohort as text)
                  )
                  and (
                    cast(:theme as text) is null
                    or lower(lm.theme) = lower(cast(:theme as text))
                    or lower(coalesce(ci.theme, '')) = lower(cast(:theme as text))
                  )
                order by lm.sort_order, lm.module_code
                """
            ),
            {
                "user_id": user_id,
                "student_profile_id": student_profile_id,
                "age_cohort": age_cohort,
                "theme": theme,
            },
        )
        return [dict(row) for row in result.mappings().all()]

    async def upsert_student_module_progress(
        self,
        *,
        user_id: UUID,
        student_profile_id: UUID | None,
        module_id: UUID,
        status: str,
        completion_percent: float,
        current_section_ordinal: int | None,
        current_step_ordinal: int | None,
    ) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        existing = await self.session.execute(
            text(
                """
                select id, started_at, completed_at
                from module_progress
                where user_id = :user_id
                  and module_id = :module_id
                  and audience_app = 'student'
                  and (
                    (cast(:student_profile_id as uuid) is null and context_student_profile_id is null)
                    or context_student_profile_id = cast(:student_profile_id as uuid)
                  )
                order by updated_at desc
                limit 1
                """
            ),
            {
                "user_id": user_id,
                "module_id": module_id,
                "student_profile_id": student_profile_id,
            },
        )
        row = existing.mappings().first()

        if row:
            started_at = row["started_at"] or (now if status in {"in_progress", "completed"} else None)
            completed_at = now if status == "completed" else None
            result = await self.session.execute(
                text(
                    """
                    update module_progress
                    set
                      status = :status,
                      completion_percent = :completion_percent,
                      current_section_ordinal = :current_section_ordinal,
                      current_step_ordinal = :current_step_ordinal,
                      last_activity_at = :now,
                      started_at = :started_at,
                      completed_at = :completed_at,
                      updated_at = :now
                    where id = :id
                    returning id, status, completion_percent, current_section_ordinal,
                              current_step_ordinal, last_activity_at, updated_at
                    """
                ),
                {
                    "id": row["id"],
                    "status": status,
                    "completion_percent": completion_percent,
                    "current_section_ordinal": current_section_ordinal,
                    "current_step_ordinal": current_step_ordinal,
                    "started_at": started_at,
                    "completed_at": completed_at,
                    "now": now,
                },
            )
        else:
            result = await self.session.execute(
                text(
                    """
                    insert into module_progress (
                      user_id,
                      context_student_profile_id,
                      module_id,
                      audience_app,
                      status,
                      started_at,
                      completed_at,
                      last_activity_at,
                      completion_percent,
                      current_section_ordinal,
                      current_step_ordinal
                    )
                    values (
                      :user_id,
                      :student_profile_id,
                      :module_id,
                      'student',
                      :status,
                      :started_at,
                      :completed_at,
                      :now,
                      :completion_percent,
                      :current_section_ordinal,
                      :current_step_ordinal
                    )
                    returning id, status, completion_percent, current_section_ordinal,
                              current_step_ordinal, last_activity_at, updated_at
                    """
                ),
                {
                    "user_id": user_id,
                    "student_profile_id": student_profile_id,
                    "module_id": module_id,
                    "status": status,
                    "started_at": now if status in {"in_progress", "completed"} else None,
                    "completed_at": now if status == "completed" else None,
                    "now": now,
                    "completion_percent": completion_percent,
                    "current_section_ordinal": current_section_ordinal,
                    "current_step_ordinal": current_step_ordinal,
                },
            )
        return dict(result.mappings().one())

    async def list_chat_sessions(
        self,
        *,
        user_id: UUID,
        audience_app: str,
        student_profile_id: UUID | None,
        limit: int,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  session_type,
                  status,
                  safety_disposition,
                  started_at,
                  ended_at,
                  last_message_at,
                  message_count,
                  summary_visibility_scope
                from chat_sessions
                where user_id = :user_id
                  and audience_app = :audience_app
                  and (
                    (cast(:student_profile_id as uuid) is null and context_student_profile_id is null)
                    or context_student_profile_id = cast(:student_profile_id as uuid)
                  )
                order by coalesce(last_message_at, started_at) desc
                limit :limit
                """
            ),
            {
                "user_id": user_id,
                "audience_app": audience_app,
                "student_profile_id": student_profile_id,
                "limit": limit,
            },
        )
        return [dict(row) for row in result.mappings().all()]

    async def create_chat_session(
        self,
        *,
        user_id: UUID,
        audience_app: str,
        student_profile_id: UUID | None,
        session_type: str,
        summary_visibility_scope: str,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into chat_sessions (
                  user_id,
                  context_student_profile_id,
                  audience_app,
                  session_type,
                  summary_visibility_scope
                )
                values (
                  :user_id,
                  :student_profile_id,
                  :audience_app,
                  :session_type,
                  :summary_visibility_scope
                )
                returning
                  id,
                  session_type,
                  status,
                  safety_disposition,
                  started_at,
                  ended_at,
                  last_message_at,
                  message_count,
                  summary_visibility_scope
                """
            ),
            {
                "user_id": user_id,
                "student_profile_id": student_profile_id,
                "audience_app": audience_app,
                "session_type": session_type,
                "summary_visibility_scope": summary_visibility_scope,
            },
        )
        return dict(result.mappings().one())

    async def list_student_checkins(
        self,
        *,
        student_profile_id: UUID,
        limit: int,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  crs.id,
                  crs.template_id,
                  ct.template_key,
                  ct.title,
                  crs.scheduled_for,
                  crs.submitted_at,
                  crs.status,
                  crs.source_mode,
                  crs.visibility_scope,
                  count(cr.id) as response_count
                from checkin_response_sets crs
                join checkin_templates ct on ct.id = crs.template_id
                left join checkin_responses cr on cr.response_set_id = crs.id
                where crs.student_profile_id = :student_profile_id
                group by crs.id, ct.template_key, ct.title
                order by coalesce(crs.submitted_at, crs.created_at) desc
                limit :limit
                """
            ),
            {"student_profile_id": student_profile_id, "limit": limit},
        )
        return [dict(row) for row in result.mappings().all()]

    async def get_student_checkin_detail(
        self,
        *,
        student_profile_id: UUID,
        response_set_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  crs.id,
                  crs.template_id,
                  ct.template_key,
                  ct.title,
                  crs.scheduled_for,
                  crs.submitted_at,
                  crs.status,
                  crs.source_mode,
                  crs.visibility_scope,
                  coalesce(
                    jsonb_agg(
                      jsonb_build_object(
                        'question_id', cq.id,
                        'question_key', cq.question_key,
                        'prompt', cq.prompt,
                        'dimension', cq.dimension,
                        'question_type', cq.question_type,
                        'numeric_value', cr.numeric_value,
                        'text_value', cr.text_value,
                        'boolean_value', cr.boolean_value,
                        'selected_options', cr.selected_options,
                        'normalized_value', cr.normalized_value
                      )
                      order by cq.ordinal
                    ) filter (where cq.id is not null),
                    '[]'::jsonb
                  ) as answers
                from checkin_response_sets crs
                join checkin_templates ct on ct.id = crs.template_id
                left join checkin_responses cr on cr.response_set_id = crs.id
                left join checkin_questions cq on cq.id = cr.question_id
                where crs.student_profile_id = :student_profile_id
                  and crs.id = :response_set_id
                group by crs.id, ct.template_key, ct.title
                """
            ),
            {"student_profile_id": student_profile_id, "response_set_id": response_set_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def get_latest_student_weekly_summary(
        self,
        *,
        student_profile_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  student_profile_id,
                  week_start,
                  week_end,
                  privacy_tier_applied,
                  summary_status,
                  summary,
                  source_window,
                  generation_version,
                  generated_at
                from student_weekly_summaries
                where student_profile_id = :student_profile_id
                order by week_end desc, generated_at desc
                limit 1
                """
            ),
            {"student_profile_id": student_profile_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def submit_student_checkin(
        self,
        *,
        student_profile_id: UUID,
        template_id: UUID,
        source_mode: str,
        visibility_scope: str,
        answers: list[dict[str, Any]],
    ) -> dict[str, Any]:
        response_set = await self.session.execute(
            text(
                """
                insert into checkin_response_sets (
                  student_profile_id,
                  template_id,
                  submitted_at,
                  status,
                  source_mode,
                  visibility_scope
                )
                values (
                  :student_profile_id,
                  :template_id,
                  :submitted_at,
                  'submitted',
                  :source_mode,
                  :visibility_scope
                )
                returning id, template_id, submitted_at, status, source_mode, visibility_scope
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "template_id": template_id,
                "submitted_at": datetime.now(timezone.utc),
                "source_mode": source_mode,
                "visibility_scope": visibility_scope,
            },
        )
        response_set_row = response_set.mappings().one()
        response_set_id = response_set_row["id"]
        for answer in answers:
            await self.session.execute(
                text(
                    """
                    insert into checkin_responses (
                      response_set_id,
                      question_id,
                      numeric_value,
                      text_value,
                      boolean_value,
                      selected_options,
                      normalized_value
                    )
                    values (
                      :response_set_id,
                      :question_id,
                      :numeric_value,
                      :text_value,
                      :boolean_value,
                      cast(:selected_options as jsonb),
                      cast(:normalized_value as jsonb)
                    )
                    """
                ),
                {
                    "response_set_id": response_set_id,
                    "question_id": answer["question_id"],
                    "numeric_value": answer.get("numeric_value"),
                    "text_value": answer.get("text_value"),
                    "boolean_value": answer.get("boolean_value"),
                    "selected_options": answer.get("selected_options_json", "[]"),
                    "normalized_value": answer.get("normalized_value_json", "{}"),
                },
            )
        return dict(response_set_row)

    async def list_parent_linked_students(self, *, guardian_id: UUID) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  sp.id as student_profile_id,
                  u.display_name as student_name,
                  sp.presentation_age_cohort as age_cohort,
                  sgl.relationship_to_student,
                  sgl.is_primary,
                  sch.name as school_name
                from student_guardian_links sgl
                join student_profiles sp on sp.id = sgl.student_profile_id
                join users u on u.id = sp.user_id
                left join schools sch on sch.id = sp.school_id
                where sgl.guardian_id = :guardian_id
                  and sgl.status = 'active'
                order by u.display_name
                """
            ),
            {"guardian_id": guardian_id},
        )
        return [dict(row) for row in result.mappings().all()]

    async def get_latest_parent_summary(
        self,
        *,
        guardian_id: UUID,
        student_profile_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  pws.id,
                  pws.student_profile_id,
                  pws.guardian_id,
                  pws.week_start,
                  pws.week_end,
                  pws.consent_status,
                  pws.visible_tiers,
                  pws.summary,
                  pws.generated_at
                from parent_weekly_summaries pws
                where pws.guardian_id = :guardian_id
                  and pws.student_profile_id = :student_profile_id
                order by pws.week_end desc, pws.generated_at desc
                limit 1
                """
            ),
            {"guardian_id": guardian_id, "student_profile_id": student_profile_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def list_published_content(
        self,
        *,
        audience_app: str,
        age_cohort: str | None,
        content_type: str | None,
        theme: str | None,
        topic: str | None,
        subtopic: str | None,
        limit: int,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  ci.id,
                  ci.slug,
                  ci.title,
                  ci.content_type,
                  ci.audience_app,
                  ci.age_cohort,
                  ci.theme,
                  ci.topic,
                  ci.subtopic,
                  ci.summary,
                  ci.metadata,
                  pv.version_id,
                  pv.version_number,
                  pv.plain_text,
                  pv.published_at
                from content_items ci
                join lateral (
                  select
                    cv_inner.id as version_id,
                    cv_inner.version_number,
                    cv_inner.plain_text,
                    coalesce(
                      cpt_inner.effective_from,
                      cv_inner.effective_from,
                      cv_inner.reviewed_at,
                      cv_inner.created_at
                    ) as published_at
                  from content_versions cv_inner
                  join content_publish_targets cpt_inner
                    on cpt_inner.content_version_id = cv_inner.id
                  where cv_inner.content_item_id = ci.id
                    and cv_inner.version_status in ('published', 'approved')
                    and cpt_inner.activation_status = 'active'
                    and cpt_inner.platform in ('android', 'all')
                    and cpt_inner.audience_app in (:audience_app, 'shared')
                    and (
                      cpt_inner.age_cohort = 'all'
                      or cast(:age_cohort as text) is null
                      or cpt_inner.age_cohort = cast(:age_cohort as text)
                    )
                  order by
                    coalesce(
                      cpt_inner.effective_from,
                      cv_inner.effective_from,
                      cv_inner.reviewed_at,
                      cv_inner.created_at
                    ) desc nulls last,
                    cv_inner.version_number desc
                  limit 1
                ) pv on true
                where ci.lifecycle_status = 'active'
                  and ci.review_status = 'approved'
                  and ci.audience_app in (:audience_app, 'shared')
                  and (
                    ci.age_cohort = 'all'
                    or cast(:age_cohort as text) is null
                    or ci.age_cohort = cast(:age_cohort as text)
                  )
                  and (
                    cast(:content_type as text) is null
                    or ci.content_type = :content_type
                  )
                  and (
                    cast(:theme as text) is null
                    or lower(coalesce(ci.theme, '')) = lower(cast(:theme as text))
                  )
                  and (
                    cast(:topic as text) is null
                    or lower(coalesce(ci.topic, '')) = lower(cast(:topic as text))
                  )
                  and (
                    cast(:subtopic as text) is null
                    or lower(coalesce(ci.subtopic, '')) = lower(cast(:subtopic as text))
                  )
                order by pv.published_at desc nulls last, ci.updated_at desc, ci.title
                limit :limit
                """
            ),
            {
                "audience_app": audience_app,
                "age_cohort": age_cohort,
                "content_type": content_type,
                "theme": theme,
                "topic": topic,
                "subtopic": subtopic,
                "limit": limit,
            },
        )
        return [dict(row) for row in result.mappings().all()]

    async def get_published_content_detail(
        self,
        *,
        content_item_id: UUID,
        audience_app: str,
        age_cohort: str | None,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  ci.id,
                  ci.slug,
                  ci.title,
                  ci.content_type,
                  ci.audience_app,
                  ci.age_cohort,
                  ci.theme,
                  ci.topic,
                  ci.subtopic,
                  ci.summary,
                  ci.metadata,
                  pv.version_id,
                  pv.version_number,
                  pv.body,
                  pv.plain_text,
                  pv.reviewed_by,
                  pv.reviewed_at,
                  pv.published_at
                from content_items ci
                join lateral (
                  select
                    cv_inner.id as version_id,
                    cv_inner.version_number,
                    cv_inner.body,
                    cv_inner.plain_text,
                    cv_inner.reviewed_by,
                    cv_inner.reviewed_at,
                    coalesce(
                      cpt_inner.effective_from,
                      cv_inner.effective_from,
                      cv_inner.reviewed_at,
                      cv_inner.created_at
                    ) as published_at
                  from content_versions cv_inner
                  join content_publish_targets cpt_inner
                    on cpt_inner.content_version_id = cv_inner.id
                  where cv_inner.content_item_id = ci.id
                    and cv_inner.version_status in ('published', 'approved')
                    and cpt_inner.activation_status = 'active'
                    and cpt_inner.platform in ('android', 'all')
                    and cpt_inner.audience_app in (:audience_app, 'shared')
                    and (
                      cpt_inner.age_cohort = 'all'
                      or cast(:age_cohort as text) is null
                      or cpt_inner.age_cohort = cast(:age_cohort as text)
                    )
                  order by
                    coalesce(
                      cpt_inner.effective_from,
                      cv_inner.effective_from,
                      cv_inner.reviewed_at,
                      cv_inner.created_at
                    ) desc nulls last,
                    cv_inner.version_number desc
                  limit 1
                ) pv on true
                where ci.id = :content_item_id
                  and ci.lifecycle_status = 'active'
                  and ci.review_status = 'approved'
                  and ci.audience_app in (:audience_app, 'shared')
                  and (
                    ci.age_cohort = 'all'
                    or cast(:age_cohort as text) is null
                    or ci.age_cohort = cast(:age_cohort as text)
                  )
                limit 1
                """
            ),
            {
                "content_item_id": content_item_id,
                "audience_app": audience_app,
                "age_cohort": age_cohort,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def list_support_contacts(
        self,
        *,
        audience_app: str,
        school_id: UUID | None,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  school_id,
                  contact_type,
                  audience_app,
                  label,
                  phone,
                  email,
                  contact_url,
                  service_hours,
                  priority,
                  metadata
                from support_contacts
                where active = true
                  and audience_app in (:audience_app, 'shared')
                  and (
                    school_id is null
                    or cast(:school_id as uuid) is null
                    or school_id = cast(:school_id as uuid)
                  )
                order by
                  case
                    when cast(:school_id as uuid) is not null and school_id = cast(:school_id as uuid) then 0
                    when school_id is null then 1
                    else 2
                  end,
                  priority asc,
                  label asc
                """
            ),
            {"audience_app": audience_app, "school_id": school_id},
        )
        return [dict(row) for row in result.mappings().all()]

    async def list_teacher_classes(self, *, teacher_profile_id: UUID) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  c.id as class_id,
                  c.class_code,
                  c.label,
                  c.academic_year,
                  c.grade_band,
                  ta.assignment_type,
                  count(cm.id) filter (where cm.membership_status = 'active') as active_student_count
                from teacher_assignments ta
                join classes c on c.id = ta.class_id
                left join class_memberships cm on cm.class_id = c.id
                where ta.teacher_profile_id = :teacher_profile_id
                  and ta.status = 'active'
                group by c.id, ta.assignment_type
                order by c.label
                """
            ),
            {"teacher_profile_id": teacher_profile_id},
        )
        return [dict(row) for row in result.mappings().all()]

    async def list_teacher_class_students(
        self,
        *,
        teacher_profile_id: UUID,
        class_id: UUID,
    ) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  sp.id as student_profile_id,
                  u.display_name as student_name,
                  sp.presentation_age_cohort as age_cohort,
                  cm.membership_status
                from teacher_assignments ta
                join class_memberships cm
                  on cm.class_id = ta.class_id
                join student_profiles sp
                  on sp.id = cm.student_profile_id
                join users u
                  on u.id = sp.user_id
                where ta.teacher_profile_id = :teacher_profile_id
                  and ta.class_id = :class_id
                  and ta.status = 'active'
                order by u.display_name
                """
            ),
            {"teacher_profile_id": teacher_profile_id, "class_id": class_id},
        )
        return [dict(row) for row in result.mappings().all()]

    async def get_latest_teacher_cohort_summary(
        self,
        *,
        class_id: UUID,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  school_id,
                  class_id,
                  week_start,
                  week_end,
                  summary_scope,
                  student_count,
                  anonymized_summary,
                  generated_at
                from teacher_cohort_summaries
                where class_id = :class_id
                order by week_end desc, generated_at desc
                limit 1
                """
            ),
            {"class_id": class_id},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def create_pastoral_flag(
        self,
        *,
        student_profile_id: UUID,
        teacher_profile_id: UUID,
        class_id: UUID | None,
        flag_type: str,
        severity: str,
        summary: str,
        details_json: str,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into pastoral_flags (
                  student_profile_id,
                  teacher_profile_id,
                  class_id,
                  flag_type,
                  severity,
                  summary,
                  details
                )
                values (
                  :student_profile_id,
                  :teacher_profile_id,
                  :class_id,
                  :flag_type,
                  :severity,
                  :summary,
                  cast(:details as jsonb)
                )
                returning
                  id, student_profile_id, teacher_profile_id, class_id,
                  flag_type, severity, status, summary, details, created_at
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "teacher_profile_id": teacher_profile_id,
                "class_id": class_id,
                "flag_type": flag_type,
                "severity": severity,
                "summary": summary,
                "details": details_json,
            },
        )
        return dict(result.mappings().one())

    async def create_help_request(
        self,
        *,
        student_profile_id: UUID | None,
        requested_by_user_id: UUID,
        requested_for_user_id: UUID | None,
        request_channel: str,
        category: str,
        urgency: str,
        summary: str,
        details_json: str,
        visibility_scope: str,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into help_requests (
                  student_profile_id,
                  requested_by_user_id,
                  requested_for_user_id,
                  request_channel,
                  category,
                  urgency,
                  summary,
                  details,
                  visibility_scope
                )
                values (
                  :student_profile_id,
                  :requested_by_user_id,
                  :requested_for_user_id,
                  :request_channel,
                  :category,
                  :urgency,
                  :summary,
                  cast(:details as jsonb),
                  :visibility_scope
                )
                returning
                  id, student_profile_id, requested_by_user_id, requested_for_user_id,
                  request_channel, category, urgency, status, summary, details,
                  visibility_scope, created_at
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "requested_by_user_id": requested_by_user_id,
                "requested_for_user_id": requested_for_user_id,
                "request_channel": request_channel,
                "category": category,
                "urgency": urgency,
                "summary": summary,
                "details": details_json,
                "visibility_scope": visibility_scope,
            },
        )
        return dict(result.mappings().one())

    async def get_chat_session_owned(
        self,
        *,
        session_id: UUID,
        user_id: UUID,
        audience_app: str,
        student_profile_id: UUID | None,
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select id, user_id, context_student_profile_id, audience_app, session_type, status, safety_disposition
                from chat_sessions
                where id = :session_id
                  and user_id = :user_id
                  and audience_app = :audience_app
                  and (
                    (cast(:student_profile_id as uuid) is null and context_student_profile_id is null)
                    or context_student_profile_id = cast(:student_profile_id as uuid)
                  )
                limit 1
                """
            ),
            {
                "session_id": session_id,
                "user_id": user_id,
                "audience_app": audience_app,
                "student_profile_id": student_profile_id,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def list_chat_messages(self, *, chat_session_id: UUID) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  chat_session_id,
                  sender_type,
                  message_type,
                  ordinal,
                  body,
                  structured_payload,
                  retrieval_filters,
                  safety_labels,
                  created_at,
                  updated_at
                from chat_messages
                where chat_session_id = :chat_session_id
                order by ordinal
                """
            ),
            {"chat_session_id": chat_session_id},
        )
        return [dict(row) for row in result.mappings().all()]

    async def create_chat_message(
        self,
        *,
        chat_session_id: UUID,
        sender_type: str,
        message_type: str,
        body: str,
        structured_payload_json: str = "{}",
        retrieval_filters_json: str = "{}",
        safety_labels_json: str = "[]",
    ) -> dict[str, Any]:
        ordinal_result = await self.session.execute(
            text(
                """
                select coalesce(max(ordinal), 0) + 1 as next_ordinal
                from chat_messages
                where chat_session_id = :chat_session_id
                """
            ),
            {"chat_session_id": chat_session_id},
        )
        next_ordinal = ordinal_result.scalar_one()
        result = await self.session.execute(
            text(
                """
                insert into chat_messages (
                  chat_session_id,
                  sender_type,
                  message_type,
                  ordinal,
                  body,
                  structured_payload,
                  retrieval_filters,
                  safety_labels
                )
                values (
                  :chat_session_id,
                  :sender_type,
                  :message_type,
                  :ordinal,
                  :body,
                  cast(:structured_payload as jsonb),
                  cast(:retrieval_filters as jsonb),
                  cast(:safety_labels as jsonb)
                )
                returning
                  id, chat_session_id, sender_type, message_type, ordinal, body,
                  structured_payload, retrieval_filters, safety_labels, created_at, updated_at
                """
            ),
            {
                "chat_session_id": chat_session_id,
                "sender_type": sender_type,
                "message_type": message_type,
                "ordinal": next_ordinal,
                "body": body,
                "structured_payload": structured_payload_json,
                "retrieval_filters": retrieval_filters_json,
                "safety_labels": safety_labels_json,
            },
        )
        return dict(result.mappings().one())

    async def add_chat_answer_citations(
        self,
        *,
        chat_message_id: UUID,
        citations: list[dict[str, Any]],
    ) -> None:
        for index, citation in enumerate(citations, start=1):
            await self.session.execute(
                text(
                    """
                    insert into chat_answer_citations (
                      chat_message_id,
                      resource_id,
                      chunk_id,
                      citation_label,
                      ordinal,
                      confidence,
                      metadata
                    )
                    values (
                      :chat_message_id,
                      :resource_id,
                      :chunk_id,
                      :citation_label,
                      :ordinal,
                      :confidence,
                      cast(:metadata as jsonb)
                    )
                    """
                ),
                {
                    "chat_message_id": chat_message_id,
                    "resource_id": citation.get("resource_id"),
                    "chunk_id": citation.get("chunk_id"),
                    "citation_label": citation.get("citation_label"),
                    "ordinal": index,
                    "confidence": citation.get("confidence"),
                    "metadata": citation.get("metadata_json", "{}"),
                },
            )

    async def touch_chat_session(
        self,
        *,
        chat_session_id: UUID,
        safety_disposition: str | None = None,
    ) -> None:
        if safety_disposition is None:
            await self.session.execute(
                text(
                    """
                    update chat_sessions
                    set
                      last_message_at = now(),
                      message_count = (
                        select count(*) from chat_messages where chat_session_id = :chat_session_id
                      ),
                      updated_at = now()
                    where id = :chat_session_id
                    """
                ),
                {"chat_session_id": chat_session_id},
            )
            return
        await self.session.execute(
            text(
                """
                update chat_sessions
                set
                  last_message_at = now(),
                  message_count = (
                    select count(*) from chat_messages where chat_session_id = :chat_session_id
                  ),
                  safety_disposition = :safety_disposition,
                  updated_at = now()
                where id = :chat_session_id
                """
            ),
            {"chat_session_id": chat_session_id, "safety_disposition": safety_disposition},
        )

    async def create_monitoring_signal(
        self,
        *,
        student_profile_id: UUID,
        signal_type: str,
        severity: str,
        title: str,
        signal_summary: str,
        derived_facts_json: str = "{}",
        metadata_json: str = "{}",
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into monitoring_signals (
                  student_profile_id,
                  signal_type,
                  signal_status,
                  severity,
                  title,
                  signal_summary,
                  derived_facts,
                  metadata
                )
                values (
                  :student_profile_id,
                  :signal_type,
                  'new',
                  :severity,
                  :title,
                  :signal_summary,
                  cast(:derived_facts as jsonb),
                  cast(:metadata as jsonb)
                )
                returning id, student_profile_id, signal_type, signal_status, severity, title, signal_summary, triggered_at
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "signal_type": signal_type,
                "severity": severity,
                "title": title,
                "signal_summary": signal_summary,
                "derived_facts": derived_facts_json,
                "metadata": metadata_json,
            },
        )
        return dict(result.mappings().one())

    async def attach_signal_source(
        self,
        *,
        monitoring_signal_id: UUID,
        source_type: str,
        source_record_id: UUID,
        contribution_weight: float | None = None,
        summary: str | None = None,
    ) -> None:
        await self.session.execute(
            text(
                """
                insert into signal_sources (
                  monitoring_signal_id,
                  source_type,
                  source_record_id,
                  contribution_weight,
                  summary
                )
                values (
                  :monitoring_signal_id,
                  :source_type,
                  :source_record_id,
                  :contribution_weight,
                  :summary
                )
                """
            ),
            {
                "monitoring_signal_id": monitoring_signal_id,
                "source_type": source_type,
                "source_record_id": source_record_id,
                "contribution_weight": contribution_weight,
                "summary": summary,
            },
        )

    async def create_escalation_case(
        self,
        *,
        student_profile_id: UUID,
        primary_signal_id: UUID | None,
        opened_by_user_id: UUID | None,
        case_type: str,
        severity: str,
        title: str,
        summary: str,
        privacy_override_active: bool,
        override_reason: str | None = None,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into escalation_cases (
                  case_key,
                  student_profile_id,
                  primary_signal_id,
                  opened_by_user_id,
                  case_type,
                  severity,
                  status,
                  privacy_override_active,
                  override_reason,
                  title,
                  summary
                )
                values (
                  concat('CASE-', replace(gen_random_uuid()::text, '-', '')),
                  :student_profile_id,
                  :primary_signal_id,
                  :opened_by_user_id,
                  :case_type,
                  :severity,
                  'open',
                  :privacy_override_active,
                  :override_reason,
                  :title,
                  :summary
                )
                returning
                  id, case_key, student_profile_id, primary_signal_id, case_type,
                  severity, status, privacy_override_active, title, summary, opened_at
                """
            ),
            {
                "student_profile_id": student_profile_id,
                "primary_signal_id": primary_signal_id,
                "opened_by_user_id": opened_by_user_id,
                "case_type": case_type,
                "severity": severity,
                "privacy_override_active": privacy_override_active,
                "override_reason": override_reason,
                "title": title,
                "summary": summary,
            },
        )
        return dict(result.mappings().one())

    async def list_counselor_queue(
        self,
        *,
        limit: int,
        school_id: UUID | None,
        unrestricted: bool,
    ) -> dict[str, Any]:
        school_filter = "" if unrestricted else "and sp.school_id = :school_id"
        params = {"limit": limit, "school_id": school_id}
        cases_result = await self.session.execute(
            text(
                f"""
                select
                  ec.id,
                  ec.case_key,
                  ec.case_type,
                  ec.severity,
                  ec.status,
                  ec.title,
                  ec.summary,
                  ec.privacy_override_active,
                  ec.opened_at,
                  u.display_name as student_name
                from escalation_cases ec
                join student_profiles sp on sp.id = ec.student_profile_id
                join users u on u.id = sp.user_id
                where ec.status in ('open', 'triaged', 'assigned', 'in_progress', 'awaiting_external')
                  {school_filter}
                order by
                  case ec.severity when 'emergency' then 1 when 'high' then 2 when 'moderate' then 3 else 4 end,
                  ec.opened_at desc
                limit :limit
                """
            ),
            params,
        )
        signals_result = await self.session.execute(
            text(
                f"""
                select
                  ms.id,
                  ms.signal_type,
                  ms.severity,
                  ms.signal_status,
                  ms.title,
                  ms.signal_summary,
                  ms.triggered_at,
                  u.display_name as student_name
                from monitoring_signals ms
                join student_profiles sp on sp.id = ms.student_profile_id
                join users u on u.id = sp.user_id
                left join escalation_cases ec on ec.primary_signal_id = ms.id
                where ms.signal_status in ('new', 'reviewing')
                  and ec.id is null
                  {school_filter}
                order by
                  case ms.severity when 'emergency' then 1 when 'high' then 2 when 'moderate' then 3 else 4 end,
                  ms.triggered_at desc
                limit :limit
                """
            ),
            params,
        )
        help_result = await self.session.execute(
            text(
                f"""
                select
                  hr.id,
                  hr.category,
                  hr.urgency,
                  hr.status,
                  hr.summary,
                  hr.created_at,
                  coalesce(u.display_name, 'Unknown student') as student_name
                from help_requests hr
                left join student_profiles sp on sp.id = hr.student_profile_id
                left join users u on u.id = sp.user_id
                where hr.status in ('open', 'acknowledged', 'in_progress', 'escalated')
                  {school_filter}
                order by
                  case hr.urgency when 'emergency' then 1 when 'urgent' then 2 when 'priority' then 3 else 4 end,
                  hr.created_at desc
                limit :limit
                """
            ),
            params,
        )
        return {
            "open_cases": [dict(row) for row in cases_result.mappings().all()],
            "unassigned_signals": [dict(row) for row in signals_result.mappings().all()],
            "open_help_requests": [dict(row) for row in help_result.mappings().all()],
        }

    async def get_counselor_case_detail(
        self,
        *,
        case_id: UUID,
        school_id: UUID | None,
        unrestricted: bool,
    ) -> dict[str, Any] | None:
        school_filter = "" if unrestricted else "and sp.school_id = :school_id"
        case_result = await self.session.execute(
            text(
                f"""
                select
                  ec.id,
                  ec.case_key,
                  ec.case_type,
                  ec.severity,
                  ec.status,
                  ec.title,
                  ec.summary,
                  ec.privacy_override_active,
                  ec.override_reason,
                  ec.opened_at,
                  ec.closed_at,
                  su.display_name as student_name
                from escalation_cases ec
                join student_profiles sp on sp.id = ec.student_profile_id
                join users su on su.id = sp.user_id
                where ec.id = :case_id
                  {school_filter}
                limit 1
                """
            ),
            {"case_id": case_id, "school_id": school_id},
        )
        case_row = case_result.mappings().first()
        if case_row is None:
            return None
        notes_result = await self.session.execute(
            text(
                """
                select
                  cn.id,
                  cn.note_type,
                  cn.visibility_scope,
                  cn.body,
                  cn.created_at,
                  u.display_name as author_name
                from case_notes cn
                left join users u on u.id = cn.author_user_id
                where cn.escalation_case_id = :case_id
                order by cn.created_at desc
                """
            ),
            {"case_id": case_id},
        )
        events_result = await self.session.execute(
            text(
                """
                select
                  ce.id,
                  ce.event_type,
                  ce.event_summary,
                  ce.event_payload,
                  ce.occurred_at,
                  u.display_name as actor_name
                from case_events ce
                left join users u on u.id = ce.actor_user_id
                where ce.escalation_case_id = :case_id
                order by ce.occurred_at desc
                """
            ),
            {"case_id": case_id},
        )
        assignments_result = await self.session.execute(
            text(
                """
                select
                  ca.id,
                  ca.assignment_role,
                  ca.status,
                  ca.assigned_at,
                  u.display_name as assigned_user_name
                from case_assignments ca
                join users u on u.id = ca.assigned_user_id
                where ca.escalation_case_id = :case_id
                order by ca.assigned_at desc
                """
            ),
            {"case_id": case_id},
        )
        return {
          "case": dict(case_row),
          "notes": [dict(row) for row in notes_result.mappings().all()],
          "events": [dict(row) for row in events_result.mappings().all()],
          "assignments": [dict(row) for row in assignments_result.mappings().all()],
        }

    async def get_latest_baha_dashboard_metric(
        self,
        *,
        metric_scope: str = "global",
        scope_key: str = "all",
    ) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select
                  id,
                  metric_scope,
                  scope_key,
                  period_start,
                  period_end,
                  metrics,
                  generation_version,
                  generated_at
                from baha_pilot_dashboard_metrics
                where metric_scope = :metric_scope
                  and scope_key = :scope_key
                order by period_end desc, generated_at desc
                limit 1
                """
            ),
            {"metric_scope": metric_scope, "scope_key": scope_key},
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def add_case_note(
        self,
        *,
        case_id: UUID,
        author_user_id: UUID,
        note_type: str,
        visibility_scope: str,
        body: str,
    ) -> dict[str, Any]:
        result = await self.session.execute(
            text(
                """
                insert into case_notes (
                  escalation_case_id,
                  author_user_id,
                  note_type,
                  visibility_scope,
                  body
                )
                values (
                  :case_id,
                  :author_user_id,
                  :note_type,
                  :visibility_scope,
                  :body
                )
                returning id, escalation_case_id, note_type, visibility_scope, body, created_at, updated_at
                """
            ),
            {
                "case_id": case_id,
                "author_user_id": author_user_id,
                "note_type": note_type,
                "visibility_scope": visibility_scope,
                "body": body,
            },
        )
        await self.session.execute(
            text(
                """
                insert into case_events (
                  escalation_case_id,
                  event_type,
                  actor_user_id,
                  event_summary,
                  event_payload
                )
                values (
                  :case_id,
                  'note_added',
                  :author_user_id,
                  'Case note added',
                  '{}'::jsonb
                )
                """
            ),
            {"case_id": case_id, "author_user_id": author_user_id},
        )
        return dict(result.mappings().one())

    def _row_to_actor_context(self, row: Any) -> ActorContext:
        roles = [role for role in (row["roles"] or []) if role]
        return ActorContext(
            user_id=row["user_id"],
            external_auth_id=row["external_auth_id"],
            display_name=row["display_name"],
            roles=roles,
            student_profile_id=row["student_profile_id"],
            guardian_id=row["guardian_id"],
            teacher_profile_id=row["teacher_profile_id"],
            age_cohort=row["presentation_age_cohort"],
            school_id=row["school_id"],
        )
