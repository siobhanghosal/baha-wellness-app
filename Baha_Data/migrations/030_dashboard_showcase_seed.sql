insert into users (id, external_auth_id, email, display_name, status, preferred_language, metadata)
values
  (
    '20000000-0000-0000-0000-000000000014',
    'supabase-student-analytics-demo',
    'analytics.demo@baha.local',
    'Maya Analytics',
    'active',
    'en',
    '{"demo": true, "scenario": "dashboard_showcase", "dev_auth": {"mode": "id_password", "salt_b64": "YmFoYS1kZW1vLWFuYWx5dGljcy0wMDE=", "password_hash_b64": "7hyNas6MnzsvyewfiIg/VGhmQW5L2UE/jPCmvTgxhnM=", "iterations": 200000}}'::jsonb
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
select
  '20000000-0000-0000-0000-000000000014'::uuid,
  r.id,
  'active',
  '{"demo": true, "scenario_seed": true}'::jsonb
from roles r
where r.role_key = 'student'
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
    '30000000-0000-0000-0000-000000000014',
    '20000000-0000-0000-0000-000000000014',
    'STU-DEMO-014',
    '10000000-0000-0000-0000-000000000001',
    '18_plus',
    'adult',
    'female',
    '2005-04-27',
    'active',
    '{
      "demo": true,
      "scenario": "dashboard_showcase",
      "age_band": "18_plus",
      "gender_identity": "female",
      "trusted_support_person": "friend",
      "school_day_sleep_quality": "poor",
      "usual_energy": "okay",
      "weekly_stress_frequency": "often",
      "main_pressure": "school",
      "main_physical_issue": "headaches",
      "experiences_periods": "prefer_not_to_say",
      "coping_style": "phone_or_music",
      "help_seeking_ease": "mixed",
      "social_connectedness": "mixed",
      "support_preference": "quick_tips",
      "checkin_focus": "sleep"
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

insert into school_enrollments (
  student_profile_id, school_id, enrollment_status, enrolled_at, metadata
)
values
  (
    '30000000-0000-0000-0000-000000000014',
    '10000000-0000-0000-0000-000000000001',
    'active',
    now(),
    '{"demo": true, "scenario": "dashboard_showcase"}'::jsonb
  )
on conflict do nothing;

insert into checkin_response_sets (
  id, student_profile_id, template_id, submitted_at, status, source_mode, visibility_scope, metadata
)
values
  ('52000000-0000-0000-0000-000000000301','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date - interval '5 day' + time '21:10','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date - interval '4 day' + time '21:05','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date - interval '3 day' + time '20:55','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date - interval '2 day' + time '20:40','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date - interval '1 day' + time '20:25','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','30000000-0000-0000-0000-000000000014','50000000-0000-0000-0000-000000000101',current_date + time '20:15','submitted','daily_optional','private','{"demo": true, "scenario": "dashboard_showcase"}'::jsonb)
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
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000101',4,'["very_poorly"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"very_poorly","label":"Very poorly","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000103',3,'["low"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000104',4,'["extremely"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"extremely","label":"Extremely","score":4,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000105',3,'["not_great"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"not_great","label":"Not great","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000106',3,'["a_bit_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"a_bit_alone","label":"A bit alone","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000107',0,'["stress_worry"]'::jsonb,'{"question_key":"sleep_reason","dimension":"sleep","choice_key":"stress_worry","label":"Stress or worry","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000108',0,'["school_studies"]'::jsonb,'{"question_key":"hardest_today","dimension":"reflection","choice_key":"school_studies","label":"School or studies","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000109',0,'["bad_sleep"]'::jsonb,'{"question_key":"energy_reason","dimension":"energy","choice_key":"bad_sleep","label":"Bad sleep","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000301','51000000-0000-0000-0000-000000000111',0,'["show_tip"]'::jsonb,'{"question_key":"support_today","dimension":"support_preference","choice_key":"show_tip","label":"Show me a tip","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000101',3,'["poorly"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"poorly","label":"Poorly","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000104',3,'["a_lot"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_lot","label":"A lot","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000105',2,'["a_bit_off"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"a_bit_off","label":"A bit off","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000106',3,'["a_bit_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"a_bit_alone","label":"A bit alone","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000107',0,'["screen_time"]'::jsonb,'{"question_key":"sleep_reason","dimension":"sleep","choice_key":"screen_time","label":"Screen time","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000108',0,'["school_studies"]'::jsonb,'{"question_key":"hardest_today","dimension":"reflection","choice_key":"school_studies","label":"School or studies","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000302','51000000-0000-0000-0000-000000000109',0,'["stress"]'::jsonb,'{"question_key":"energy_reason","dimension":"energy","choice_key":"stress","label":"Stress","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000102',2,'["okay"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000105',2,'["a_bit_off"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"a_bit_off","label":"A bit off","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000303','51000000-0000-0000-0000-000000000106',2,'["mixed"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000304','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000305','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000101',0,'["very_well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"very_well","label":"Very well","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000103',0,'["very_good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000306','51000000-0000-0000-0000-000000000106',0,'["very_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"very_connected","label":"Very connected","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb)
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
    '30000000-0000-0000-0000-000000000014',
    current_date - 6,
    current_date,
    'tier1',
    'ready',
    '{
      "headline":"Sleep strain and school pressure drove the hardest days early on, then eased as rest and support recovered.",
      "week_story":"The clearest pattern was a sleep-stress loop: the poorest sleep lined up with lower energy, heavier stress, and lower connection. Once rest improved, the whole picture steadied.",
      "best_progress":"Sleep, mood, and connection all recovered by the end of the week.",
      "watch_area":"Stress still looks linked to school pressure, so heavy weeks could trigger the same pattern again.",
      "support_nudge":"On busy school days, protect one wind-down step early and check in with one trusted person before the stress piles up.",
      "mood_trend":"Mood started low, then lifted steadily as the week became calmer.",
      "sleep_trend":"Sleep was the strongest early strain signal and then improved sharply.",
      "stress_trend":"Stress peaked at the start of the week and softened once sleep improved.",
      "energy_trend":"Energy recovered more slowly than sleep, but it followed the same general pattern.",
      "physical_trend":"Physical discomfort stayed mild and improved with the rest of the week.",
      "connectedness_trend":"Connection felt low on the hardest days, then became a clear protective factor by the end.",
      "risk_flags":["Sleep strain repeated","Stress and school pressure clustered together"],
      "profile_tags":["sleep_stress_link","school_pressure_driven","support_recovery_pattern"]
    }'::jsonb,
    '{"checkins":6,"chat_sessions":0}'::jsonb,
    'dashboard-showcase-v1',
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
