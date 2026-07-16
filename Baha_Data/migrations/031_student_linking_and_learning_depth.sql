create temp table module_seed (
  age_cohort text,
  lane_group text,
  theme text,
  topic text,
  subtopic text,
  module_code text,
  slug text,
  title text,
  summary text,
  sort_order integer,
  estimated_minutes integer,
  heading text,
  body_text text,
  bullet_title text,
  bullet_1 text,
  bullet_2 text,
  bullet_3 text,
  step_title text,
  step_1 text,
  step_2 text,
  reflection text
);

insert into module_seed (
  age_cohort,
  lane_group,
  theme,
  topic,
  subtopic,
  module_code,
  slug,
  title,
  summary,
  sort_order,
  estimated_minutes,
  heading,
  body_text,
  bullet_title,
  bullet_1,
  bullet_2,
  bullet_3,
  step_title,
  step_1,
  step_2,
  reflection
)
values
    ('13_14','age_13_14','Sleep','sleep_habits','wind_down','STU-1314-SLEEP-002','student-13-14-sleep-evening-wind-down','Evening Wind-Down','A short module about building one bedtime sequence that actually feels doable on school nights.',2,6,'A short wind-down works better than a perfect routine','You do not need a complicated system. A repeatable sequence helps your brain recognize that the day is ending and that sleep is allowed to happen.','What helps most','Keep the same general bedtime target.','Use one quiet step like stretching, music, or reading.','Make the routine easy enough to repeat even on busy days.','Try this tonight','Pick one wind-down habit you can repeat.','Move the start of the routine a little earlier than usual.','Which part of your evening is easiest to make more predictable?'),
    ('13_14','age_13_14','Sleep','sleep_habits','screens','STU-1314-SLEEP-003','student-13-14-sleep-screens-and-sleep','Screens and Sleep','A short module about how phones, gaming, and scrolling can quietly delay real rest.',3,6,'Screens often affect sleep more than we notice','Bright light, excitement, and endless content can keep your body alert long after you meant to stop.','Notice these clues','You keep saying “just a few more minutes.”','You feel tired but keep scrolling or gaming.','Morning energy drops after late screen time.','Quick reset','Choose one screen-off point before bed.','Put the device far enough away that it is not the last thing you check.','What kind of screen time keeps you awake the longest?'),
    ('13_14','age_13_14','Stress','stress_support','early_signs','STU-1314-STRESS-002','student-13-14-stress-catch-it-early','Catch Stress Early','A short module about noticing stress in your body and thoughts before it builds into overload.',2,6,'Stress gets easier to handle when you spot it early','Many people only notice stress once they are already snappy, frozen, tired, or overwhelmed. Earlier clues help you step in sooner.','Early clues can be','A tight chest or stomach.','Irritation over small things.','Feeling like you want to avoid everything.','Try this next','Name the first stress clue you notice.','Use one calming step before the stress gets bigger.','What is usually your earliest clue that pressure is building?'),
    ('13_14','age_13_14','Stress','stress_support','reset','STU-1314-STRESS-003','student-13-14-stress-reset-after-a-hard-day','Reset After a Hard Day','A short module about recovering after school pressure instead of carrying the whole day into the evening.',3,6,'Recovery matters after stressful days','You do not need to pretend the day was easy. A short reset can stop one difficult day from spilling into the rest of your night.','A good reset can include','A short walk or stretch.','A calmer conversation with someone you trust.','Doing one small next step instead of everything at once.','Try this next','Pick one calming step for after school.','Then choose only one practical task to restart with.','What helps you feel a little more steady after a rough day?'),
    ('13_14','age_13_14','Bullying','peer_safety','pattern','STU-1314-BULLY-002','student-13-14-bullying-spot-the-pattern','Spot the Pattern','A short module about telling the difference between one conflict and a repeated pattern of harm.',2,6,'Repeated harm should be treated seriously','When something keeps happening, feels targeted, or starts affecting your safety or confidence, it is no longer “just drama.”','Pattern clues can be','It keeps happening again.','It feels aimed at you.','You start changing behavior to avoid it.','Try this next','Notice what is repeating.','Tell one trusted adult what keeps happening.','If it repeated next week, who would be the best adult to tell first?'),
    ('13_14','age_13_14','Bullying','peer_safety','response','STU-1314-BULLY-003','student-13-14-bullying-build-a-safe-response','Build a Safe Response','A short module about moving toward safe people and adults instead of carrying the problem alone.',3,6,'Safety comes before proving anything','You do not need the perfect response. The most useful next move is the one that gets you safer and more supported.','Safe moves can be','Move toward adults or supportive friends.','Keep screenshots if it is online.','Repeat the concern until an adult responds.','Try this next','Pick the adult support path you would use.','Save anything you might need to show later.','What would make it easier to ask for help sooner?'),
    ('13_14','age_13_14','Healthy Gaming','digital_balance','sleep','STU-1314-GAME-002','student-13-14-gaming-protect-sleep','Protect Sleep While Gaming','A short module about keeping gaming fun without letting it steal sleep and next-day energy.',2,6,'Late gaming can quietly drain the next day','The hardest part is not usually one game. It is how late stopping turns into less rest, worse focus, and more conflict tomorrow.','Watch for these clues','You keep pushing bedtime later.','Morning energy drops.','You feel upset when it is time to stop.','Try this next','Choose a finish time before you start.','Protect sleep even on fun nights.','What makes it hardest to stop gaming on time?'),
    ('13_14','age_13_14','Healthy Gaming','digital_balance','routine','STU-1314-GAME-003','student-13-14-gaming-keep-play-in-balance','Keep Play in Balance','A short module about keeping gaming inside a balanced day instead of letting it crowd everything else out.',3,6,'Balance matters more than perfection','Gaming fits best when school, rest, movement, and offline time still have room too.','Good balance can look like','Finish key tasks first.','Take breaks between longer sessions.','Keep some offline time in the day.','Try this next','Choose one part of life you want to protect better.','Set one gaming habit around that priority.','What part of life gets crowded out first when gaming grows too much?'),
    ('13_14','age_13_14','Alcohol Safety','substance_safety','pressure','STU-1314-ALC-002','student-13-14-alcohol-handle-pressure-better','Handle Pressure Better','A short module about staying steady when someone pushes you toward risky choices.',2,6,'Pressure works fast when you feel put on the spot','A short answer and a safe exit plan make it easier to hold your ground in awkward moments.','Pressure can sound like','Come on, everyone is doing it.','Do not be boring.','No one will know.','Try this next','Keep one short no ready.','Move toward a safer person or place if needed.','What kind of pressure would feel hardest to handle calmly?'),
    ('13_14','age_13_14','Alcohol Safety','substance_safety','safe_exit','STU-1314-ALC-003','student-13-14-alcohol-plan-a-safe-exit','Plan a Safe Exit','A short module about leaving unsafe situations early instead of waiting for them to get worse.',3,6,'Leaving early is a strength move','If something feels wrong, you do not need to stay polite or prove anything. Safety matters more.','A safe exit can include','Text or call a trusted adult.','Stay close to safe people.','Leave the situation before it escalates.','Try this next','Choose who you would contact first.','Decide what your first exit move would be.','What would help you leave sooner if something felt off?'),
    ('15_18','age_15_18','Sleep','sleep_habits','recovery','STU-1518-SLEEP-002','student-15-18-sleep-recovery-habits','Recovery Habits That Last','A short module about building sleep habits that support focus, mood, and school performance over time.',2,7,'Recovery needs consistency more than motivation','Most sleep routines fail when they are too ambitious. A few habits that you can repeat matter more than an ideal plan you never use.','What steady habits look like','A realistic bedtime window.','A short wind-down that you actually use.','Protecting mornings from total chaos.','Try this next','Choose one habit you can keep even on busy days.','Repeat it long enough to notice the effect.','Which recovery habit would be easiest to keep this week?'),
    ('15_18','age_15_18','Sleep','sleep_habits','screens','STU-1518-SLEEP-003','student-15-18-sleep-protect-from-screens','Protect Sleep From Screens','A short module about late-night phone use, gaming, and media loops that make sleep harder to protect.',3,7,'The problem is often the last hour, not the whole day','A lot of sleep disruption happens because the final hour stays loud, bright, or mentally switched on.','Watch for these patterns','You feel tired but keep scrolling anyway.','You tell yourself you will stop after one more thing.','Your brain stays active after the screen is gone.','Try this next','Create one no-screen point before bed.','Replace it with one lower-stimulation habit.','What kind of screen use keeps your brain the most switched on at night?'),
    ('15_18','age_15_18','Stress','stress_support','overload','STU-1518-STRESS-002','student-15-18-stress-catch-overload','Catch Overload Sooner','A short module about noticing when normal pressure is starting to turn into overload.',2,7,'Overload usually builds before it crashes','When stress starts stacking across school, life, and expectations, the first signs are often reduced focus, irritability, avoidance, or exhaustion.','Early overload can look like','You stop starting important tasks.','Small setbacks feel huge.','Your body stays tense or tired.','Try this next','Name the strongest current pressure.','Shrink the next step until it feels possible.','What sign tells you pressure is becoming too much instead of just busy?'),
    ('15_18','age_15_18','Stress','stress_support','recovery','STU-1518-STRESS-003','student-15-18-stress-recover-after-pressure','Recover After Pressure','A short module about resetting after deadlines, conflict, or heavy days instead of carrying them forward unchanged.',3,7,'Recovery is part of performance too','If you never come down from pressure, the next demand feels heavier than it should. Short recovery helps you think more clearly again.','A useful reset can include','A pause before jumping into the next task.','A calmer check-in with someone you trust.','One small plan for tomorrow instead of spiraling tonight.','Try this next','Decide how you will reset after today.','Keep the first recovery step simple and concrete.','What helps you move from pressure back into steadier thinking?'),
    ('15_18','age_15_18','Bullying','peer_safety','documentation','STU-1518-BULLY-002','student-15-18-bullying-document-and-escalate','Document and Escalate','A short module about keeping clear notes and getting adults involved when harm keeps repeating.',2,7,'Documentation makes it easier to get real help','When repeated harm is brushed off, clear details can help an adult understand the pattern faster and act more effectively.','Useful details include','What happened.','Where and when it happened.','Whether there is proof like screenshots.','Try this next','Keep only the facts that show the pattern.','Share them with a trusted adult sooner, not later.','If you had to explain the pattern clearly, what facts matter most?'),
    ('15_18','age_15_18','Bullying','peer_safety','boundaries','STU-1518-BULLY-003','student-15-18-bullying-protect-your-space','Protect Your Space','A short module about stepping back from harmful spaces and building safer boundaries around yourself.',3,7,'Boundaries can reduce harm while support catches up','Sometimes the safest move is to limit access, block contact, move toward safer groups, and stop treating the situation as something you must absorb.','Protective boundaries can be','Blocking or muting harmful contact.','Avoiding unsafe situations when possible.','Staying closer to supportive people.','Try this next','Choose one boundary that would lower harm right now.','Tell a trusted adult how the pattern is affecting you.','What boundary would make the biggest difference if you used it this week?'),
    ('15_18','age_15_18','Healthy Gaming','digital_balance','boundaries','STU-1518-GAME-002','student-15-18-gaming-boundaries-that-work','Boundaries That Work','A short module about using realistic limits instead of vague promises when gaming starts stretching too far.',2,7,'Boundaries work best when they are specific','It is easier to hold a real limit like a stop time or task-first rule than a general goal to “just play less.”','Useful boundaries can be','Finish priorities before longer sessions.','Choose an end point before you begin.','Keep late-night gaming from taking over sleep.','Try this next','Pick one boundary you can actually follow.','Test it for a few days before judging it.','Which boundary would improve balance without making gaming feel like a battle?'),
    ('15_18','age_15_18','Healthy Gaming','digital_balance','priorities','STU-1518-GAME-003','student-15-18-gaming-protect-priorities','Protect Priorities','A short module about keeping gaming in the picture while still protecting school, rest, and real-life responsibilities.',3,7,'Balance means your priorities stay visible','Gaming becomes a problem when it quietly pushes aside what matters most to you over time.','Priorities worth protecting','Sleep and energy.','School or work responsibilities.','Offline relationships and downtime.','Try this next','Pick the priority most at risk right now.','Adjust one gaming habit around that priority.','What priority needs more protection from gaming this week?'),
    ('15_18','age_15_18','Alcohol Safety','substance_safety','read_situation','STU-1518-ALC-002','student-15-18-alcohol-read-the-situation','Read the Situation','A short module about spotting social situations that are starting to become unsafe or harder to control.',2,7,'Risk builds before something obviously goes wrong','A lot of safer choices happen early, when you notice who is around, what pressure is rising, and whether the environment still feels steady.','Useful things to notice','Who feels safe to stay near.','Whether pressure is rising.','Whether judgment is starting to slip around you.','Try this next','Scan the situation earlier than usual.','Move closer to safer people before you need to.','What part of a social situation would tell you it is time to get more careful?'),
    ('15_18','age_15_18','Alcohol Safety','substance_safety','exit_plan','STU-1518-ALC-003','student-15-18-alcohol-safer-exit-plan','Safer Exit Plan','A short module about planning your exit before a situation gets harder to manage.',3,7,'Exit plans are easier before pressure peaks','Thinking ahead removes decision pressure later. You are more likely to leave safely if the plan is already simple.','A safer exit plan can include','Knowing who to call.','Choosing how you will leave.','Staying with safer people while you do it.','Try this next','Decide what your exit trigger would be.','Choose the first person you would contact.','What would your safest exit plan look like in real life?'),
    ('18_plus','age_18_plus','Sleep','sleep_habits','recovery','STU-18P-SLEEP-002','student-18-plus-sleep-real-recovery-routine','Build a Real Recovery Routine','A short module about building recovery habits that hold up around study, work, and independence.',2,8,'Recovery routines need to match real life','Adult schedules are messy. Good sleep routines work because they are realistic enough to survive busy weeks, not because they are perfect.','A workable routine can include','A repeatable bedtime window.','A calmer final hour.','Small habits that lower stimulation before sleep.','Try this next','Choose one recovery habit that fits your real week.','Keep it simple enough to repeat consistently.','What habit would most improve recovery without feeling unrealistic?'),
    ('18_plus','age_18_plus','Sleep','sleep_habits','work_and_screens','STU-18P-SLEEP-003','student-18-plus-sleep-work-and-screens','Protect Sleep Around Work and Screens','A short module about the way work stress, studying, and phone habits can all push sleep later than intended.',3,8,'Late stimulation can come from stress as much as screens','Sometimes it is not only the device. It is also work, worry, and unfinished thinking that keep your system switched on.','What tends to delay sleep','Late task spillover.','Phone use that keeps your mind active.','Trying to wind down while still mentally working.','Try this next','Set one stopping point for work or study.','Create one lower-stimulation transition before bed.','What usually keeps your brain working when you want to be sleeping?'),
    ('18_plus','age_18_plus','Stress','stress_support','burnout_signals','STU-18P-STRESS-002','student-18-plus-stress-notice-burnout-signals','Notice Burnout Signals','A short module about catching repeated strain before it turns into a longer pattern of exhaustion and disengagement.',2,8,'Burnout signals are easier to act on early','When stress stays high for too long, it can shift from pressure into numbness, exhaustion, poor concentration, and emotional flattening.','Signals to watch','You feel drained even after stopping.','Tasks feel heavier than usual.','You start caring less because you are overloaded.','Try this next','Notice what is repeating, not just what happened today.','Reduce one avoidable pressure where you can.','Which sign tells you stress is becoming a sustained pattern instead of a rough day?'),
    ('18_plus','age_18_plus','Stress','stress_support','reset','STU-18P-STRESS-003','student-18-plus-stress-reset-after-high-pressure-days','Reset After High-Pressure Days','A short module about creating a deliberate reset after demanding days so stress does not become your permanent baseline.',3,8,'Resetting helps you avoid carrying pressure forward unchanged','A short decompression step makes it easier to recover judgment, perspective, and emotional range after intense days.','A useful reset might include','A short walk or movement break.','Turning down stimulation for a while.','Separating today’s stress from tomorrow’s plan.','Try this next','Choose one way to close out the day more intentionally.','Write down only one next step for tomorrow.','What helps you return to steadier thinking after a high-pressure day?'),
    ('18_plus','age_18_plus','Bullying','peer_safety','adult_boundaries','STU-18P-BULLY-002','student-18-plus-bullying-boundaries-in-adult-spaces','Boundaries in Adult Spaces','A short module about handling repeated harm in more independent social, academic, or workplace environments.',2,8,'Adult spaces still require safety boundaries','Independence does not mean tolerating repeated disrespect, exclusion, or intimidation without support.','Useful boundary moves','Reduce contact where possible.','Keep a factual record of repeated behavior.','Move toward safer people and channels.','Try this next','Choose one boundary that lowers exposure.','Decide who you would escalate the pattern to if needed.','What boundary would make you feel more protected right now?'),
    ('18_plus','age_18_plus','Bullying','peer_safety','escalation','STU-18P-BULLY-003','student-18-plus-bullying-escalate-without-isolating','Escalate Without Isolating','A short module about asking for help early enough that you are not carrying the whole pattern alone.',3,8,'Escalation is stronger when it is calm and specific','You do not need to wait until harm becomes extreme before bringing in a supervisor, tutor, counselor, or other trusted adult.','A stronger escalation path includes','Keeping the facts clear.','Naming the impact on safety or functioning.','Using formal support channels where needed.','Try this next','Choose the person or channel you would use first.','Keep the focus on the repeated pattern and its impact.','What support channel feels most realistic if this keeps happening?'),
    ('18_plus','age_18_plus','Healthy Gaming','digital_balance','sustainable','STU-18P-GAME-002','student-18-plus-gaming-keep-it-sustainable','Keep Gaming Sustainable','A short module about keeping gaming enjoyable without letting it quietly erode recovery, focus, and responsibility.',2,8,'Sustainable gaming still leaves room for the rest of life','The goal is not less enjoyment. It is making sure enjoyment does not keep taking from sleep, work, or relationships.','Check whether gaming is affecting','Recovery and sleep.','Work, study, or responsibilities.','Your ability to disengage when you mean to.','Try this next','Choose one limit that protects your most important priority.','Notice whether gaming feels easier to enjoy when balance improves.','What would make gaming feel more sustainable in your current routine?'),
    ('18_plus','age_18_plus','Healthy Gaming','digital_balance','rebalance','STU-18P-GAME-003','student-18-plus-gaming-rebalance-when-it-crowds-life','Rebalance When It Starts Crowding Life','A short module about recognizing when gaming is taking up too much space and making a practical adjustment.',3,8,'Rebalancing early is easier than waiting for a crash','The longer a pattern crowds out sleep, work, or relationships, the harder it feels to correct. Earlier shifts are usually smaller and more realistic.','Signs rebalancing may be needed','You keep sacrificing sleep.','Responsibilities keep slipping.','You feel stuck even when you want to stop.','Try this next','Name the part of life losing space.','Adjust one gaming habit around that priority.','What part of life would benefit first from a small gaming reset?'),
    ('18_plus','age_18_plus','Alcohol Safety','substance_safety','social_calls','STU-18P-ALC-002','student-18-plus-alcohol-make-safer-social-calls','Make Safer Social Calls','A short module about making clearer decisions in social settings where alcohol is present.',2,8,'Safer decisions start before the night drifts','Knowing your limits, your people, and your exit options early makes it easier to stay in control later.','Useful checks include','Who do you trust here?','What is your way home?','What would tell you it is time to leave?','Try this next','Decide one safety limit before you go.','Keep your exit option simple and realistic.','What helps you stay clearer in social settings that might become risky?'),
    ('18_plus','age_18_plus','Alcohol Safety','substance_safety','exit_before_needed','STU-18P-ALC-003','student-18-plus-alcohol-plan-your-exit-before-you-need-it','Plan Your Exit Before You Need It','A short module about leaving unsafe situations early instead of relying on judgment that may get worse later.',3,8,'Exit planning protects you when pressure rises','Leaving is easier when the decision has already been simplified. You do not need to wait for a perfect reason if the situation no longer feels safe.','A safer exit plan can include','A message you can send quickly.','A person you can stay close to.','A simple rule for when you leave.','Try this next','Choose your first exit trigger.','Choose who you would contact if needed.','What would make it easier for you to leave earlier instead of later?');

