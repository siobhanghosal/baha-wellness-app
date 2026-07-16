insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000021',
    'student-9-12-sleep-and-recharge',
    'Sleep and Recharge',
    'learning_module',
    'student',
    '9_12',
    'Sleep',
    'sleep_habits',
    'bedtime_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short sleep lane about bedtime habits, calmer evenings, and better rest.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Sleep and Recharge"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000022',
    'student-9-12-stress-calm-through-stress',
    'Calm Through Stress',
    'learning_module',
    'student',
    '9_12',
    'Stress',
    'stress_support',
    'calm_toolbox',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short stress lane about noticing worry, using calm tools, and asking for help.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Calm Through Stress"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000023',
    'student-9-12-bullying-and-kindness',
    'Bullying and Kindness',
    'learning_module',
    'student',
    '9_12',
    'Bullying',
    'peer_safety',
    'trusted_help',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short bullying lane about safe actions, kind bystander choices, and trusted adults.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Bullying and Kindness"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000024',
    'student-9-12-healthy-gaming',
    'Healthy Gaming',
    'learning_module',
    'student',
    '9_12',
    'Healthy Gaming',
    'digital_balance',
    'daily_rhythm',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short gaming lane about balance, online safety, and making room for life away from the screen.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Healthy Gaming"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000025',
    'student-9-12-alcohol-safety',
    'Alcohol Safety',
    'learning_module',
    'student',
    '9_12',
    'Alcohol Safety',
    'substance_safety',
    'safe_choices',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short safety lane about saying no, asking a trusted adult for help, and staying safe.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Alcohol Safety"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000026',
    'student-9-12-bedtime-routine-starter',
    'Bedtime Routine Starter',
    'checklist',
    'student',
    '9_12',
    'Sleep',
    'sleep_habits',
    'quick_practice',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short bedtime checklist that supports the main sleep lane.',
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000027',
    'student-9-12-fast-calm-choices',
    'Fast Calm Choices',
    'learning_card',
    'student',
    '9_12',
    'Stress',
    'stress_support',
    'quick_practice',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short calm card that supports the main stress lane.',
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000028',
    'student-9-12-helpful-bystander-card',
    'Helpful Bystander Card',
    'learning_card',
    'student',
    '9_12',
    'Bullying',
    'peer_safety',
    'quick_practice',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short card about safe ways to help when someone is being bullied.',
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000029',
    'student-9-12-balanced-day-check',
    'Balanced Day Check',
    'checklist',
    'student',
    '9_12',
    'Healthy Gaming',
    'digital_balance',
    'quick_practice',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short checklist for keeping games balanced with sleep, school, and play.',
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000030',
    'student-9-12-safe-response-lines',
    'Safe Response Lines',
    'learning_card',
    'student',
    '9_12',
    'Alcohol Safety',
    'substance_safety',
    'quick_practice',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short set of lines children can remember if something unsafe happens around alcohol.',
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
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
    '61000000-0000-0000-0000-000000000021',
    '60000000-0000-0000-0000-000000000021',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Why sleep helps so much"},
        {"type":"text","value":"Sleep gives your body and brain time to rest, grow, and get ready for the next day. When your bedtime is steadier, school, mood, and energy often feel easier too."},
        {"type":"bullet_list","title":"Three habits that help","items":["Go to bed around the same time each night.","Choose one calming bedtime habit like reading or quiet music.","Put bright screens away before sleep when possible."]},
        {"type":"callout","title":"Try this tonight","value":"Pick one simple bedtime signal, like charging your device away from the pillow or opening a book before lights out."},
        {"type":"reflection_prompt","value":"What part of your evening makes it hardest to settle down?"}
      ]
    }'::jsonb,
    'Sleep helps your body and brain grow strong. A calm routine, less stimulation, and one steady bedtime habit can make nights easier.',
    'Add 9-12 sleep lane starter module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000022',
    '60000000-0000-0000-0000-000000000022',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Stress happens to everyone sometimes"},
        {"type":"text","value":"Stress is your body''s way of reacting when something feels important, difficult, or new. It can show up in your thoughts, your feelings, or even your tummy and head."},
        {"type":"step_list","title":"Use this calm plan","items":["Notice what your body is doing first.","Choose one calm tool like breathing, drawing, or talking to someone you trust.","Take the next smallest step instead of trying to solve everything at once."]},
        {"type":"callout","title":"You are not doing it wrong","value":"Feeling stressed does not mean something is wrong with you. It means your body may need support and a simpler next step."},
        {"type":"reflection_prompt","value":"When stress shows up for you, what do you notice first: worry, a headache, a tummy ache, or wanting quiet?"}
      ]
    }'::jsonb,
    'Stress can feel big, but a small calm plan often helps more than waiting to feel perfect.',
    'Add 9-12 stress lane starter module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000023',
    '60000000-0000-0000-0000-000000000023',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Bullying is repeated hurt on purpose"},
        {"type":"text","value":"Bullying can happen in person or online. It is not your job to handle it alone, and the safest next move usually includes a trusted adult."},
        {"type":"bullet_list","title":"Safe next steps","items":["Move toward a safe place where adults are nearby.","Stay with supportive friends if you can.","Tell a teacher, parent, counselor, or another trusted adult.","Keep speaking up if it keeps happening."]},
        {"type":"callout","title":"Being kind still matters","value":"If you see bullying, helping safely can mean inviting someone into your group, not laughing along, and telling an adult."},
        {"type":"reflection_prompt","value":"If someone around you felt left out or laughed at, what safe action could you take first?"}
      ]
    }'::jsonb,
    'Bullying is never okay. Safe help, kind action, and trusted adults matter.',
    'Add 9-12 bullying lane starter module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000024',
    '60000000-0000-0000-0000-000000000024',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Games are fun when they stay in balance"},
        {"type":"text","value":"Gaming can be creative and exciting, but it should not take the place of sleep, school, friends, movement, or family time. A balanced day helps games stay fun."},
        {"type":"checklist","title":"Healthy gaming habits","items":["Finish important tasks before a longer game session.","Take breaks to move your body.","Protect your private information online.","Stop in time for sleep."]},
        {"type":"callout","title":"Balance beats all-or-nothing","value":"The goal is not to never play. The goal is to notice when games start crowding out the rest of your life."},
        {"type":"reflection_prompt","value":"What part of your day do games make hardest to protect: homework, outside play, family time, or sleep?"}
      ]
    }'::jsonb,
    'Games should stay one part of a healthy day, not the whole day.',
    'Add 9-12 healthy gaming lane starter module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000025',
    '60000000-0000-0000-0000-000000000025',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Alcohol is not for children"},
        {"type":"text","value":"Children''s bodies and brains are still growing, which is why alcohol is unsafe for them. If something feels wrong, you do not have to deal with it by yourself."},
        {"type":"step_list","title":"Safe response plan","items":["Say no or step away if something feels unsafe.","Do not take a drink if you do not know what is in it.","Find a parent, teacher, or another trusted adult right away."]},
        {"type":"callout","title":"Saying no is brave","value":"A short safe response works well. You do not need a perfect speech to protect yourself."},
        {"type":"reflection_prompt","value":"Which trusted adult would you go to first if someone offered you something unsafe?"}
      ]
    }'::jsonb,
    'Alcohol is unsafe for children. Saying no and finding a trusted adult is the safest plan.',
    'Add 9-12 alcohol safety lane starter module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000026',
    '60000000-0000-0000-0000-000000000026',
    1,
    'published',
    '{
      "blocks": [
        {"type":"checklist","title":"My bedtime routine starter","items":["Brush teeth","Put away bright screens","Choose a calm activity","Dim the lights","Get into bed around the same time"]},
        {"type":"callout","title":"Keep it simple","value":"A short routine you actually use is better than a perfect plan you never follow."}
      ]
    }'::jsonb,
    'A bedtime routine can be short, calm, and repeatable.',
    'Add 9-12 sleep quick support card',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000027',
    '60000000-0000-0000-0000-000000000027',
    1,
    'published',
    '{
      "blocks": [
        {"type":"callout","title":"Try one fast calm choice","value":"Slow breathing, coloring, a quiet walk with an adult, or talking to someone you trust can all help your body settle."},
        {"type":"text","value":"You do not need ten strategies at once. One calm choice is enough to start."}
      ]
    }'::jsonb,
    'One calm choice is enough to begin.',
    'Add 9-12 stress quick support card',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000028',
    '60000000-0000-0000-0000-000000000028',
    1,
    'published',
    '{
      "blocks": [
        {"type":"bullet_list","title":"Helpful bystander ideas","items":["Invite the person into your group.","Do not laugh or cheer the bully.","Tell a trusted adult what happened.","Stay safe and do not start a fight."]},
        {"type":"callout","title":"Safe help counts","value":"Helping does not mean putting yourself in danger. Telling an adult is still real help."}
      ]
    }'::jsonb,
    'Helping safely matters more than being dramatic or risky.',
    'Add 9-12 bullying quick support card',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000029',
    '60000000-0000-0000-0000-000000000029',
    1,
    'published',
    '{
      "blocks": [
        {"type":"checklist","title":"Balanced day check","items":["I made time for school or homework.","I took a movement break.","I kept private information private.","I stopped in time for sleep.","I made room for something away from the screen."]},
        {"type":"callout","title":"Balance is the goal","value":"Games can stay fun when the rest of your day still has room to breathe."}
      ]
    }'::jsonb,
    'A good gaming day still protects sleep, school, and real-world time.',
    'Add 9-12 healthy gaming quick support card',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000030',
    '60000000-0000-0000-0000-000000000030',
    1,
    'published',
    '{
      "blocks": [
        {"type":"callout","title":"Safe response lines","value":"Try: no thank you, I do not want that, I am going to find my parent, or let us do something else."},
        {"type":"text","value":"Short answers often work better than long explanations when something feels unsafe."}
      ]
    }'::jsonb,
    'Short safe lines can help a child buy time and move toward a trusted adult.',
    'Add 9-12 alcohol safety quick support card',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12", "lane_role": "quick_support"}'::jsonb
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
  ('61000000-0000-0000-0000-000000000021', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000022', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000023', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000024', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000025', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000026', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000027', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000028', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000029', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000030', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb)
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
    '62000000-0000-0000-0000-000000000021',
    '60000000-0000-0000-0000-000000000021',
    'STU-912-SLEEP-001',
    'student',
    'Sleep',
    '9_12',
    6,
    1,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000022',
    '60000000-0000-0000-0000-000000000022',
    'STU-912-STRESS-001',
    'student',
    'Stress',
    '9_12',
    6,
    1,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000023',
    '60000000-0000-0000-0000-000000000023',
    'STU-912-BULLY-001',
    'student',
    'Bullying',
    '9_12',
    6,
    1,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000024',
    '60000000-0000-0000-0000-000000000024',
    'STU-912-GAME-001',
    'student',
    'Healthy Gaming',
    '9_12',
    6,
    1,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000025',
    '60000000-0000-0000-0000-000000000025',
    'STU-912-ALC-001',
    'student',
    'Alcohol Safety',
    '9_12',
    6,
    1,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
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
  ('62000000-0000-0000-0000-000000000121', '62000000-0000-0000-0000-000000000021', 'Rest, routine, and calmer nights', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000122', '62000000-0000-0000-0000-000000000022', 'Notice stress and shrink the next step', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000123', '62000000-0000-0000-0000-000000000023', 'Safe help and kind action', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000124', '62000000-0000-0000-0000-000000000024', 'Keep games in balance', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000125', '62000000-0000-0000-0000-000000000025', 'Say no and find help', 1, '{"demo": true}'::jsonb)
on conflict (id) do update
set
  title = excluded.title,
  ordinal = excluded.ordinal,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_module_steps (id, section_id, content_item_id, step_type, title, ordinal, is_required, metadata)
values
  (
    '62000000-0000-0000-0000-000000000221',
    '62000000-0000-0000-0000-000000000121',
    '60000000-0000-0000-0000-000000000021',
    'content',
    'Build a calmer bedtime',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000222',
    '62000000-0000-0000-0000-000000000122',
    '60000000-0000-0000-0000-000000000022',
    'content',
    'Use a calm plan',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000223',
    '62000000-0000-0000-0000-000000000123',
    '60000000-0000-0000-0000-000000000023',
    'content',
    'Choose a safe next step',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000224',
    '62000000-0000-0000-0000-000000000124',
    '60000000-0000-0000-0000-000000000024',
    'content',
    'Protect the rest of your day',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000225',
    '62000000-0000-0000-0000-000000000125',
    '60000000-0000-0000-0000-000000000025',
    'content',
    'Practice a safe response',
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

insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000031',
    'student-9-12-bedtime-habits-that-help',
    'Bedtime Habits That Help',
    'learning_module',
    'student',
    '9_12',
    'Sleep',
    'sleep_habits',
    'healthy_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about simple bedtime habits that help sleep feel steadier.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Bedtime Habits That Help"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000032',
    'student-9-12-screens-and-sleep',
    'Screens and Sleep',
    'learning_module',
    'student',
    '9_12',
    'Sleep',
    'sleep_habits',
    'screen_boundaries',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about why bright screens can make sleep harder and what to do instead.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Screens and Sleep"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000033',
    'student-9-12-what-stress-can-feel-like',
    'What Stress Can Feel Like',
    'learning_module',
    'student',
    '9_12',
    'Stress',
    'stress_support',
    'stress_signals',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about the body and feeling signs that can show up with stress.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "What Stress Can Feel Like"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000034',
    'student-9-12-my-calm-superpowers',
    'My Calm Superpowers',
    'learning_module',
    'student',
    '9_12',
    'Stress',
    'stress_support',
    'calm_tools',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about practical calm tools children can actually use.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "My Calm Superpowers"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000035',
    'student-9-12-what-bullying-can-look-like',
    'What Bullying Can Look Like',
    'learning_module',
    'student',
    '9_12',
    'Bullying',
    'peer_safety',
    'warning_signs',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about how bullying can look in person and online.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "What Bullying Can Look Like"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000036',
    'student-9-12-helping-safely',
    'Helping Safely',
    'learning_module',
    'student',
    '9_12',
    'Bullying',
    'peer_safety',
    'bystander_help',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about safe bystander actions and when to get adult help.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Helping Safely"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000037',
    'student-9-12-online-safety-in-games',
    'Online Safety in Games',
    'learning_module',
    'student',
    '9_12',
    'Healthy Gaming',
    'digital_balance',
    'online_safety',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about protecting private information and getting help when chats feel unsafe.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Online Safety in Games"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000038',
    'student-9-12-build-a-balanced-day',
    'Build a Balanced Day',
    'learning_module',
    'student',
    '9_12',
    'Healthy Gaming',
    'digital_balance',
    'daily_balance',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about making room for school, movement, family, and sleep alongside games.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Build a Balanced Day"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000039',
    'student-9-12-safe-choices-with-others',
    'Safe Choices With Others',
    'learning_module',
    'student',
    '9_12',
    'Alcohol Safety',
    'substance_safety',
    'social_safety',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about safe choices around friends, family events, and unknown drinks.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Safe Choices With Others"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000040',
    'student-9-12-who-can-help-right-away',
    'Who Can Help Right Away',
    'learning_module',
    'student',
    '9_12',
    'Alcohol Safety',
    'substance_safety',
    'trusted_help',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A short module about trusted adults, urgent safety, and what to do when a situation feels scary.',
    '{"demo": true, "lane_group": "age_9_12", "display_title": "Who Can Help Right Away"}'::jsonb
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
    '61000000-0000-0000-0000-000000000031',
    '60000000-0000-0000-0000-000000000031',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Small bedtime habits can make a big difference"},
        {"type":"text","value":"You do not need a perfect night routine. A few steady habits help your body notice that rest is getting closer."},
        {"type":"checklist","title":"Habits that help","items":["Brush teeth before bed.","Choose one quiet activity.","Keep the room calmer and more comfortable.","Try to wake up around the same time most days."]},
        {"type":"callout","title":"Keep it realistic","value":"A routine works best when it feels possible on normal school nights, not just on perfect days."},
        {"type":"reflection_prompt","value":"Which bedtime habit would be easiest for you to start this week?"}
      ]
    }'::jsonb,
    'A few steady bedtime habits can help sleep feel easier without making bedtime feel strict or complicated.',
    'Add second 9-12 sleep module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000032',
    '60000000-0000-0000-0000-000000000032',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Screens can wake your brain back up"},
        {"type":"text","value":"Phones, tablets, videos, and fast-moving games can make your brain feel more switched on right when you are trying to slow down."},
        {"type":"bullet_list","title":"Try these swaps","items":["Read or color instead of one more video.","Charge the device away from the pillow.","Pick one quiet screen-free activity before sleep."]},
        {"type":"callout","title":"You do not have to do it perfectly","value":"Even shortening screen time before bed a little can help more than doing nothing."},
        {"type":"reflection_prompt","value":"What screen habit keeps bedtime going later for you the most?"}
      ]
    }'::jsonb,
    'Bright or exciting screens can make bedtime harder, but small screen swaps can help.',
    'Add third 9-12 sleep module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000033',
    '60000000-0000-0000-0000-000000000033',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Stress can show up in your body too"},
        {"type":"text","value":"Stress does not only sound like worried thoughts. It can feel like a tummy ache, a headache, being grumpy, or wanting to hide away for a while."},
        {"type":"bullet_list","title":"Common stress clues","items":["Trouble focusing","Wanting extra quiet","Feeling tired or shaky","A faster heartbeat or funny tummy"]},
        {"type":"callout","title":"Notice before you judge","value":"The goal is not to be annoyed with yourself. The goal is to notice the signal earlier so you can help yourself sooner."},
        {"type":"reflection_prompt","value":"Which stress clue shows up in your body first most often?"}
      ]
    }'::jsonb,
    'Stress can feel physical as well as emotional, and noticing the clue early helps.',
    'Add second 9-12 stress module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000034',
    '60000000-0000-0000-0000-000000000034',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Your calm tools do not have to be fancy"},
        {"type":"text","value":"A calm tool is anything safe that helps your body settle enough to think again. The best calm tools are usually simple and easy to repeat."},
        {"type":"step_list","title":"Pick a calm tool","items":["Choose one thing that helps your body slow down.","Choose one thing that helps your thoughts feel smaller.","Choose one person you can talk to when the feeling stays big."]},
        {"type":"callout","title":"One tool is enough to begin","value":"You do not need the perfect answer. Start with one tool that feels possible today."},
        {"type":"reflection_prompt","value":"Which calm tool feels most natural to you right now: breathing, drawing, music, walking, or talking?"}
      ]
    }'::jsonb,
    'Calm tools work best when they are simple enough to use in real life.',
    'Add third 9-12 stress module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000035',
    '60000000-0000-0000-0000-000000000035',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Bullying is repeated hurt, not just one disagreement"},
        {"type":"text","value":"People can disagree sometimes without it being bullying. Bullying keeps happening on purpose and is meant to make someone feel smaller, scared, or left out."},
        {"type":"bullet_list","title":"Bullying can look like","items":["Name-calling","Leaving someone out on purpose","Spreading mean rumors","Sending hurtful messages online"]},
        {"type":"callout","title":"It is not your fault","value":"If someone keeps treating you badly, that does not mean you caused it or deserve it."},
        {"type":"reflection_prompt","value":"If someone saw this happening, how would they know it was repeated and not just one argument?"}
      ]
    }'::jsonb,
    'Children need help seeing the difference between conflict and bullying, because the response is different.',
    'Add second 9-12 bullying module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000036',
    '60000000-0000-0000-0000-000000000036',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Helping safely still counts as real help"},
        {"type":"text","value":"You do not need to be dramatic or put yourself in danger to help someone. Safe help is often the smartest kind."},
        {"type":"step_list","title":"A safe bystander plan","items":["Do not join in or laugh along.","Move toward a trusted adult or tell one quickly.","Be kind to the person afterward so they do not feel alone."]},
        {"type":"callout","title":"Do not start a fight","value":"Helping someone does not mean taking a risky action that could make the situation bigger."},
        {"type":"reflection_prompt","value":"Which safe bystander action would feel easiest for you to actually do?"}
      ]
    }'::jsonb,
    'Safe bystander help is more useful than dramatic but risky reactions.',
    'Add third 9-12 bullying module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000037',
    '60000000-0000-0000-0000-000000000037',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Online safety matters inside games too"},
        {"type":"text","value":"Games can feel friendly and exciting, but chats inside games are still online spaces. You should protect your private information there too."},
        {"type":"checklist","title":"Protect yourself online","items":["Do not share your full name, address, school, or passwords.","Tell a trusted adult if someone asks to meet you or keep a secret.","Leave or report chats that feel scary, mean, or pushy."]},
        {"type":"callout","title":"Your safety matters more than winning","value":"If something feels strange in a game or chat, getting help is the right move."},
        {"type":"reflection_prompt","value":"Which online safety rule do children forget most easily when they are having fun?"}
      ]
    }'::jsonb,
    'Online safety has to be part of the gaming conversation, not an afterthought.',
    'Add second 9-12 healthy gaming module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000038',
    '60000000-0000-0000-0000-000000000038',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"A balanced day makes games feel better"},
        {"type":"text","value":"Games stay more fun when they fit into a full day that still has room for homework, movement, meals, family, and sleep."},
        {"type":"bullet_list","title":"What balance can include","items":["School or homework first","Active play or movement","Time with family or friends","Stopping in time for sleep"]},
        {"type":"callout","title":"Balance is not the same as no fun","value":"The goal is not to remove games. The goal is to keep them from becoming the only thing your day revolves around."},
        {"type":"reflection_prompt","value":"What part of a balanced day is easiest to lose when gaming goes too long?"}
      ]
    }'::jsonb,
    'A balanced day is a better teaching goal than only warning children to play less.',
    'Add third 9-12 healthy gaming module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000039',
    '60000000-0000-0000-0000-000000000039',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Safe choices work best when they are simple"},
        {"type":"text","value":"Children do not need long speeches to stay safe. The safest choice is usually to say no, step away, and move toward a trusted adult."},
        {"type":"bullet_list","title":"Simple safe choices","items":["Do not drink something if you do not know what is in it.","Say no if someone pushes you to do something unsafe.","Ask an adult when you are unsure instead of guessing."]},
        {"type":"callout","title":"Trust your feelings","value":"If something feels strange or wrong, that feeling is important and worth acting on."},
        {"type":"reflection_prompt","value":"Which safe choice would be easiest for you to remember in the moment?"}
      ]
    }'::jsonb,
    'Safety guidance for children should be direct, simple, and easy to remember under pressure.',
    'Add second 9-12 alcohol safety module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000040',
    '60000000-0000-0000-0000-000000000040',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Trusted adults are part of the safety plan"},
        {"type":"text","value":"If someone offers a child alcohol, pressures them, or seems too unsafe to care for them, that is a trusted-adult moment right away."},
        {"type":"step_list","title":"Get help fast","items":["Find a parent, teacher, counselor, or another trusted adult.","Tell them exactly what happened.","Stay near safe adults and do not try to handle it alone."]},
        {"type":"callout","title":"Urgent means urgent","value":"If someone cannot wake up, cannot breathe properly, or is in immediate danger, tell an adult right away and call emergency help."},
        {"type":"reflection_prompt","value":"Who are two adults you could go to quickly if a situation felt scary?"}
      ]
    }'::jsonb,
    'Trusted-adult help needs to be explicit because children should not be left to improvise in unsafe moments.',
    'Add third 9-12 alcohol safety module',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
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
  ('61000000-0000-0000-0000-000000000031', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000032', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000033', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000034', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000035', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000036', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000037', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000038', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000039', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000040', 'student', 'android', '9_12', 'active', now(), '{"demo": true}'::jsonb)
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
    '62000000-0000-0000-0000-000000000031',
    '60000000-0000-0000-0000-000000000031',
    'STU-912-SLEEP-002',
    'student',
    'Sleep',
    '9_12',
    5,
    2,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000032',
    '60000000-0000-0000-0000-000000000032',
    'STU-912-SLEEP-003',
    'student',
    'Sleep',
    '9_12',
    5,
    3,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000033',
    '60000000-0000-0000-0000-000000000033',
    'STU-912-STRESS-002',
    'student',
    'Stress',
    '9_12',
    5,
    2,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000034',
    '60000000-0000-0000-0000-000000000034',
    'STU-912-STRESS-003',
    'student',
    'Stress',
    '9_12',
    5,
    3,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000035',
    '60000000-0000-0000-0000-000000000035',
    'STU-912-BULLY-002',
    'student',
    'Bullying',
    '9_12',
    5,
    2,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000036',
    '60000000-0000-0000-0000-000000000036',
    'STU-912-BULLY-003',
    'student',
    'Bullying',
    '9_12',
    5,
    3,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000037',
    '60000000-0000-0000-0000-000000000037',
    'STU-912-GAME-002',
    'student',
    'Healthy Gaming',
    '9_12',
    5,
    2,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000038',
    '60000000-0000-0000-0000-000000000038',
    'STU-912-GAME-003',
    'student',
    'Healthy Gaming',
    '9_12',
    5,
    3,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000039',
    '60000000-0000-0000-0000-000000000039',
    'STU-912-ALC-002',
    'student',
    'Alcohol Safety',
    '9_12',
    5,
    2,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000040',
    '60000000-0000-0000-0000-000000000040',
    'STU-912-ALC-003',
    'student',
    'Alcohol Safety',
    '9_12',
    5,
    3,
    true,
    '{"demo": true, "lane_group": "age_9_12"}'::jsonb
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
  ('62000000-0000-0000-0000-000000000131', '62000000-0000-0000-0000-000000000031', 'Simple habits that support sleep', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000132', '62000000-0000-0000-0000-000000000032', 'Why screens can delay sleep', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000133', '62000000-0000-0000-0000-000000000033', 'Body clues and stress signals', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000134', '62000000-0000-0000-0000-000000000034', 'Pick calm tools that feel real', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000135', '62000000-0000-0000-0000-000000000035', 'Know what bullying looks like', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000136', '62000000-0000-0000-0000-000000000036', 'Help safely without making it bigger', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000137', '62000000-0000-0000-0000-000000000037', 'Protect yourself inside games', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000138', '62000000-0000-0000-0000-000000000038', 'Make room for the rest of life', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000139', '62000000-0000-0000-0000-000000000039', 'Safe choices around other people', 1, '{"demo": true}'::jsonb),
  ('62000000-0000-0000-0000-000000000140', '62000000-0000-0000-0000-000000000040', 'Trusted adults and urgent help', 1, '{"demo": true}'::jsonb)
on conflict (id) do update
set
  title = excluded.title,
  ordinal = excluded.ordinal,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_module_steps (id, section_id, content_item_id, step_type, title, ordinal, is_required, metadata)
values
  (
    '62000000-0000-0000-0000-000000000231',
    '62000000-0000-0000-0000-000000000131',
    '60000000-0000-0000-0000-000000000031',
    'content',
    'Choose habits you can repeat',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000232',
    '62000000-0000-0000-0000-000000000132',
    '60000000-0000-0000-0000-000000000032',
    'content',
    'Swap one screen habit',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000233',
    '62000000-0000-0000-0000-000000000133',
    '60000000-0000-0000-0000-000000000033',
    'content',
    'Notice your first stress clue',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000234',
    '62000000-0000-0000-0000-000000000134',
    '60000000-0000-0000-0000-000000000034',
    'content',
    'Build a calm toolbox',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000235',
    '62000000-0000-0000-0000-000000000135',
    '60000000-0000-0000-0000-000000000035',
    'content',
    'Tell the difference between conflict and bullying',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000236',
    '62000000-0000-0000-0000-000000000136',
    '60000000-0000-0000-0000-000000000036',
    'content',
    'Help without taking unsafe risks',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000237',
    '62000000-0000-0000-0000-000000000137',
    '60000000-0000-0000-0000-000000000037',
    'content',
    'Protect private information',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000238',
    '62000000-0000-0000-0000-000000000138',
    '60000000-0000-0000-0000-000000000038',
    'content',
    'Keep games in a full day',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000239',
    '62000000-0000-0000-0000-000000000139',
    '60000000-0000-0000-0000-000000000039',
    'content',
    'Use simple safe choices',
    1,
    true,
    '{"demo": true}'::jsonb
  ),
  (
    '62000000-0000-0000-0000-000000000240',
    '62000000-0000-0000-0000-000000000140',
    '60000000-0000-0000-0000-000000000040',
    'content',
    'Know who to tell right away',
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
