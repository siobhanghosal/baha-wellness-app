insert into users (id, external_auth_id, email, display_name, status, preferred_language, metadata)
values
  (
    '20000000-0000-0000-0000-000000000011',
    'supabase-student-connection-demo',
    'connection.demo@baha.local',
    'Nisha Connection',
    'active',
    'en',
    '{"demo": true, "scenario": "social_connection_strain", "dev_auth": {"mode": "id_password", "salt_b64": "YmFoYS1kZW1vLWNvbm5lY3Rpb24tMDAx", "password_hash_b64": "Gjhf7HHFjUVHGvKZwpOHFhAn24pLlZE4JvtSfDkLjws=", "iterations": 200000}}'::jsonb
  ),
  (
    '20000000-0000-0000-0000-000000000012',
    'supabase-student-physical-demo',
    'physical.demo@baha.local',
    'Sana Physical',
    'active',
    'en',
    '{"demo": true, "scenario": "physical_wellbeing_pattern", "dev_auth": {"mode": "id_password", "salt_b64": "YmFoYS1kZW1vLXBoeXNpY2FsLTAwMQ==", "password_hash_b64": "+5054nzBWv1carG/H1eLzGK6F9B8aA4Kri1yOwjUyg0=", "iterations": 200000}}'::jsonb
  ),
  (
    '20000000-0000-0000-0000-000000000013',
    'supabase-student-steady-demo',
    'steady.demo@baha.local',
    'Kabir Steady',
    'active',
    'en',
    '{"demo": true, "scenario": "healthy_consistency", "dev_auth": {"mode": "id_password", "salt_b64": "YmFoYS1kZW1vLXN0ZWFkeS0wMDE=", "password_hash_b64": "FvW+ywaEXJf+XWRbgCIDAj9PdqbMTGye9NPI/s0KhKE=", "iterations": 200000}}'::jsonb
  )
on conflict (id) do update
set external_auth_id = excluded.external_auth_id,
    email = excluded.email,
    display_name = excluded.display_name,
    status = excluded.status,
    preferred_language = excluded.preferred_language,
    metadata = excluded.metadata,
    updated_at = now();

insert into user_roles (user_id, role_id, status, metadata)
select v.user_id, r.id, 'active', '{"demo": true, "scenario_seed": true}'::jsonb
from (
  values
    ('20000000-0000-0000-0000-000000000011'::uuid, 'student'),
    ('20000000-0000-0000-0000-000000000012'::uuid, 'student'),
    ('20000000-0000-0000-0000-000000000013'::uuid, 'student')
) as v(user_id, role_key)
join roles r on r.role_key = v.role_key
on conflict (user_id, role_id) do update
set status = excluded.status,
    metadata = excluded.metadata,
    updated_at = now();

insert into student_profiles (
  id, user_id, student_code, school_id, presentation_age_cohort,
  legal_consent_band, gender, date_of_birth, enrollment_status, metadata
)
values
  (
    '30000000-0000-0000-0000-000000000011',
    '20000000-0000-0000-0000-000000000011',
    'STU-DEMO-011',
    '10000000-0000-0000-0000-000000000001',
    '18_plus',
    'adult',
    'female',
    '2006-03-19',
    'active',
    '{
      "demo": true,
      "age_band": "18_plus",
      "gender_identity": "female",
      "trusted_support_person": "friend",
      "school_day_sleep_quality": "okay",
      "usual_energy": "okay",
      "weekly_stress_frequency": "often",
      "main_pressure": "friends",
      "main_physical_issue": "none",
      "experiences_periods": "prefer_not_to_say",
      "coping_style": "stay_alone",
      "help_seeking_ease": "hard",
      "social_connectedness": "a_bit_isolated",
      "support_preference": "quick_tips",
      "checkin_focus": "connectedness"
    }'::jsonb
  ),
  (
    '30000000-0000-0000-0000-000000000012',
    '20000000-0000-0000-0000-000000000012',
    'STU-DEMO-012',
    '10000000-0000-0000-0000-000000000001',
    '18_plus',
    'adult',
    'female',
    '2005-11-08',
    'active',
    '{
      "demo": true,
      "age_band": "18_plus",
      "gender_identity": "female",
      "trusted_support_person": "parent_guardian",
      "school_day_sleep_quality": "poor",
      "usual_energy": "low",
      "weekly_stress_frequency": "often",
      "main_pressure": "health",
      "main_physical_issue": "chronic_condition",
      "experiences_periods": "yes",
      "period_impact": "a_lot",
      "coping_style": "phone_or_music",
      "help_seeking_ease": "mixed",
      "social_connectedness": "mostly_connected",
      "support_preference": "trusted_adult",
      "checkin_focus": "physical_wellbeing"
    }'::jsonb
  ),
  (
    '30000000-0000-0000-0000-000000000013',
    '20000000-0000-0000-0000-000000000013',
    'STU-DEMO-013',
    '10000000-0000-0000-0000-000000000001',
    '18_plus',
    'adult',
    'male',
    '2004-06-02',
    'active',
    '{
      "demo": true,
      "age_band": "18_plus",
      "gender_identity": "male",
      "trusted_support_person": "parent_guardian",
      "school_day_sleep_quality": "good",
      "usual_energy": "good",
      "weekly_stress_frequency": "sometimes",
      "main_pressure": "school",
      "main_physical_issue": "none",
      "experiences_periods": "no",
      "coping_style": "talk_to_someone",
      "help_seeking_ease": "somewhat_easy",
      "social_connectedness": "mostly_connected",
      "support_preference": "quick_tips",
      "checkin_focus": "mood"
    }'::jsonb
  )
