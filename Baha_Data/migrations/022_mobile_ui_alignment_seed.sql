insert into users (id, email, display_name, status, preferred_language, metadata)
values
  (
    '20000000-0000-0000-0000-000000000006',
    'pending.teacher@baha.local',
    'Nisha Pending Teacher',
    'pending',
    'en',
    '{"demo": true, "seed_purpose": "approval_queue"}'::jsonb
  ),
  (
    '20000000-0000-0000-0000-000000000007',
    'pending.counselor@baha.local',
    'Rahul Pending Counselor',
    'pending',
    'en',
    '{"demo": true, "seed_purpose": "approval_queue"}'::jsonb
  )
on conflict (id) do nothing;

insert into approval_requests (
  user_id,
  requested_role,
  school_id,
  request_type,
  status,
  requested_metadata
)
values
  (
    '20000000-0000-0000-0000-000000000006',
    'teacher',
    '10000000-0000-0000-0000-000000000001',
    'account_activation',
    'pending',
    '{"demo": true, "staff_code": "TCH-PENDING-01", "note": "Demo pending teacher approval"}'::jsonb
  ),
  (
    '20000000-0000-0000-0000-000000000007',
    'counselor',
    '10000000-0000-0000-0000-000000000001',
    'account_activation',
    'pending',
    '{"demo": true, "staff_code": "COU-PENDING-01", "note": "Demo pending counselor approval"}'::jsonb
  )
on conflict (user_id, requested_role, request_type)
where status = 'pending'
do update set
  school_id = excluded.school_id,
  requested_metadata = excluded.requested_metadata,
  requested_at = now(),
  updated_at = now();

update baha_pilot_dashboard_metrics
set
  metrics = jsonb_build_object(
    'students_active', 1,
    'guardians_active', 1,
    'teachers_active', 1,
    'open_cases', 1,
    'open_help_requests', 1,
    'unassigned_signals', 1
  ),
  generation_version = 'demo-v2',
  generated_at = now(),
  updated_at = now()
where metric_scope = 'global'
  and scope_key = 'all';

insert into baha_pilot_dashboard_metrics (
  metric_scope,
  scope_key,
  period_start,
  period_end,
  metrics,
  generation_version,
  generated_at
)
values
  (
    'school',
    '10000000-0000-0000-0000-000000000001',
    current_date - 7,
    current_date - 1,
    '{"students_active":1,"checkin_participation_rate":1.0,"open_cases":1,"open_help_requests":1,"unassigned_signals":1}'::jsonb,
    'demo-v2',
    now()
  )
on conflict (metric_scope, scope_key, period_start, period_end) do update
set
  metrics = excluded.metrics,
  generation_version = excluded.generation_version,
  generated_at = excluded.generated_at,
  updated_at = now();
