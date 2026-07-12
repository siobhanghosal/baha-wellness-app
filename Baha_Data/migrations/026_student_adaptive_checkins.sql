alter table checkin_questions
  drop constraint if exists checkin_questions_dimension_check;

alter table checkin_questions
  add constraint checkin_questions_dimension_check
  check (
    dimension in (
      'mood',
      'sleep',
      'energy',
      'stress',
      'screen_time',
      'physical_activity',
      'lifestyle',
      'academic_stress',
      'reflection',
      'sensitive_indirect',
      'physical_wellbeing',
      'connectedness',
      'support_preference'
    )
  );

update checkin_templates
set active = false,
    updated_at = now()
where template_key = 'weekly_student_checkin_13_14';

insert into checkin_templates (
  id, template_key, title, cadence, audience_app, age_cohort, active, metadata
)
values (
  '50000000-0000-0000-0000-000000000101',
  'daily_student_pulse_v2_13_14',
  'Daily Wellbeing Pulse',
  'daily',
  'student',
  '13_14',
  true,
  '{
    "demo": true,
    "logic_version": "daily_pulse_v2",
    "profile_driven": true,
    "estimated_minutes": 2,
    "core_dimensions": ["sleep", "energy", "mood", "stress", "physical_wellbeing", "connectedness"],
    "max_questions": 10
  }'::jsonb
)
on conflict (id) do update
set template_key = excluded.template_key,
    title = excluded.title,
    cadence = excluded.cadence,
    audience_app = excluded.audience_app,
    age_cohort = excluded.age_cohort,
    active = excluded.active,
    metadata = excluded.metadata,
    updated_at = now();