on conflict (id) do update
set student_code = excluded.student_code,
    school_id = excluded.school_id,
    presentation_age_cohort = excluded.presentation_age_cohort,
    legal_consent_band = excluded.legal_consent_band,
    gender = excluded.gender,
    date_of_birth = excluded.date_of_birth,
    enrollment_status = excluded.enrollment_status,
    metadata = excluded.metadata,
    updated_at = now();

insert into school_enrollments (student_profile_id, school_id, enrollment_status, enrolled_at, metadata)
values
  ('30000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000001', 'active', now(), '{"demo": true}'::jsonb),
  ('30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000001', 'active', now(), '{"demo": true}'::jsonb),
  ('30000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000001', 'active', now(), '{"demo": true}'::jsonb)
on conflict do nothing;

insert into class_memberships (class_id, student_profile_id, membership_status, metadata)
values
  ('10000000-0000-0000-0000-000000000101', '30000000-0000-0000-0000-000000000011', 'active', '{"demo": true}'::jsonb),
  ('10000000-0000-0000-0000-000000000101', '30000000-0000-0000-0000-000000000012', 'active', '{"demo": true}'::jsonb),
  ('10000000-0000-0000-0000-000000000101', '30000000-0000-0000-0000-000000000013', 'active', '{"demo": true}'::jsonb)
on conflict (class_id, student_profile_id) do update
set membership_status = excluded.membership_status,
    metadata = excluded.metadata,
    updated_at = now();

insert into checkin_response_sets (
  id, student_profile_id, template_id, submitted_at, status, source_mode, visibility_scope, metadata
)
values
  ('52000000-0000-0000-0000-000000000201','30000000-0000-0000-0000-000000000011','50000000-0000-0000-0000-000000000101',current_date - interval '4 day' + time '20:10','submitted','daily_optional','private','{"demo": true, "scenario": "connection"}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','30000000-0000-0000-0000-000000000011','50000000-0000-0000-0000-000000000101',current_date - interval '3 day' + time '20:05','submitted','daily_optional','private','{"demo": true, "scenario": "connection"}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','30000000-0000-0000-0000-000000000011','50000000-0000-0000-0000-000000000101',current_date - interval '2 day' + time '19:55','submitted','daily_optional','private','{"demo": true, "scenario": "connection"}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','30000000-0000-0000-0000-000000000011','50000000-0000-0000-0000-000000000101',current_date - interval '1 day' + time '20:00','submitted','daily_optional','private','{"demo": true, "scenario": "connection"}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','30000000-0000-0000-0000-000000000011','50000000-0000-0000-0000-000000000101',current_date + time '19:50','submitted','daily_optional','private','{"demo": true, "scenario": "connection"}'::jsonb),

  ('52000000-0000-0000-0000-000000000211','30000000-0000-0000-0000-000000000012','50000000-0000-0000-0000-000000000101',current_date - interval '4 day' + time '18:40','submitted','daily_optional','private','{"demo": true, "scenario": "physical"}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','30000000-0000-0000-0000-000000000012','50000000-0000-0000-0000-000000000101',current_date - interval '3 day' + time '18:35','submitted','daily_optional','private','{"demo": true, "scenario": "physical"}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','30000000-0000-0000-0000-000000000012','50000000-0000-0000-0000-000000000101',current_date - interval '2 day' + time '18:30','submitted','daily_optional','private','{"demo": true, "scenario": "physical"}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','30000000-0000-0000-0000-000000000012','50000000-0000-0000-0000-000000000101',current_date - interval '1 day' + time '18:25','submitted','daily_optional','private','{"demo": true, "scenario": "physical"}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','30000000-0000-0000-0000-000000000012','50000000-0000-0000-0000-000000000101',current_date + time '18:20','submitted','daily_optional','private','{"demo": true, "scenario": "physical"}'::jsonb),

  ('52000000-0000-0000-0000-000000000221','30000000-0000-0000-0000-000000000013','50000000-0000-0000-0000-000000000101',current_date - interval '4 day' + time '21:00','submitted','daily_optional','private','{"demo": true, "scenario": "steady"}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','30000000-0000-0000-0000-000000000013','50000000-0000-0000-0000-000000000101',current_date - interval '3 day' + time '20:50','submitted','daily_optional','private','{"demo": true, "scenario": "steady"}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','30000000-0000-0000-0000-000000000013','50000000-0000-0000-0000-000000000101',current_date - interval '2 day' + time '20:45','submitted','daily_optional','private','{"demo": true, "scenario": "steady"}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','30000000-0000-0000-0000-000000000013','50000000-0000-0000-0000-000000000101',current_date - interval '1 day' + time '20:40','submitted','daily_optional','private','{"demo": true, "scenario": "steady"}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','30000000-0000-0000-0000-000000000013','50000000-0000-0000-0000-000000000101',current_date + time '20:35','submitted','daily_optional','private','{"demo": true, "scenario": "steady"}'::jsonb)
