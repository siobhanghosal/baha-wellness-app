update learning_modules
set active = false,
    updated_at = now()
where role_track = 'student'
  and age_cohort in ('13_14', '15_18', '18_plus')
  and coalesce(metadata ->> 'demo', 'false') = 'true';

update content_items
set lifecycle_status = 'archived',
    updated_at = now()
where audience_app = 'student'
  and age_cohort in ('13_14', '15_18', '18_plus')
  and coalesce(metadata ->> 'demo', 'false') = 'true';

insert into content_items (
  id, slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
values
  (
    '60000000-0000-0000-0000-000000000101',
    'student-13-14-sleep-reset',
    'Sleep Reset',
    'learning_module',
    'student',
    '13_14',
    'Sleep',
    'sleep_habits',
    'recovery_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A teen-facing sleep module about routines, screens, and better daytime energy.',
    '{"demo": true, "lane_group": "age_13_14", "display_title": "Sleep Reset"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000102',
    'student-13-14-stress-reset',
    'Stress Reset',
    'learning_module',
    'student',
    '13_14',
    'Stress',
    'stress_support',
    'school_pressure',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A teen-facing stress module about pressure, calm tools, and asking for help sooner.',
    '{"demo": true, "lane_group": "age_13_14", "display_title": "Stress Reset"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000103',
    'student-13-14-bullying-and-boundaries',
    'Bullying and Boundaries',
    'learning_module',
    'student',
    '13_14',
    'Bullying',
    'peer_safety',
    'safe_escalation',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A teen-facing safety module about repeated harm, online behaviour, and adult help.',
    '{"demo": true, "lane_group": "age_13_14", "display_title": "Bullying and Boundaries"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000104',
    'student-13-14-healthy-gaming',
    'Healthy Gaming',
    'learning_module',
    'student',
    '13_14',
    'Healthy Gaming',
    'digital_balance',
    'screen_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A teen-facing gaming module about balance, online safety, and protecting sleep.',
    '{"demo": true, "lane_group": "age_13_14", "display_title": "Healthy Gaming"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000105',
    'student-13-14-alcohol-safety',
    'Alcohol Safety',
    'learning_module',
    'student',
    '13_14',
    'Alcohol Safety',
    'substance_safety',
    'safer_choices',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A teen-facing alcohol safety module about peer pressure, confidence, and safe exits.',
    '{"demo": true, "lane_group": "age_13_14", "display_title": "Alcohol Safety"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000106',
    'student-15-18-sleep-and-recovery',
    'Sleep and Recovery',
    'learning_module',
    'student',
    '15_18',
    'Sleep',
    'sleep_habits',
    'recovery_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A later-teen sleep module about late nights, recovery, and protecting focus.',
    '{"demo": true, "lane_group": "age_15_18", "display_title": "Sleep and Recovery"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000107',
    'student-15-18-handling-stress',
    'Handling Stress',
    'learning_module',
    'student',
    '15_18',
    'Stress',
    'stress_support',
    'pressure_management',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A later-teen stress module about workload, expectations, and manageable next steps.',
    '{"demo": true, "lane_group": "age_15_18", "display_title": "Handling Stress"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000108',
    'student-15-18-bullying-and-boundaries',
    'Bullying and Boundaries',
    'learning_module',
    'student',
    '15_18',
    'Bullying',
    'peer_safety',
    'safe_escalation',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A later-teen safety module about repeated harm, documentation, and escalation.',
    '{"demo": true, "lane_group": "age_15_18", "display_title": "Bullying and Boundaries"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000109',
    'student-15-18-healthy-gaming',
    'Healthy Gaming',
    'learning_module',
    'student',
    '15_18',
    'Healthy Gaming',
    'digital_balance',
    'screen_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A later-teen gaming module about time balance, habits, and online conduct.',
    '{"demo": true, "lane_group": "age_15_18", "display_title": "Healthy Gaming"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000110',
    'student-15-18-alcohol-safety',
    'Alcohol Safety',
    'learning_module',
    'student',
    '15_18',
    'Alcohol Safety',
    'substance_safety',
    'safer_choices',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A later-teen alcohol safety module about pressure, planning, and safer decisions.',
    '{"demo": true, "lane_group": "age_15_18", "display_title": "Alcohol Safety"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000111',
    'student-18-plus-sleep-and-recovery',
    'Sleep and Recovery',
    'learning_module',
    'student',
    '18_plus',
    'Sleep',
    'sleep_habits',
    'recovery_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A young-adult sleep module about protecting recovery, judgment, and sustainable routines.',
    '{"demo": true, "lane_group": "age_18_plus", "display_title": "Sleep and Recovery"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000112',
    'student-18-plus-stress-under-pressure',
    'Stress Under Pressure',
    'learning_module',
    'student',
    '18_plus',
    'Stress',
    'stress_support',
    'pressure_management',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A young-adult stress module about responsibility, workload, and support before overload.',
    '{"demo": true, "lane_group": "age_18_plus", "display_title": "Stress Under Pressure"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000113',
    'student-18-plus-bullying-and-boundaries',
    'Bullying and Boundaries',
    'learning_module',
    'student',
    '18_plus',
    'Bullying',
    'peer_safety',
    'safe_escalation',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A young-adult safety module about repeated harm, self-protection, and escalation.',
    '{"demo": true, "lane_group": "age_18_plus", "display_title": "Bullying and Boundaries"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000114',
    'student-18-plus-healthy-gaming',
    'Healthy Gaming',
    'learning_module',
    'student',
    '18_plus',
    'Healthy Gaming',
    'digital_balance',
    'screen_routine',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A young-adult gaming module about self-management, priorities, and digital balance.',
    '{"demo": true, "lane_group": "age_18_plus", "display_title": "Healthy Gaming"}'::jsonb
  ),
  (
    '60000000-0000-0000-0000-000000000115',
    'student-18-plus-alcohol-safety',
    'Alcohol Safety',
    'learning_module',
    'student',
    '18_plus',
    'Alcohol Safety',
    'substance_safety',
    'safer_choices',
    'en',
    'none',
    'tier1',
    'active',
    'approved',
    'manual',
    'A young-adult alcohol safety module about social situations, impairment, and safe exits.',
    '{"demo": true, "lane_group": "age_18_plus", "display_title": "Alcohol Safety"}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
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
    '61000000-0000-0000-0000-000000000101',
    '60000000-0000-0000-0000-000000000101',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Sleep is part of how you recover"},
        {"type":"text","value":"Sleep helps your brain store learning, your body recharge, and your mood stay steadier. When sleep slips, school, memory, and patience often slip with it."},
        {"type":"bullet_list","title":"What gets in the way","items":["Late-night scrolling","Gaming too close to bedtime","Homework pushed very late","An inconsistent bedtime"]},
        {"type":"step_list","title":"Try this reset","items":["Choose one steady bedtime target.","Put your phone away earlier.","Use one calm wind-down habit."]},
        {"type":"reflection_prompt","value":"Which part of your evening usually keeps sleep from happening on time?"}
      ]
    }'::jsonb,
    'Sleep supports learning, energy, and mood. Small changes to screens and bedtime routines can make a real difference.',
    'Refresh 13-14 sleep lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_13_14"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000102',
    '60000000-0000-0000-0000-000000000102',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Stress is real, but it can be managed"},
        {"type":"text","value":"Stress is your body and mind reacting to pressure. It can show up as worry, frustration, headaches, low motivation, or trouble concentrating."},
        {"type":"bullet_list","title":"Common stress drivers","items":["School deadlines","Friendship tension","Online pressure","Trying to do too much at once"]},
        {"type":"step_list","title":"A calmer next-step plan","items":["Name what feels heavy.","Break it into one smaller task.","Use one calming tool.","Ask for help sooner."]},
        {"type":"reflection_prompt","value":"When pressure shows up, what tends to happen first for you: worry, tiredness, frustration, or shutdown?"}
      ]
    }'::jsonb,
    'Stress becomes easier to manage when you notice it earlier and stop trying to carry everything at once.',
    'Refresh 13-14 stress lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_13_14"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000103',
    '60000000-0000-0000-0000-000000000103',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Repeated harm deserves real support"},
        {"type":"text","value":"Bullying is not just one disagreement. It is repeated behavior meant to hurt, embarrass, or exclude someone, and it can happen in person or online."},
        {"type":"bullet_list","title":"Useful clues","items":["It keeps happening","It feels targeted","It affects safety or confidence","It is hard to handle alone"]},
        {"type":"step_list","title":"Safer next moves","items":["Move toward safer people.","Keep screenshots if it is online.","Tell a trusted adult.","Do not keep carrying it alone."]},
        {"type":"reflection_prompt","value":"If something kept happening online or at school, which adult would be the easiest to tell first?"}
      ]
    }'::jsonb,
    'Bullying gets easier to interrupt when you treat it as a safety issue, not something you must fix by yourself.',
    'Refresh 13-14 bullying lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_13_14"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000104',
    '60000000-0000-0000-0000-000000000104',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Gaming works best inside a balanced week"},
        {"type":"text","value":"Gaming can be fun, social, and rewarding. The problem starts when it quietly pushes out sleep, homework, movement, or real-life time."},
        {"type":"bullet_list","title":"Watch for balance slips","items":["Staying up late","Homework drifting","Feeling tired at school","Getting frustrated when you have to stop"]},
        {"type":"checklist","title":"Healthy habits that help","items":["Finish key work first","Take breaks","Protect bedtime","Keep private details private online"]},
        {"type":"reflection_prompt","value":"What part of life gets crowded out first when gaming takes up too much space?"}
      ]
    }'::jsonb,
    'Healthy gaming is not about quitting. It is about protecting the rest of your life too.',
    'Refresh 13-14 healthy gaming lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_13_14"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000105',
    '60000000-0000-0000-0000-000000000105',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Safe choices matter more than fitting in"},
        {"type":"text","value":"Alcohol can affect judgment, memory, and safety, especially for teenagers whose brains and bodies are still developing."},
        {"type":"bullet_list","title":"Risky moments can include","items":["Parties","Pressure from friends","Videos that make drinking look normal","Wanting to seem older"]},
        {"type":"step_list","title":"Safer responses","items":["Use a short no.","Stay near trusted people.","Leave if it feels unsafe.","Tell a trusted adult quickly."]},
        {"type":"reflection_prompt","value":"What would make it easier for you to say no if a situation felt wrong?"}
      ]
    }'::jsonb,
    'You do not need a perfect speech to make a safe choice. Clear, short responses usually work best.',
    'Refresh 13-14 alcohol safety lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_13_14"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000106',
    '60000000-0000-0000-0000-000000000106',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Sleep protects performance and recovery"},
        {"type":"text","value":"Sleep is not spare time. It supports memory, concentration, decision-making, and mood. Late nights often make even simple days feel harder."},
        {"type":"bullet_list","title":"Common disruptors","items":["Phones in bed","Studying too late","Caffeine to push through","Irregular sleep timing"]},
        {"type":"step_list","title":"Use a recovery routine","items":["Plan work earlier when possible.","Reduce screen use before bed.","Keep bedtime steadier.","Treat sleep as part of performance."]},
        {"type":"reflection_prompt","value":"If you protected one sleep habit first, which one would have the biggest effect?"}
      ]
    }'::jsonb,
    'Sleep and recovery improve when you treat rest like part of productivity, not the leftover piece after everything else.',
    'Refresh 15-18 sleep lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_15_18"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000107',
    '60000000-0000-0000-0000-000000000107',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Pressure gets easier to handle when it is named early"},
        {"type":"text","value":"Stress often builds from school, deadlines, expectations, friendships, or future decisions. When it stays high, sleep, mood, and concentration usually feel it too."},
        {"type":"bullet_list","title":"Signs it is piling up","items":["Feeling overwhelmed","Avoiding tasks","Trouble sleeping","Getting irritable faster"]},
        {"type":"step_list","title":"A steadier response","items":["Shrink the next task.","Protect short breaks.","Talk to someone sooner.","Drop the idea of doing everything perfectly."]},
        {"type":"reflection_prompt","value":"What kind of pressure tends to build up fastest for you right now?"}
      ]
    }'::jsonb,
    'Handling stress well is less about never feeling it and more about responding before it takes over the day.',
    'Refresh 15-18 stress lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_15_18"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000108',
    '60000000-0000-0000-0000-000000000108',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Boundaries matter when harm keeps repeating"},
        {"type":"text","value":"Bullying can look verbal, social, physical, or digital. What makes it serious is the repeated pattern of harm and the way it affects safety or confidence."},
        {"type":"bullet_list","title":"Helpful clues","items":["It is happening more than once","It feels targeted","It changes how safe you feel","It is hard to stop alone"]},
        {"type":"step_list","title":"Practical escalation","items":["Document the pattern if needed.","Tell a trusted adult or school staff member.","Protect distance from unsafe people.","Keep checking whether the situation is improving."]},
        {"type":"reflection_prompt","value":"If a repeated pattern kept going, what would make it easier to escalate it properly?"}
      ]
    }'::jsonb,
    'Repeated harm should be handled as a real safety issue, not something you are expected to silently absorb.',
    'Refresh 15-18 bullying lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_15_18"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000109',
    '60000000-0000-0000-0000-000000000109',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Gaming should fit around life, not replace it"},
        {"type":"text","value":"Gaming can be social and enjoyable, but balance starts slipping when sleep, study, responsibilities, or offline relationships are repeatedly pushed aside."},
        {"type":"bullet_list","title":"Signs of drift","items":["Late nights","Delayed work","Less offline time","Feeling irritated when stopped"]},
        {"type":"checklist","title":"Balance moves","items":["Finish key tasks first","Take real breaks","Protect sleep","Stay respectful and safe online"]},
        {"type":"reflection_prompt","value":"If gaming had to fit better around your goals, what would need to change first?"}
      ]
    }'::jsonb,
    'Healthy gaming is about balance, not guilt. The goal is to keep games enjoyable without letting them crowd out everything else.',
    'Refresh 15-18 healthy gaming lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_15_18"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000110',
    '60000000-0000-0000-0000-000000000110',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Thinking ahead is part of staying safe"},
        {"type":"text","value":"Alcohol can show up in more social settings as you get older. Safe decisions depend on thinking ahead before the pressure starts."},
        {"type":"bullet_list","title":"Situations to think about","items":["Parties","Friends saying just one drink","Riding with someone after drinking","Posting risky moments online"]},
        {"type":"step_list","title":"A safer plan","items":["Use a simple refusal line.","Plan how to get home safely.","Stay with trusted people.","Get help fast if a situation turns unsafe."]},
        {"type":"reflection_prompt","value":"What would your safest exit plan look like if a social situation started going wrong?"}
      ]
    }'::jsonb,
    'Safe alcohol decisions are easier when you plan the response before you are in the middle of the pressure.',
    'Refresh 15-18 alcohol safety lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_15_18"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000111',
    '60000000-0000-0000-0000-000000000111',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Sleep is a base layer for adult functioning"},
        {"type":"text","value":"As independence grows, no one else protects your bedtime for you. Sleep supports judgment, concentration, mood, and the ability to recover after demanding days."},
        {"type":"bullet_list","title":"Patterns worth noticing","items":["Using screens deep into the night","Relying on caffeine instead of sleep","Feeling tired even after busy weekends","Treating sleep as optional"]},
        {"type":"step_list","title":"Protect recovery earlier","items":["Set a realistic stop point at night.","Charge devices away from bed.","Plan work earlier where possible.","Treat rest like part of self-management."]},
        {"type":"reflection_prompt","value":"Where does your sleep routine usually break down first when life gets busy?"}
      ]
    }'::jsonb,
    'Protecting sleep is one of the clearest ways to protect performance, mood, and decision-making at the same time.',
    'Refresh 18-plus sleep lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_18_plus"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000112',
    '60000000-0000-0000-0000-000000000112',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Stress becomes more manageable when you stop carrying it alone"},
        {"type":"text","value":"Stress often comes from overlapping responsibilities, big decisions, exams, work, family pressure, or future uncertainty. It gets heavier when everything stays inside your head."},
        {"type":"bullet_list","title":"What high pressure can affect","items":["Concentration","Sleep","Mood","Physical tension","Relationships"]},
        {"type":"step_list","title":"A practical pressure plan","items":["Name the pressure clearly.","Lower the next step size.","Protect one reset window.","Use support before overload becomes the norm."]},
        {"type":"reflection_prompt","value":"What kind of pressure is most likely to build quietly in the background for you?"}
      ]
    }'::jsonb,
    'Stress under pressure is easier to manage when you make it visible, shrink it, and involve support earlier.',
    'Refresh 18-plus stress lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_18_plus"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000113',
    '60000000-0000-0000-0000-000000000113',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Repeated harm should not be normalized"},
        {"type":"text","value":"Bullying and repeated intimidation can still happen in later teen years and early adulthood, including online, in teams, or in work-like settings. The repeated pattern matters."},
        {"type":"bullet_list","title":"Useful questions","items":["Is it repeated?","Is it targeted?","Is it changing how safe I feel?","Do I need to document it?"]},
        {"type":"step_list","title":"Protective actions","items":["Keep records where needed.","Loop in school or another adult support path.","Avoid facing repeated harm alone.","Treat safety as the priority."]},
        {"type":"reflection_prompt","value":"If something crossed the line from conflict into repeated harm, what would help you act sooner?"}
      ]
    }'::jsonb,
    'Boundaries become stronger when you stop minimizing repeated harm and start treating it as something that deserves action.',
    'Refresh 18-plus bullying lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_18_plus"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000114',
    '60000000-0000-0000-0000-000000000114',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Digital habits shape more than screen time"},
        {"type":"text","value":"Gaming can be a healthy hobby, but it becomes costly when it begins to take priority over goals, sleep, relationships, or basic self-care."},
        {"type":"bullet_list","title":"Balance questions","items":["Does gaming fit around responsibilities?","Am I sleeping enough?","Do I still make time for offline life?","Am I using gaming as my only escape?"]},
        {"type":"checklist","title":"Healthier guardrails","items":["Set a stop point","Protect bedtime","Finish key work first","Keep one offline recovery habit active"]},
        {"type":"reflection_prompt","value":"If you wanted gaming to support your week rather than run it, what boundary would matter most?"}
      ]
    }'::jsonb,
    'Healthy gaming is less about restriction and more about making sure the rest of life still has room to breathe.',
    'Refresh 18-plus healthy gaming lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_18_plus"}'::jsonb
  ),
  (
    '61000000-0000-0000-0000-000000000115',
    '60000000-0000-0000-0000-000000000115',
    1,
    'published',
    '{
      "blocks": [
        {"type":"heading","value":"Independence also means planning for safety"},
        {"type":"text","value":"Alcohol can affect judgment, memory, coordination, and decision-making. Safer choices usually start before the event, not in the middle of it."},
        {"type":"bullet_list","title":"High-risk situations","items":["Driving after drinking","Riding with someone impaired","Pressure to keep up","Using alcohol to cope with stress"]},
        {"type":"step_list","title":"Build the safer response first","items":["Decide your line before the situation.","Protect your way home.","Stay near trusted people.","Get help quickly if the situation shifts."]},
        {"type":"reflection_prompt","value":"What is the one part of your safety plan you would want ready before a high-pressure social event?"}
      ]
    }'::jsonb,
    'Safer alcohol decisions come from planning, not improvising under pressure.',
    'Refresh 18-plus alcohol safety lane',
    'BAHA Demo Reviewer',
    now(),
    now(),
    '{"demo": true, "lane_group": "age_18_plus"}'::jsonb
  )