insert into checkin_questions (
  id, template_id, question_key, dimension, question_type, prompt, response_config, is_required, ordinal, metadata
)
values
  (
    '51000000-0000-0000-0000-000000000101',
    '50000000-0000-0000-0000-000000000101',
    'sleep_last_night',
    'sleep',
    'choice',
    'How did you sleep last night?',
    '{
      "choices": [
        {"key":"very_well","label":"Very well","score":0},
        {"key":"well","label":"Well","score":1},
        {"key":"okay","label":"Okay","score":2},
        {"key":"poorly","label":"Poorly","score":3},
        {"key":"very_poorly","label":"Very poorly","score":4}
      ]
    }'::jsonb,
    true,
    1,
    '{"demo": true, "is_core": true, "factor_key": "sleep"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000102',
    '50000000-0000-0000-0000-000000000101',
    'energy_today',
    'energy',
    'choice',
    'How is your energy today?',
    '{
      "choices": [
        {"key":"very_high","label":"Very high","score":0},
        {"key":"good","label":"Good","score":1},
        {"key":"okay","label":"Okay","score":2},
        {"key":"low","label":"Low","score":3},
        {"key":"very_low","label":"Very low","score":4}
      ]
    }'::jsonb,
    true,
    2,
    '{"demo": true, "is_core": true, "factor_key": "energy"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000103',
    '50000000-0000-0000-0000-000000000101',
    'mood_today',
    'mood',
    'choice',
    'How is your mood today?',
    '{
      "choices": [
        {"key":"very_good","label":"Very good","score":0},
        {"key":"good","label":"Good","score":1},
        {"key":"mixed","label":"Mixed","score":2},
        {"key":"low","label":"Low","score":3},
        {"key":"very_low","label":"Very low","score":4}
      ]
    }'::jsonb,
    true,
    3,
    '{"demo": true, "is_core": true, "factor_key": "mood"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000104',
    '50000000-0000-0000-0000-000000000101',
    'stress_today',
    'stress',
    'choice',
    'How stressed or worried do you feel today?',
    '{
      "choices": [
        {"key":"not_at_all","label":"Not at all","score":0},
        {"key":"a_little","label":"A little","score":1},
        {"key":"somewhat","label":"Somewhat","score":2},
        {"key":"a_lot","label":"A lot","score":3},
        {"key":"extremely","label":"Extremely","score":4}
      ]
    }'::jsonb,
    true,
    4,
    '{"demo": true, "is_core": true, "factor_key": "stress"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000105',
    '50000000-0000-0000-0000-000000000101',
    'body_today',
    'physical_wellbeing',
    'choice',
    'How does your body feel today?',
    '{
      "choices": [
        {"key":"very_good","label":"Very good","score":0},
        {"key":"mostly_good","label":"Mostly good","score":1},
        {"key":"a_bit_off","label":"A bit off","score":2},
        {"key":"not_great","label":"Not great","score":3},
        {"key":"quite_bad","label":"Quite bad","score":4}
      ]
    }'::jsonb,
    true,
    5,
    '{"demo": true, "is_core": true, "factor_key": "physical_wellbeing"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000106',
    '50000000-0000-0000-0000-000000000101',
    'connected_today',
    'connectedness',
    'choice',
    'How supported or connected do you feel today?',
    '{
      "choices": [
        {"key":"very_connected","label":"Very connected","score":0},
        {"key":"mostly_connected","label":"Mostly connected","score":1},
        {"key":"mixed","label":"Mixed","score":2},
        {"key":"a_bit_alone","label":"A bit alone","score":3},
        {"key":"very_alone","label":"Very alone","score":4}
      ]
    }'::jsonb,
    true,
    6,
    '{"demo": true, "is_core": true, "factor_key": "connectedness"}'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000107',
    '50000000-0000-0000-0000-000000000101',
    'sleep_reason',
    'sleep',
    'choice',
    'What was the biggest reason your sleep felt bad?',
    '{
      "choices": [
        {"key":"stress_worry","label":"Stress or worry","score":0},
        {"key":"screen_time","label":"Screen time","score":0},
        {"key":"woke_up_a_lot","label":"Woke up a lot","score":0},
        {"key":"noise_room","label":"Noise or room issues","score":0},
        {"key":"pain_illness","label":"Pain or illness","score":0},
        {"key":"bad_dream","label":"Bad dream","score":0},
        {"key":"not_sure","label":"Not sure","score":0}
      ]
    }'::jsonb,
    false,
    7,
    '{
      "demo": true,
      "show_when": {
        "question_key": "sleep_last_night",
        "selected_options": ["poorly", "very_poorly"]
      }
    }'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000108',
    '50000000-0000-0000-0000-000000000101',
    'hardest_today',
    'reflection',
    'choice',
    'What felt hardest today?',
    '{
      "choices": [
        {"key":"school_studies","label":"School or studies","score":0},
        {"key":"friends","label":"Friends","score":0},
        {"key":"family","label":"Family","score":0},
        {"key":"health_body","label":"Health or body","score":0},
        {"key":"online_social","label":"Online or social media","score":0},
        {"key":"nothing_specific","label":"Nothing specific","score":0},
        {"key":"not_sure","label":"Not sure","score":0}
      ]
    }'::jsonb,
    false,
    8,
    '{
      "demo": true,
      "show_when_any": [
        {"question_key":"mood_today","selected_options":["low","very_low"]},
        {"question_key":"stress_today","selected_options":["a_lot","extremely"]}
      ]
    }'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000109',
    '50000000-0000-0000-0000-000000000101',
    'energy_reason',
    'energy',
    'choice',
    'What best explains the low energy?',
    '{
      "choices": [
        {"key":"bad_sleep","label":"Bad sleep","score":0},
        {"key":"stress","label":"Stress","score":0},
        {"key":"illness_pain","label":"Illness or pain","score":0},
        {"key":"food_water","label":"Didn''t eat or drink enough","score":0},
        {"key":"too_much_activity","label":"Too much activity","score":0},
        {"key":"not_sure","label":"Not sure","score":0}
      ]
    }'::jsonb,
    false,
    9,
    '{
      "demo": true,
      "show_when": {
        "question_key": "energy_today",
        "selected_options": ["low", "very_low"]
      }
    }'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000110',
    '50000000-0000-0000-0000-000000000101',
    'body_reason',
    'physical_wellbeing',
    'choice',
    'What bothered you most physically?',
    '{
      "choices": [
        {"key":"headache","label":"Headache","score":0},
        {"key":"stomach_issue","label":"Stomach issue","score":0},
        {"key":"tiredness","label":"Tiredness","score":0},
        {"key":"pain","label":"Pain","score":0},
        {"key":"cold_fever","label":"Cold or fever symptoms","score":0},
        {
          "key":"period_related",
          "label":"Period-related",
          "score":0,
          "metadata": {
            "profile_requirements": {
              "experiences_periods": "yes"
            }
          }
        },
        {"key":"not_sure","label":"Not sure","score":0}
      ]
    }'::jsonb,
    false,
    10,
    '{
      "demo": true,
      "show_when": {
        "question_key": "body_today",
        "selected_options": ["not_great", "quite_bad"]
      }
    }'::jsonb
  ),
  (
    '51000000-0000-0000-0000-000000000111',
    '50000000-0000-0000-0000-000000000101',
    'support_today',
    'support_preference',
    'choice',
    'Would you like support today?',
    '{
      "choices": [
        {"key":"no","label":"No","score":0},
        {"key":"maybe_later","label":"Maybe later","score":0},
        {"key":"show_tip","label":"Show me a tip","score":0},
        {"key":"trusted_adult","label":"Talk to a trusted adult","score":0},
        {"key":"counselor_support","label":"Ask for counselor support","score":0}
      ]
    }'::jsonb,
    false,
    11,
    '{
      "demo": true,
      "show_when_any": [
        {"question_key":"sleep_last_night","selected_options":["poorly", "very_poorly"]},
        {"question_key":"mood_today","selected_options":["low", "very_low"]},
        {"question_key":"stress_today","selected_options":["a_lot", "extremely"]},
        {"question_key":"connected_today","selected_options":["a_bit_alone", "very_alone"]}
      ]
    }'::jsonb
  )