on conflict (id) do update
set student_profile_id = excluded.student_profile_id,
    template_id = excluded.template_id,
    submitted_at = excluded.submitted_at,
    status = excluded.status,
    source_mode = excluded.source_mode,
    visibility_scope = excluded.visibility_scope,
    metadata = excluded.metadata,
    updated_at = now();

insert into checkin_responses (
  response_set_id, question_id, numeric_value, selected_options, normalized_value, metadata
)
values
  -- Nisha: connection and mood strain
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000102',2,'["okay"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000103',3,'["low"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000201','51000000-0000-0000-0000-000000000106',4,'["very_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"very_alone","label":"Very alone","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000103',3,'["low"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000104',3,'["a_lot"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_lot","label":"A lot","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000202','51000000-0000-0000-0000-000000000106',4,'["very_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"very_alone","label":"Very alone","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000102',2,'["okay"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000203','51000000-0000-0000-0000-000000000106',3,'["a_bit_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"a_bit_alone","label":"A bit alone","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000204','51000000-0000-0000-0000-000000000106',2,'["mixed"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000205','51000000-0000-0000-0000-000000000106',2,'["mixed"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  -- Sana: physical discomfort and energy pattern
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000101',3,'["poorly"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"poorly","label":"Poorly","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000102',4,'["very_low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"very_low","label":"Very low","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000104',3,'["a_lot"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_lot","label":"A lot","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000105',4,'["quite_bad"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"quite_bad","label":"Quite bad","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000211','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000101',3,'["poorly"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"poorly","label":"Poorly","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000104',3,'["a_lot"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_lot","label":"A lot","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000105',4,'["quite_bad"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"quite_bad","label":"Quite bad","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000212','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000105',3,'["not_great"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"not_great","label":"Not great","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000213','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000102',2,'["okay"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000105',2,'["a_bit_off"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"a_bit_off","label":"A bit off","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000214','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000215','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  -- Kabir: stable and healthy consistency
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000221','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000103',0,'["very_good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000222','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000101',0,'["very_well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"very_well","label":"Very well","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000103',0,'["very_good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000223','51000000-0000-0000-0000-000000000106',0,'["very_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"very_connected","label":"Very connected","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000102',0,'["very_high"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"very_high","label":"Very high","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000104',0,'["not_at_all"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"not_at_all","label":"Not at all","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000224','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000101',0,'["very_well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"very_well","label":"Very well","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000102',0,'["very_high"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"very_high","label":"Very high","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000103',0,'["very_good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000104',0,'["not_at_all"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"not_at_all","label":"Not at all","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000225','51000000-0000-0000-0000-000000000106',0,'["very_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"very_connected","label":"Very connected","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb)
on conflict (response_set_id, question_id) do update
set numeric_value = excluded.numeric_value,
    selected_options = excluded.selected_options,
    normalized_value = excluded.normalized_value,
    metadata = excluded.metadata,
    updated_at = now();

insert into student_weekly_summaries (
  student_profile_id, week_start, week_end, privacy_tier_applied, summary_status,
  summary, source_window, generation_version, generated_at
)
values
  (
    '30000000-0000-0000-0000-000000000011',
    current_date - 7,
    current_date - 1,
    'tier1',
    'ready',
    '{
      "headline":"Connection was the clearest strain signal this week, while mood recovered once the student re-engaged socially.",
      "week_story":"The week started with strong isolation signals, then gradually stabilized after support and reconnection.",
      "best_progress":"Mood recovered by the end of the week.",
      "watch_area":"Connection still needs watching because low-connectedness answers repeated across multiple days.",
      "support_nudge":"Encourage one low-pressure check-in with a trusted friend or adult after a difficult day.",
      "mood_trend":"Mood dipped for two days, then moved back toward steady.",
      "sleep_trend":"Sleep stayed acceptable overall and was not the main driver.",
      "stress_trend":"Stress rose when connection felt low, then eased.",
      "energy_trend":"Energy improved as mood steadied.",
      "physical_trend":"Physical wellbeing stayed broadly steady.",
      "connectedness_trend":"Connection was low across several check-ins before partial recovery.",
      "risk_flags":["Mood dip needs attention","Connection feels low"],
      "profile_tags":["friendship_pressure_driven","low_help_seeking","social_isolation_risk"]
    }'::jsonb,
    '{"checkins":5,"chat_sessions":1}'::jsonb,
    'demo-scenarios-v1',
    now()
  ),
  (
    '30000000-0000-0000-0000-000000000012',
    current_date - 7,
    current_date - 1,
    'tier1',
    'ready',
    '{
      "headline":"Body discomfort and low energy clustered together early in the week, then improved as physical strain eased.",
      "week_story":"The strongest pattern was a physical wellbeing dip that also pulled sleep and energy down.",
      "best_progress":"Physical discomfort reduced by the end of the week.",
      "watch_area":"Body and energy should still be monitored together because they moved as a linked pattern.",
      "support_nudge":"Prompt the student to notice when physical discomfort is affecting sleep, energy, or concentration and to reach out earlier.",
      "mood_trend":"Mood stayed mostly steady despite physical strain.",
      "sleep_trend":"Sleep looked strained on the hardest physical days, then improved.",
      "stress_trend":"Stress was elevated early, then softened as symptoms eased.",
      "energy_trend":"Energy was one of the clearest burden signals and improved only after the body score improved.",
      "physical_trend":"Physical wellbeing showed a repeated strain pattern before recovery.",
      "connectedness_trend":"Connection remained stable and protective overall.",
      "risk_flags":["Sleep strain repeating","Physical discomfort pattern visible"],
      "profile_tags":["somatic_signal_prone","period_linked_physical_impact","focus_physical_wellbeing"]
    }'::jsonb,
    '{"checkins":5,"chat_sessions":0}'::jsonb,
    'demo-scenarios-v1',
    now()
  ),
  (
    '30000000-0000-0000-0000-000000000013',
    current_date - 7,
    current_date - 1,
    'tier1',
    'ready',
    '{
      "headline":"This week was steady overall, with strong sleep, energy, and connection consistency across repeated check-ins.",
      "week_story":"The pattern here is not crisis detection; it shows how BAHA can reinforce stable routines and resilience too.",
      "best_progress":"Stress reduced from low to very low by the end of the week.",
      "watch_area":"No repeated high-strain pattern stood out this week.",
      "support_nudge":"Keep reinforcing the habits that are already supporting sleep, mood, and energy.",
      "mood_trend":"Mood stayed positive throughout the week.",
      "sleep_trend":"Sleep was consistently strong.",
      "stress_trend":"Stress stayed low and became even lighter by week end.",
      "energy_trend":"Energy remained strong and steady.",
      "physical_trend":"Physical wellbeing remained stable.",
      "connectedness_trend":"Connection stayed healthy and supportive.",
      "risk_flags":[],
      "profile_tags":["focus_mood"]
    }'::jsonb,
    '{"checkins":5,"chat_sessions":0}'::jsonb,
    'demo-scenarios-v1',
    now()
  )
on conflict (student_profile_id, week_start, week_end) do update
set privacy_tier_applied = excluded.privacy_tier_applied,
    summary_status = excluded.summary_status,
    summary = excluded.summary,
    source_window = excluded.source_window,
    generation_version = excluded.generation_version,
    generated_at = excluded.generated_at,
    updated_at = now();
