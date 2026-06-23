insert into schools (id, school_code, name, city, state, country, status, metadata)
values
  ('10000000-0000-0000-0000-000000000001', 'BLR-PILOT-01', 'BAHA Pilot School', 'Bengaluru', 'Karnataka', 'India', 'active', '{"pilot": true}'::jsonb)
on conflict (id) do nothing;

insert into classes (id, school_id, class_code, label, academic_year, grade_band, status, metadata)
values
  ('10000000-0000-0000-0000-000000000101', '10000000-0000-0000-0000-000000000001', 'G8-A', 'Grade 8 A', '2026-2027', '13_14', 'active', '{"pilot": true}'::jsonb)
on conflict (id) do nothing;

insert into users (id, external_auth_id, email, display_name, status, preferred_language, metadata)
values
  ('20000000-0000-0000-0000-000000000001', 'supabase-student-demo', 'student.demo@baha.local', 'Aarav Student', 'active', 'en', '{"demo": true}'::jsonb),
  ('20000000-0000-0000-0000-000000000002', 'supabase-guardian-demo', 'guardian.demo@baha.local', 'Meera Guardian', 'active', 'en', '{"demo": true}'::jsonb),
  ('20000000-0000-0000-0000-000000000003', 'supabase-teacher-demo', 'teacher.demo@baha.local', 'Riya Teacher', 'active', 'en', '{"demo": true}'::jsonb),
  ('20000000-0000-0000-0000-000000000004', 'supabase-counselor-demo', 'counselor.demo@baha.local', 'Anita Counselor', 'active', 'en', '{"demo": true}'::jsonb),
  ('20000000-0000-0000-0000-000000000005', 'supabase-admin-demo', 'admin.demo@baha.local', 'BAHA Admin', 'active', 'en', '{"demo": true}'::jsonb)
on conflict (id) do nothing;

insert into user_roles (user_id, role_id, status, metadata)
select v.user_id, r.id, 'active', '{"demo": true}'::jsonb
from (
  values
    ('20000000-0000-0000-0000-000000000001'::uuid, 'student'),
    ('20000000-0000-0000-0000-000000000002'::uuid, 'guardian'),
    ('20000000-0000-0000-0000-000000000003'::uuid, 'teacher'),
    ('20000000-0000-0000-0000-000000000004'::uuid, 'counselor'),
    ('20000000-0000-0000-0000-000000000005'::uuid, 'baha_admin')
) as v(user_id, role_key)
join roles r on r.role_key = v.role_key
on conflict (user_id, role_id) do nothing;