create temp table card_seed (
  age_cohort text,
  lane_group text,
  theme text,
  topic text,
  subtopic text,
  slug text,
  title text,
  summary text,
  body_text text
);

insert into card_seed (
  age_cohort,
  lane_group,
  theme,
  topic,
  subtopic,
  slug,
  title,
  summary,
  body_text
)
values
    ('13_14','age_13_14','Sleep','sleep_habits','quick_support','student-13-14-sleep-quick-support','Tonight''s sleep reset','A quick support card for protecting sleep on a busy night.','If tonight already feels messy, protect one thing only: a steady bedtime target or an earlier screen-off point.'),
    ('13_14','age_13_14','Stress','stress_support','quick_support','student-13-14-stress-quick-support','Fast calm reset','A quick support card for bringing pressure down a little faster.','Try this: name the pressure, slow your breathing once, and pick only one next step instead of five.'),
    ('13_14','age_13_14','Bullying','peer_safety','quick_support','student-13-14-bullying-quick-support','Get safe support fast','A quick support card for repeated harm or unsafe peer situations.','If something keeps happening, move toward safe adults and tell the pattern clearly. You do not need to carry it alone.'),
    ('13_14','age_13_14','Healthy Gaming','digital_balance','quick_support','student-13-14-gaming-quick-support','Quick gaming balance check','A quick support card for keeping play from taking over the rest of the day.','Before you start, decide what still needs protecting tonight: sleep, homework, or time away from the screen.'),
    ('13_14','age_13_14','Alcohol Safety','substance_safety','quick_support','student-13-14-alcohol-quick-support','Safe exit reminder','A quick support card for moments that feel pressuring or unsafe.','A short no and a fast move toward safer people is enough. Safety matters more than fitting in.'),
    ('15_18','age_15_18','Sleep','sleep_habits','quick_support','student-15-18-sleep-quick-support','Protect tonight''s recovery','A quick support card for saving recovery when the day ran late.','If the evening slipped, cut one layer of stimulation now so your brain has a better chance to settle.'),
    ('15_18','age_15_18','Stress','stress_support','quick_support','student-15-18-stress-quick-support','Pressure reset','A quick support card for breaking stress into something more manageable.','Ask yourself what matters most right now, then shrink the next step until it feels possible again.'),
    ('15_18','age_15_18','Bullying','peer_safety','quick_support','student-15-18-bullying-quick-support','Use facts, then get help','A quick support card for repeated harm online or in person.','Keep the facts clear, save proof if needed, and involve a trusted adult before the pattern grows.'),
    ('15_18','age_15_18','Healthy Gaming','digital_balance','quick_support','student-15-18-gaming-quick-support','Boundary check','A quick support card for holding one gaming limit that actually protects balance.','Pick one clear stop point or task-first rule before you begin. Specific limits are easier to follow than vague promises.'),
    ('15_18','age_15_18','Alcohol Safety','substance_safety','quick_support','student-15-18-alcohol-quick-support','Read the room early','A quick support card for social settings that may become risky.','Notice who feels safe, where your exit is, and what would tell you to leave sooner instead of later.'),
    ('18_plus','age_18_plus','Sleep','sleep_habits','quick_support','student-18-plus-sleep-quick-support','Recovery check','A quick support card for protecting recovery around work, study, and screens.','Ask what is keeping your system switched on right now, then remove one layer of stimulation before bed.'),
    ('18_plus','age_18_plus','Stress','stress_support','quick_support','student-18-plus-stress-quick-support','Catch the pattern','A quick support card for noticing when stress is becoming your baseline.','If the same strain has repeated for days, treat the pattern seriously and lower one avoidable pressure tonight.'),
    ('18_plus','age_18_plus','Bullying','peer_safety','quick_support','student-18-plus-bullying-quick-support','Boundary first','A quick support card for repeated harm in adult spaces.','Reduce exposure where you can, keep the facts clear, and use a real support channel before the situation isolates you further.'),
    ('18_plus','age_18_plus','Healthy Gaming','digital_balance','quick_support','student-18-plus-gaming-quick-support','Sustainability check','A quick support card for keeping gaming inside a sustainable routine.','If gaming is taking from recovery or responsibility, adjust one habit now before the pattern gets harder to unwind.'),
    ('18_plus','age_18_plus','Alcohol Safety','substance_safety','quick_support','student-18-plus-alcohol-quick-support','Exit early if needed','A quick support card for any setting where alcohol is making the situation feel less safe.','You do not need to wait for a dramatic reason. If the situation feels off, use your exit plan early.');