on conflict (id) do update
set version_status = excluded.version_status,
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
  ('61000000-0000-0000-0000-000000000101', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000102', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000103', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000104', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000105', 'student', 'android', '13_14', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000106', 'student', 'android', '15_18', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000107', 'student', 'android', '15_18', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000108', 'student', 'android', '15_18', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000109', 'student', 'android', '15_18', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000110', 'student', 'android', '15_18', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000111', 'student', 'android', '18_plus', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000112', 'student', 'android', '18_plus', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000113', 'student', 'android', '18_plus', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000114', 'student', 'android', '18_plus', 'active', now(), '{"demo": true}'::jsonb),
  ('61000000-0000-0000-0000-000000000115', 'student', 'android', '18_plus', 'active', now(), '{"demo": true}'::jsonb)
on conflict (content_version_id, audience_app, platform, age_cohort) do update
set activation_status = excluded.activation_status,
    effective_from = excluded.effective_from,
    metadata = excluded.metadata,
    updated_at = now();

insert into learning_modules (
  id, content_item_id, module_code, role_track, theme, age_cohort, estimated_minutes, sort_order, active, metadata
)
values
  ('62000000-0000-0000-0000-000000000101', '60000000-0000-0000-0000-000000000101', 'STU-1314-SLEEP-001', 'student', 'Sleep', '13_14', 7, 1, true, '{"demo": true, "lane_group": "age_13_14"}'::jsonb),
  ('62000000-0000-0000-0000-000000000102', '60000000-0000-0000-0000-000000000102', 'STU-1314-STRESS-001', 'student', 'Stress', '13_14', 7, 1, true, '{"demo": true, "lane_group": "age_13_14"}'::jsonb),
  ('62000000-0000-0000-0000-000000000103', '60000000-0000-0000-0000-000000000103', 'STU-1314-BULLY-001', 'student', 'Bullying', '13_14', 7, 1, true, '{"demo": true, "lane_group": "age_13_14"}'::jsonb),
  ('62000000-0000-0000-0000-000000000104', '60000000-0000-0000-0000-000000000104', 'STU-1314-GAME-001', 'student', 'Healthy Gaming', '13_14', 7, 1, true, '{"demo": true, "lane_group": "age_13_14"}'::jsonb),
  ('62000000-0000-0000-0000-000000000105', '60000000-0000-0000-0000-000000000105', 'STU-1314-ALC-001', 'student', 'Alcohol Safety', '13_14', 7, 1, true, '{"demo": true, "lane_group": "age_13_14"}'::jsonb),
  ('62000000-0000-0000-0000-000000000106', '60000000-0000-0000-0000-000000000106', 'STU-1518-SLEEP-001', 'student', 'Sleep', '15_18', 8, 1, true, '{"demo": true, "lane_group": "age_15_18"}'::jsonb),
  ('62000000-0000-0000-0000-000000000107', '60000000-0000-0000-0000-000000000107', 'STU-1518-STRESS-001', 'student', 'Stress', '15_18', 8, 1, true, '{"demo": true, "lane_group": "age_15_18"}'::jsonb),
  ('62000000-0000-0000-0000-000000000108', '60000000-0000-0000-0000-000000000108', 'STU-1518-BULLY-001', 'student', 'Bullying', '15_18', 8, 1, true, '{"demo": true, "lane_group": "age_15_18"}'::jsonb),
  ('62000000-0000-0000-0000-000000000109', '60000000-0000-0000-0000-000000000109', 'STU-1518-GAME-001', 'student', 'Healthy Gaming', '15_18', 8, 1, true, '{"demo": true, "lane_group": "age_15_18"}'::jsonb),
  ('62000000-0000-0000-0000-000000000110', '60000000-0000-0000-0000-000000000110', 'STU-1518-ALC-001', 'student', 'Alcohol Safety', '15_18', 8, 1, true, '{"demo": true, "lane_group": "age_15_18"}'::jsonb),
  ('62000000-0000-0000-0000-000000000111', '60000000-0000-0000-0000-000000000111', 'STU-18P-SLEEP-001', 'student', 'Sleep', '18_plus', 8, 1, true, '{"demo": true, "lane_group": "age_18_plus"}'::jsonb),
  ('62000000-0000-0000-0000-000000000112', '60000000-0000-0000-0000-000000000112', 'STU-18P-STRESS-001', 'student', 'Stress', '18_plus', 8, 1, true, '{"demo": true, "lane_group": "age_18_plus"}'::jsonb),
  ('62000000-0000-0000-0000-000000000113', '60000000-0000-0000-0000-000000000113', 'STU-18P-BULLY-001', 'student', 'Bullying', '18_plus', 8, 1, true, '{"demo": true, "lane_group": "age_18_plus"}'::jsonb),
  ('62000000-0000-0000-0000-000000000114', '60000000-0000-0000-0000-000000000114', 'STU-18P-GAME-001', 'student', 'Healthy Gaming', '18_plus', 8, 1, true, '{"demo": true, "lane_group": "age_18_plus"}'::jsonb),
  ('62000000-0000-0000-0000-000000000115', '60000000-0000-0000-0000-000000000115', 'STU-18P-ALC-001', 'student', 'Alcohol Safety', '18_plus', 8, 1, true, '{"demo": true, "lane_group": "age_18_plus"}'::jsonb)
on conflict (id) do update
set content_item_id = excluded.content_item_id,
    module_code = excluded.module_code,
    role_track = excluded.role_track,
    theme = excluded.theme,
    age_cohort = excluded.age_cohort,
    estimated_minutes = excluded.estimated_minutes,
    sort_order = excluded.sort_order,
    active = excluded.active,
    metadata = excluded.metadata,
    updated_at = now();