on conflict (id) do update
set template_id = excluded.template_id,
    question_key = excluded.question_key,
    dimension = excluded.dimension,
    question_type = excluded.question_type,
    prompt = excluded.prompt,
    response_config = excluded.response_config,
    is_required = excluded.is_required,
    ordinal = excluded.ordinal,
    metadata = excluded.metadata,
    updated_at = now();

insert into checkin_response_sets (
  id, student_profile_id, template_id, submitted_at, status, source_mode, visibility_scope, metadata
)
values
  (
    '52000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000101',
    current_date - interval '4 day' + time '18:30',
    'submitted',
    'daily_optional',
    'private',
    '{"demo": true, "profile_version": 1}'::jsonb
  ),
  (
    '52000000-0000-0000-0000-000000000102',
    '30000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000101',
    current_date - interval '3 day' + time '19:00',
    'submitted',
    'daily_optional',
    'private',
    '{"demo": true, "profile_version": 1}'::jsonb
  ),
  (
    '52000000-0000-0000-0000-000000000103',
    '30000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000101',
    current_date - interval '2 day' + time '18:45',
    'submitted',
    'daily_optional',
    'private',
    '{"demo": true, "profile_version": 1}'::jsonb
  ),
  (
    '52000000-0000-0000-0000-000000000104',
    '30000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000101',
    current_date - interval '1 day' + time '18:20',
    'submitted',
    'daily_optional',
    'private',
    '{"demo": true, "profile_version": 1}'::jsonb
  ),
  (
    '52000000-0000-0000-0000-000000000105',
    '30000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000101',
    current_date + time '18:10',
    'submitted',
    'daily_optional',
    'private',
    '{"demo": true, "profile_version": 1}'::jsonb
  )