insert into student_profiles (
  id, user_id, student_code, school_id, presentation_age_cohort,
  legal_consent_band, gender, date_of_birth, enrollment_status, metadata
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'STU-DEMO-001',
    '10000000-0000-0000-0000-000000000001',
    '13_14',
    'minor',
    'unspecified',
    '2012-08-14',
    'active',
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into guardians (id, user_id, guardian_type, metadata)
values
  ('30000000-0000-0000-0000-000000000101', '20000000-0000-0000-0000-000000000002', 'parent', '{"demo": true}'::jsonb)
on conflict (id) do nothing;

insert into student_guardian_links (
  student_profile_id, guardian_id, relationship_to_student, is_primary,
  consent_authority, status, metadata
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000101',
    'mother',
    true,
    true,
    'active',
    '{"demo": true}'::jsonb
  )
on conflict (student_profile_id, guardian_id) do nothing;

insert into teacher_profiles (id, user_id, school_id, staff_code, staff_type, metadata)
values
  ('30000000-0000-0000-0000-000000000201', '20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'TCH-DEMO-01', 'teacher', '{"demo": true}'::jsonb),
  ('30000000-0000-0000-0000-000000000202', '20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'COU-DEMO-01', 'counselor', '{"demo": true}'::jsonb)
on conflict (id) do nothing;

insert into class_memberships (class_id, student_profile_id, membership_status, metadata)
values
  ('10000000-0000-0000-0000-000000000101', '30000000-0000-0000-0000-000000000001', 'active', '{"demo": true}'::jsonb)
on conflict (class_id, student_profile_id) do nothing;

insert into teacher_assignments (teacher_profile_id, class_id, assignment_type, status, metadata)
values
  ('30000000-0000-0000-0000-000000000201', '10000000-0000-0000-0000-000000000101', 'class_teacher', 'active', '{"demo": true}'::jsonb),
  ('30000000-0000-0000-0000-000000000202', '10000000-0000-0000-0000-000000000101', 'counselor', 'active', '{"demo": true}'::jsonb)
on conflict (teacher_profile_id, class_id, assignment_type) do nothing;

insert into school_enrollments (student_profile_id, school_id, enrollment_status, enrolled_at, metadata)
values
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'active', now(), '{"demo": true}'::jsonb)
on conflict do nothing;

insert into consent_versions (
  id, consent_type, version_label, policy_reference, language, summary_text,
  full_text, effective_from, active, metadata
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    'platform_participation',
    'v1-demo',
    'demo-policy-platform',
    'en',
    'Demo platform participation consent',
    '{"title":"Demo platform participation consent"}'::jsonb,
    now(),
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    'parent_summary_sharing',
    'v1-demo',
    'demo-policy-parent-summary',
    'en',
    'Demo parent summary sharing consent',
    '{"title":"Demo parent summary consent"}'::jsonb,
    now(),
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into consent_records (
  consent_version_id, subject_user_id, actor_user_id, student_profile_id, guardian_id,
  consent_type, actor_relationship, scope, status, granted_at, metadata
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000101',
    'platform_participation',
    'parent',
    'general',
    'granted',
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000101',
    'parent_summary_sharing',
    'parent',
    'weekly_summaries',
    'granted',
    now(),
    '{"demo": true}'::jsonb
  )
on conflict do nothing;

insert into privacy_tier_settings (
  student_profile_id, configured_by_user_id, tier_1_enabled, tier_2_enabled, tier_3_enabled,
  status, effective_from, metadata
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    true,
    true,
    false,
    'active',
    now(),
    '{"demo": true}'::jsonb
  )
on conflict do nothing;

insert into checkin_templates (id, template_key, title, cadence, audience_app, age_cohort, active, metadata)
values
  ('50000000-0000-0000-0000-000000000001', 'weekly_student_checkin_13_14', 'Weekly Student Check-In', 'weekly', 'student', '13_14', true, '{"demo": true}'::jsonb)
on conflict (id) do nothing;

insert into checkin_questions (
  template_id, question_key, dimension, question_type, prompt, response_config, is_required, ordinal, metadata
)
values
  ('50000000-0000-0000-0000-000000000001', 'mood_week', 'mood', 'scale', 'How have you been feeling this week?', '{"scale":[1,2,3,4,5]}'::jsonb, true, 1, '{"demo": true}'::jsonb),
  ('50000000-0000-0000-0000-000000000001', 'sleep_week', 'sleep', 'scale', 'How well have you been sleeping this week?', '{"scale":[1,2,3,4,5]}'::jsonb, true, 2, '{"demo": true}'::jsonb),
  ('50000000-0000-0000-0000-000000000001', 'stress_week', 'stress', 'scale', 'How stressed have you felt this week?', '{"scale":[1,2,3,4,5]}'::jsonb, true, 3, '{"demo": true}'::jsonb)
on conflict (template_id, question_key) do nothing;

insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    'demo-student-module-sleep-basics',
    'Sleep Basics for Students',
    'learning_module',
    'student',
    '13_14',
    'Sleep',
    'sleep_habits',
    'daily_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Demo student module for Flutter integration',
    '{"demo": true}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    'demo-parent-weekly-conversation-guide',
    'Weekly Parent Conversation Guide',
    'conversation_guide',
    'parent',
    '13_14',
    'Relationships',
    'parent_support',
    'weekly_checkin',
    'en',
    'none',
    'tier2',
    'active',
    'approved',
    'manual',
    'Demo parent guide for backend handoff',
    '{"demo": true}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000003',
    'demo-teacher-wellbeing-overview',
    'Teacher Wellbeing Overview',
    'article',
    'teacher',
    '13_14',
    'Wellbeing',
    'teacher_support',
    'cohort_awareness',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Demo teacher content for backend handoff',
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into content_versions (
  id, content_item_id, version_number, version_status, body, plain_text, changelog,
  reviewed_by, reviewed_at, effective_from, metadata
)
values
  (
    '61000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    1,
    'published',
    '{"blocks":[{"type":"text","value":"Students can build healthier sleep routines by keeping a stable schedule and reducing stimulation before bed."}]}'::jsonb,
    'Students can build healthier sleep routines by keeping a stable schedule and reducing stimulation before bed.',
    'Initial demo version',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    1,
    'published',
    '{"blocks":[{"type":"text","value":"Start with one calm question about how the week felt before discussing habits or concerns."}]}'::jsonb,
    'Start with one calm question about how the week felt before discussing habits or concerns.',
    'Initial demo version',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000003',
    1,
    'published',
    '{"blocks":[{"type":"text","value":"Teachers should use cohort trends to decide when to normalize support and when to refer through BAHA workflows."}]}'::jsonb,
    'Teachers should use cohort trends to decide when to normalize support and when to refer through BAHA workflows.',
    'Initial demo version',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into content_publish_targets (
  content_version_id, audience_app, platform, age_cohort, activation_status,
  effective_from, metadata
)
values
  ('61000000-0000-0000-0000-000000000001', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000002', 'parent', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000003', 'teacher', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb)
on conflict (content_version_id, audience_app, platform, age_cohort) do nothing;

insert into learning_modules (
  id, content_item_id, module_code, role_track, theme, age_cohort, estimated_minutes, sort_order, active, metadata
)
values
  (
    '62000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    'STU-SLEEP-001',
    'student',
    'Sleep',
    '13_14',
    12,
    1,
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into learning_module_sections (id, module_id, title, ordinal, metadata)
values
  ('62000000-0000-0000-0000-000000000101', '62000000-0000-0000-0000-000000000001', 'Build a Better Bedtime', 1, '{"demo": true}'::jsonb)
on conflict (id) do nothing;

insert into learning_module_steps (id, section_id, content_item_id, step_type, title, ordinal, is_required, metadata)
values
  (
    '62000000-0000-0000-0000-000000000201',
    '62000000-0000-0000-0000-000000000101',
    '60000000-0000-0000-0000-000000000001',
    'content',
    'Why sleep routines matter',
    1,
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into support_contacts (
  id, school_id, contact_type, audience_app, label, phone, email, service_hours, priority, active, metadata
)
values
  (
    '70000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'counselor',
    'shared',
    'BAHA Demo Counselor Line',
    '+91-90000-00001',
    'counselor.demo@baha.local',
    'Mon-Fri 9am-6pm',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    null,
    'crisis_line',
    'shared',
    'Emergency Support',
    '112',
    null,
    '24x7',
    1,
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into crisis_routing_rules (
  id, rule_key, active, severity, trigger_category, audience_app, route_to_contact_id,
  action_summary, escalation_sla_minutes, metadata
)
values
  (
    '71000000-0000-0000-0000-000000000001',
    'demo-self-harm-emergency',
    true,
    'emergency',
    'self_harm',
    'student',
    '70000000-0000-0000-0000-000000000002',
    'Route immediately to emergency support and counselor review.',
    5,
    '{"demo": true}'::jsonb
  )
on conflict (id) do nothing;

insert into student_weekly_summaries (
  student_profile_id, week_start, week_end, privacy_tier_applied, summary_status,
  summary, source_window, generation_version, generated_at
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    current_date - 7,
    current_date - 1,
    'tier1',
    'ready',
    '{"headline":"Steady week overall","mood_trend":"stable","sleep_trend":"improving","module_progress":25}'::jsonb,
    '{"checkins":1,"chat_sessions":0}'::jsonb,
    'demo-v1',
    now()
  )
on conflict (student_profile_id, week_start, week_end) do nothing;

insert into parent_weekly_summaries (
  student_profile_id, guardian_id, week_start, week_end, consent_status,
  visible_tiers, summary, generation_version, generated_at
)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000101',
    current_date - 7,
    current_date - 1,
    'approved',
    '["tier1","tier2"]'::jsonb,
    '{"headline":"Your child showed consistent check-in participation this week.","safe_talking_point":"Ask what part of the week felt easiest."}'::jsonb,
    'demo-v1',
    now()
  )
on conflict (student_profile_id, guardian_id, week_start, week_end) do nothing;

insert into teacher_cohort_summaries (
  school_id, class_id, week_start, week_end, summary_scope, student_count,
  anonymized_summary, generation_version, generated_at
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000101',
    current_date - 7,
    current_date - 1,
    'class',
    1,
    '{"checkin_participation_rate":1.0,"module_completion_rate":0.25,"sleep_trend":"improving"}'::jsonb,
    'demo-v1',
    now()
  )
on conflict (school_id, class_id, week_start, week_end, summary_scope) do nothing;

insert into baha_pilot_dashboard_metrics (
  metric_scope, scope_key, period_start, period_end, metrics, generation_version, generated_at
)
values
  (
    'global',
    'all',
    current_date - 7,
    current_date - 1,
    '{"students_active":1,"guardians_active":1,"teachers_active":1,"open_cases":0}'::jsonb,
    'demo-v1',
    now()
  )
on conflict (metric_scope, scope_key, period_start, period_end) do nothing;