with all_content as (
  select
    slug,
    title,
    'learning_module'::text as content_type,
    'student'::text as audience_app,
    age_cohort,
    theme,
    topic,
    subtopic,
    summary,
    jsonb_build_object('demo', true, 'lane_group', lane_group, 'display_title', title) as metadata
  from module_seed
  union all
  select
    slug,
    title,
    'learning_card'::text as content_type,
    'student'::text as audience_app,
    age_cohort,
    theme,
    topic,
    subtopic,
    summary,
    jsonb_build_object('demo', true, 'lane_group', lane_group, 'lane_role', 'quick_support') as metadata
  from card_seed
)
insert into content_items (
  slug, title, content_type, audience_app, age_cohort, theme, topic, subtopic,
  language, risk_level, consent_sensitivity, lifecycle_status, review_status, source_kind,
  summary, metadata
)
select
  slug,
  title,
  content_type,
  audience_app,
  age_cohort,
  theme,
  topic,
  subtopic,
  'en',
  'none',
  'tier1',
  'active',
  'approved',
  'manual',
  summary,
  metadata
from all_content
on conflict (slug) do update
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

with module_versions as (
  select
    ci.id as content_item_id,
    m.slug,
    jsonb_build_object(
      'blocks',
      jsonb_build_array(
        jsonb_build_object('type','heading','value',m.heading),
        jsonb_build_object('type','text','value',m.body_text),
        jsonb_build_object('type','bullet_list','title',m.bullet_title,'items',jsonb_build_array(m.bullet_1, m.bullet_2, m.bullet_3)),
        jsonb_build_object('type','step_list','title',m.step_title,'items',jsonb_build_array(m.step_1, m.step_2)),
        jsonb_build_object('type','reflection_prompt','value',m.reflection)
      )
    ) as body,
    m.summary
  from module_seed m
  join content_items ci on ci.slug = m.slug
), card_versions as (
  select
    ci.id as content_item_id,
    c.slug,
    jsonb_build_object(
      'blocks',
      jsonb_build_array(
        jsonb_build_object('type','heading','value',c.title),
        jsonb_build_object('type','text','value',c.body_text)
      )
    ) as body,
    c.summary
  from card_seed c
  join content_items ci on ci.slug = c.slug
)
insert into content_versions (
  content_item_id, version_number, version_status, body, plain_text, changelog,
  reviewed_by, reviewed_at, effective_from, metadata
)
select
  content_item_id,
  1,
  'published',
  body,
  summary,
  'Add missing demo learning depth',
  'BAHA Demo Reviewer',
  now(),
  now(),
  jsonb_build_object('demo', true)