on conflict (id) do update
set template_id = excluded.template_id,
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
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000101',3,'["poorly"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"poorly","label":"Poorly","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000102',3,'["low"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"low","label":"Low","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000104',3,'["a_lot"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_lot","label":"A lot","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000105',2,'["a_bit_off"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"a_bit_off","label":"A bit off","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000106',3,'["a_bit_alone"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"a_bit_alone","label":"A bit alone","score":3,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000107',0,'["stress_worry"]'::jsonb,'{"question_key":"sleep_reason","dimension":"sleep","choice_key":"stress_worry","label":"Stress or worry","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000108',0,'["school_studies"]'::jsonb,'{"question_key":"hardest_today","dimension":"reflection","choice_key":"school_studies","label":"School or studies","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000101','51000000-0000-0000-0000-000000000109',0,'["bad_sleep"]'::jsonb,'{"question_key":"energy_reason","dimension":"energy","choice_key":"bad_sleep","label":"Bad sleep","score":0,"is_core":false}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000101',2,'["okay"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000102',2,'["okay"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"okay","label":"Okay","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000103',2,'["mixed"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000102','51000000-0000-0000-0000-000000000106',2,'["mixed"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mixed","label":"Mixed","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000104',2,'["somewhat"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"somewhat","label":"Somewhat","score":2,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000103','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000103',1,'["good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000105',1,'["mostly_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"mostly_good","label":"Mostly good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000104','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),

  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000101',1,'["well"]'::jsonb,'{"question_key":"sleep_last_night","dimension":"sleep","choice_key":"well","label":"Well","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000102',1,'["good"]'::jsonb,'{"question_key":"energy_today","dimension":"energy","choice_key":"good","label":"Good","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000103',0,'["very_good"]'::jsonb,'{"question_key":"mood_today","dimension":"mood","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000104',1,'["a_little"]'::jsonb,'{"question_key":"stress_today","dimension":"stress","choice_key":"a_little","label":"A little","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000105',0,'["very_good"]'::jsonb,'{"question_key":"body_today","dimension":"physical_wellbeing","choice_key":"very_good","label":"Very good","score":0,"is_core":true}'::jsonb,'{"demo": true}'::jsonb),
  ('52000000-0000-0000-0000-000000000105','51000000-0000-0000-0000-000000000106',1,'["mostly_connected"]'::jsonb,'{"question_key":"connected_today","dimension":"connectedness","choice_key":"mostly_connected","label":"Mostly connected","score":1,"is_core":true}'::jsonb,'{"demo": true}'::jsonb)
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
    '30000000-0000-0000-0000-000000000001',
    current_date - 7,
    current_date - 1,
    'tier1',
    'ready',
    '{
      "headline":"Sleep and stress improved through the week, with connectedness still worth monitoring.",
      "daily_burden_average":1.28,
      "mood_trend":"Mood moved from mixed to mostly steady by the end of the week.",
      "sleep_trend":"Sleep strain eased after the first two check-ins.",
      "stress_trend":"Stress started high but trended down as the week settled.",
      "energy_trend":"Energy improved in step with sleep.",
      "physical_trend":"Physical discomfort stayed mild overall.",
      "connectedness_trend":"Connection improved, but one isolated day still matters.",
      "risk_flags":["Sleep strain repeating early week","Stress elevated across days"],
      "profile_tags":["sleep_vulnerable","school_pressure_driven","low_help_seeking"]
    }'::jsonb,
    '{"checkins":5,"chat_sessions":0}'::jsonb,
    'demo-v2',
    now()
  )
on conflict (student_profile_id, week_start, week_end) do update
set privacy_tier_applied = excluded.privacy_tier_applied,
    summary_status = excluded.summary_status,
    summary = excluded.summary,
    source_window = excluded.source_window,
    generation_version = excluded.generation_version,
    generated_at = excluded.generated_at;
