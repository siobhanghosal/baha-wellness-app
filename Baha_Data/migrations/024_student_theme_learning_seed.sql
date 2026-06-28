insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000009',
    'demo-student-module-peer-pressure',
    'Peer Pressure Without Losing Yourself',
    'learning_module',
    'student',
    '13_14',
    'Peer Pressure',
    'peer_pressure_support',
    'boundary_setting',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Practice noticing pressure, buying time, and choosing a response that still feels like you.',
    '{"demo": true, "featured": true, "coverage_note": "direct corpus coverage remains thin; this module is a reviewed manual starter built from adjacent communication and decision-making themes"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000010',
    'demo-student-module-exam-stress-reset',
    'Exam Stress Reset Plan',
    'learning_module',
    'student',
    '13_14',
    'Exam Stress',
    'stress_support',
    'exam_planning',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Turn spiraling exam thoughts into a small plan, a reset action, and a manageable next step.',
    '{"demo": true, "featured": true, "coverage_note": "direct exam-stress coverage remains a gap area; this module is a reviewed manual starter"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000011',
    'demo-student-peer-pressure-script-card',
    'One Line You Can Say Under Pressure',
    'learning_card',
    'student',
    '13_14',
    'Peer Pressure',
    'peer_pressure_support',
    'response_script',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short script card for buying time and reducing social pressure in the moment.',
    '{"demo": true, "featured": false}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000012',
    'demo-student-exam-reset-checklist',
    '10-Minute Exam Reset',
    'checklist',
    'student',
    '13_14',
    'Exam Stress',
    'stress_support',
    'quick_reset',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A fast checklist for calming down enough to restart when exam pressure spikes.',
    '{"demo": true, "featured": false}'::jsonb
  )
on conflict (id) do update
set
  title = excluded.title,
  content_type = excluded.content_type,
  audience_app = excluded.audience_app,
  age_cohort = excluded.age_cohort,
  theme = excluded.theme,
  topic = excluded.topic,
  subtopic = excluded.subtopic,
  lifecycle_status = excluded.lifecycle_status,
  review_status = excluded.review_status,
  summary = excluded.summary,
  metadata = excluded.metadata,
  updated_at = now();

insert into content_versions (
  id, content_item_id, version_number, version_status, body, plain_text, changelog,
  reviewed_by, reviewed_at, effective_from, metadata
)
values
  (
    '61000000-0000-0000-0000-000000000009',
    '60000000-0000-0000-0000-000000000009',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "heading",
          "value": "Notice the pressure before you answer"
        },
        {
          "type": "text",
          "value": "Pressure works faster when you feel you must respond immediately. A better first move is to slow the moment down."
        },
        {
          "type": "step_list",
          "title": "Use this three-step reset",
          "items": [
            "Name what is happening: Is this teasing, pushing, or fear of missing out?",
            "Buy time with one short line instead of arguing straight away.",
            "Choose the answer you will still feel okay about later."
          ]
        },
        {
          "type": "callout",
          "title": "Good delay lines",
          "value": "Try: not now, I am good, maybe later, or I need a minute to think."
        },
        {
          "type": "reflection_prompt",
          "value": "Which type of pressure is hardest for you: being laughed at, being left out, or being rushed?"
        }
      ]
    }'::jsonb,
    'Slow the moment down, buy time with one short line, and choose the answer you can still respect later.',
    'Added student peer pressure module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000010',
    '60000000-0000-0000-0000-000000000010',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "heading",
          "value": "Make the next ten minutes smaller"
        },
        {
          "type": "text",
          "value": "Exam stress grows when everything feels urgent at once. A reset plan works best when it shrinks the next task instead of trying to solve the whole problem."
        },
        {
          "type": "bullet_list",
          "title": "Reset formula",
          "items": [
            "Settle your body with one minute of slower breathing.",
            "Pick the smallest useful task you can finish next.",
            "Decide when you will stop and check in again."
          ]
        },
        {
          "type": "callout",
          "title": "Smaller is smarter",
          "value": "A ten-minute restart usually works better than waiting until you feel perfectly calm."
        },
        {
          "type": "reflection_prompt",
          "value": "When exam stress spikes, which thought shows up first: I am behind, I will fail, or I cannot focus?"
        }
      ]
    }'::jsonb,
    'Calm your body, choose one smaller task, and restart with a ten-minute plan.',
    'Added student exam stress module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000011',
    '60000000-0000-0000-0000-000000000011',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "callout",
          "title": "Try this line",
          "value": "I am not up for that. Let us do something else."
        },
        {
          "type": "text",
          "value": "Short answers often work better than long explanations. You do not have to sound perfect to protect your boundary."
        }
      ]
    }'::jsonb,
    'Use a short line to protect your boundary without overexplaining.',
    'Added peer pressure quick guide',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000012',
    '60000000-0000-0000-0000-000000000012',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "checklist",
          "title": "10-minute exam reset",
          "items": [
            "Put the phone farther away for the next ten minutes.",
            "Write one tiny task instead of the whole chapter.",
            "Do that task before you judge how well it is going.",
            "Take one breath and choose the next tiny task."
          ]
        },
        {
          "type": "callout",
          "title": "Use motion, not mood",
          "value": "You do not need to feel fully ready before you start again."
        }
      ]
    }'::jsonb,
    'Put the phone away, choose one tiny task, and restart before your thoughts get louder again.',
    'Added exam stress checklist',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  )
