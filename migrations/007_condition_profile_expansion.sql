insert into taxonomy (category, condition, topics) values
('Emotional', 'Emotional Regulation', array['emotion regulation', 'self regulation']),
('Academic', 'School Refusal', array['school refusal', 'attendance', 'avoidance']),
('High Risk', 'Suicide Prevention', array['suicide prevention', 'suicidal ideation', 'crisis'])
on conflict (condition) do update set
  category = excluded.category,
  topics = excluded.topics;

insert into condition_profile_targets (condition) values
('Emotional Regulation'),
('School Refusal'),
('Suicide Prevention')
on conflict (condition) do nothing;

update condition_profile_targets
set profile_exists = exists (
  select 1
  from condition_profiles p
  where p.condition = condition_profile_targets.condition
);
