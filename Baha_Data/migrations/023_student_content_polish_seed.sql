update content_items
set
  summary = 'Sleep routines, digital boundaries, and calming habits for steadier nights.',
  updated_at = now()
where id = '60000000-0000-0000-0000-000000000001';

update content_versions
set
  body = '{
    "blocks": [
      {
        "type": "heading",
        "value": "Why sleep routines matter"
      },
      {
        "type": "text",
        "value": "Small routines help your brain slow down in the same order each evening. That makes falling asleep easier and makes the next morning feel less chaotic."
      },
      {
        "type": "bullet_list",
        "title": "Three sleep-friendly habits",
        "items": [
          "Keep roughly the same sleep and wake time most days.",
          "Dim screens and bright lights for the last 30 minutes before bed.",
          "Choose one calming habit like stretching, reading, or quiet music."
        ]
      },
      {
        "type": "callout",
        "title": "Try this tonight",
        "value": "Pick one small signal that bedtime has started, such as putting your phone on charge away from the pillow."
      },
      {
        "type": "reflection_prompt",
        "value": "Which part of your current night routine makes it hardest to settle down?"
      }
    ]
  }'::jsonb,
  plain_text = 'Small routines help your brain slow down in the same order each evening. Keep a stable sleep time, lower stimulation before bed, and pick one calming habit.',
  changelog = 'Expanded student module body for richer Flutter Learn rendering',
  updated_at = now()
where id = '61000000-0000-0000-0000-000000000001';

insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000004',
    'demo-student-module-focus-reset',
    'Focus Reset for Study Sessions',
    'learning_module',
    'student',
    '13_14',
    'Focus',
    'study_habits',
    'attention_reset',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Build a calmer study start, shorter focus blocks, and a reset plan when your mind drifts.',
    '{"demo": true, "featured": true}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000005',
    'demo-student-module-digital-balance',
    'Digital Balance After School',
    'learning_module',
    'student',
    '13_14',
    'Digital Wellness',
    'digital_habits',
    'screen_boundaries',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Reset from scrolling loops and build a healthier after-school screen rhythm.',
    '{"demo": true, "featured": true}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000006',
    'demo-student-night-reset-checklist',
    'Night Reset Checklist',
    'checklist',
    'student',
    '13_14',
    'Sleep',
    'sleep_habits',
    'wind_down',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A quick evening checklist for winding down before bed.',
    '{"demo": true, "featured": false}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000007',
    'demo-student-exam-stress-reflection',
    'Exam Stress Reflection',
    'reflection_prompt',
    'student',
    '13_14',
    'Exam Stress',
    'stress_support',
    'reflection',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A guided reflection prompt to slow down spiraling exam thoughts.',
    '{"demo": true, "featured": false}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000008',
    'demo-student-screen-breaks-card',
    'Screen Breaks That Actually Work',
    'learning_card',
    'student',
    '13_14',
    'Digital Wellness',
    'digital_habits',
    'energy_reset',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'Tiny reset ideas for when a quick break is better than pushing harder.',
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
    '61000000-0000-0000-0000-000000000004',
    '60000000-0000-0000-0000-000000000004',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "heading",
          "value": "Reset before you start"
        },
        {
          "type": "text",
          "value": "A focus routine works better when you decide how to begin instead of waiting to feel perfectly ready."
        },
        {
          "type": "bullet_list",
          "title": "Use this three-part start",
          "items": [
            "Choose one task small enough to begin in under two minutes.",
            "Set a short focus block, like 15 or 20 minutes.",
            "Put one distraction farther away before you begin."
          ]
        },
        {
          "type": "callout",
          "title": "When focus slips",
          "value": "Reset the block instead of blaming yourself. Close the distraction, take one breath, and restart with a smaller target."
        },
        {
          "type": "reflection_prompt",
          "value": "What usually pulls your attention away first: noise, phone, worry, or boredom?"
        }
      ]
    }'::jsonb,
    'Choose one small task, set a short focus block, and move one distraction away before you begin.',
    'Expanded demo focus module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000005',
    '60000000-0000-0000-0000-000000000005',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "heading",
          "value": "Build a softer after-school reset"
        },
        {
          "type": "text",
          "value": "Scrolling is not always the problem. The harder part is when one quick check turns into losing your whole evening without noticing."
        },
        {
          "type": "checklist",
          "title": "Try this sequence",
          "items": [
            "Put your bag down and drink water first.",
            "Decide whether this is a rest break or a scroll break.",
            "Set a stop cue before opening the app."
          ]
        },
        {
          "type": "callout",
          "title": "Easy stop cues",
          "value": "Use a timer, a playlist ending, or a parent/guardian check-in as the signal that the break is done."
        },
        {
          "type": "reflection_prompt",
          "value": "Which app is hardest to stop once you open it, and what cue could interrupt that loop?"
        }
      ]
    }'::jsonb,
    'Choose a stop cue before you open the app so one short break does not take the whole evening.',
    'Expanded demo digital wellness module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000006',
    '60000000-0000-0000-0000-000000000006',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "checklist",
          "title": "Night reset",
          "items": [
            "Charge your phone away from the pillow.",
            "Choose tomorrow''s clothes or bag item now.",
            "Lower brightness and noise for the last half hour.",
            "Pick one calm activity to end the day."
          ]
        },
        {
          "type": "callout",
          "title": "Good enough is enough",
          "value": "You do not need a perfect night routine. Repeating one or two steps most evenings is already progress."
        }
      ]
    }'::jsonb,
    'Charge the phone away from the pillow, lower stimulation, and choose one calm end-of-day habit.',
    'Added student checklist content',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000007',
    '60000000-0000-0000-0000-000000000007',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "reflection_prompt",
          "title": "Slow the spiral",
          "value": "What are you telling yourself about this exam right now, and what would be a calmer but still honest version of that thought?"
        },
        {
          "type": "text",
          "value": "Reflection works best when it leads to one action. After you answer the question, pick one next step you can finish in ten minutes or less."
        }
      ]
    }'::jsonb,
    'Notice the stressful thought, rewrite it more calmly, then choose one ten-minute next step.',
    'Added student reflection content',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000008',
    '60000000-0000-0000-0000-000000000008',
    1,
    'published',
    '{
      "blocks": [
        {
          "type": "bullet_list",
          "title": "Break ideas",
          "items": [
            "Stand up and stretch your shoulders.",
            "Look out of the window for one minute.",
            "Walk to get water and come straight back.",
            "Take five slower breaths before the next task."
          ]
        },
        {
          "type": "callout",
          "title": "Pick one reset",
          "value": "A useful break should help you return, not make it harder to begin again."
        }
      ]
    }'::jsonb,
    'Use short breaks that make re-entry easier, not harder.',
    'Added student learning card content',
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
  ('61000000-0000-0000-0000-000000000004', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000005', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000006', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000007', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000008', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb)
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
    '62000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000004',
    'STU-FOCUS-001',
    'student',
    'Focus',
    '13_14',
    10,
    2,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000005',
    'STU-DIGITAL-001',
    'student',
    'Digital Wellness',
    '13_14',
    8,
    3,
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
  ('62000000-0000-0000-0000-000000000102', '62000000-0000-0000-0000-000000000002', 'Set Up a Focus Start', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000103', '62000000-0000-0000-0000-000000000003', 'Reset the Scroll Loop', 1, '{"demo": true}'::jsonb)
on conflict (id) do update
set
  title = excluded.title,
  ordinal = excluded.ordinal,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_module_steps (id, section_id, content_item_id, step_type, title, ordinal, is_required, metadata)
values
  (
    '62000000-0000-0000-0000-000000000202',
    '62000000-0000-0000-0000-000000000102',
    '60000000-0000-0000-0000-000000000004',
    'content',
    'Build a calmer study start',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000203',
    '62000000-0000-0000-0000-000000000103',
    '60000000-0000-0000-0000-000000000005',
    'content',
    'Choose a stop cue',
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