from (
  select * from module_versions
  union all
  select * from card_versions
) seeded_versions
on conflict (content_item_id, version_number) do update
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
  content_version_id,
  audience_app,
  platform,
  age_cohort,
  activation_status,
  effective_from,
  metadata
)
select
  cv.id,
  ci.audience_app,
  'android',
  ci.age_cohort,
  'active',
  now(),
  jsonb_build_object('demo', true)
from content_versions cv
join content_items ci on ci.id = cv.content_item_id
where cv.version_number = 1
  and ci.slug in (
    select slug from module_seed
    union all
    select slug from card_seed
  )
on conflict (content_version_id, audience_app, platform, age_cohort) do update
set
  activation_status = excluded.activation_status,
  effective_from = excluded.effective_from,
  metadata = excluded.metadata,
  updated_at = now();

insert into learning_modules (
  content_item_id,
  module_code,
  role_track,
  theme,
  age_cohort,
  estimated_minutes,
  sort_order,
  active,
  metadata
)
select
  ci.id,
  m.module_code,
  'student',
  m.theme,
  m.age_cohort,
  m.estimated_minutes,
  m.sort_order,
  true,
  jsonb_build_object('demo', true, 'lane_group', m.lane_group)
from module_seed m
join content_items ci on ci.slug = m.slug
on conflict (content_item_id) do update
set
  module_code = excluded.module_code,
  role_track = excluded.role_track,
  theme = excluded.theme,
  age_cohort = excluded.age_cohort,
  estimated_minutes = excluded.estimated_minutes,
  sort_order = excluded.sort_order,
  active = excluded.active,
  metadata = excluded.metadata,
  updated_at = now();