on conflict (id) do update
set
  version_status = excluded.version_status,
  body = excluded.body,
  plain_text = excluded.plain_text,
  changelog = excluded.changelog,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  effective_from = excluded.effective_from,
  metadata = excluded.metadata,
  updated_at = now();

insert into content_publish_targets (
  content_version_id, audience_app, platform, age_cohort, activation_status,
  effective_from, metadata
)
values
  ('61000000-0000-0000-0000-000000000009', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000010', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000011', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000012', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb)
on conflict (content_version_id, audience_app, platform, age_cohort) do update
set
  activation_status = excluded.activation_status,
  effective_from = excluded.effective_from,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_modules (
  id, content_item_id, module_code, role_track, theme, age_cohort, estimated_minutes, sort_order, active, metadata
)
values
  (
    '62000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000009',
    'STU-PEER-001',
    'student',
    'Peer Pressure',
    '13_14',
    9,
    4,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000010',
    'STU-EXAM-001',
    'student',
    'Exam Stress',
    '13_14',
    9,
    5,
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do update
set
  content_item_id = excluded.content_item_id,
  module_code = excluded.module_code,
  role_track = excluded.role_track,
  theme = excluded.theme,
  age_cohort = excluded.age_cohort,
  estimated_minutes = excluded.estimated_minutes,
  sort_order = excluded.sort_order,
  active = excluded.active,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_module_sections (id, module_id, title, ordinal, metadata)
values
  ('62000000-0000-0000-0000-000000000104', '62000000-0000-0000-0000-000000000004', 'Respond Without Rushing', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000105', '62000000-0000-0000-0000-000000000005', 'Shrink the Next Step', 1, '{"demo": true}'::jsonb)
on conflict (id) do update
set
  title = excluded.title,
  ordinal = excluded.ordinal,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_module_steps (id, section_id, content_item_id, step_type, title, ordinal, is_required, metadata)
values
  (
    '62000000-0000-0000-0000-000000000204',
    '62000000-0000-0000-0000-000000000104',
    '60000000-0000-0000-0000-000000000009',
    'content',
    'Notice pressure and buy time',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000205',
    '62000000-0000-0000-0000-000000000105',
    '60000000-0000-0000-0000-000000000010',
    'content',
    'Reset into one smaller task',
    1,
    true,
    '{"demo": true}'::jsonb
  )
on conflict (id) do update
set
  content_item_id = excluded.content_item_id,
  step_type = excluded.step_type,
  title = excluded.title,
  ordinal = excluded.ordinal,
  is_required = excluded.is_required,
  metadata = excluded.metadata,
  updated_at = now();
