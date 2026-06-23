create table if not exists help_requests (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid references student_profiles(id) on delete set null,
  requested_by_user_id uuid not null references users(id) on delete cascade,
  requested_for_user_id uuid references users(id) on delete set null,
  request_channel text not null default 'student_app' check (
    request_channel in ('student_app', 'parent_app', 'teacher_app', 'counselor_app', 'chatbot', 'manual')
  ),
  category text not null check (
    category in ('emotional_support', 'academic_stress', 'peer_issue', 'family_issue', 'crisis', 'other')
  ),
  urgency text not null default 'standard' check (
    urgency in ('standard', 'priority', 'urgent', 'emergency')
  ),
  status text not null default 'open' check (
    status in ('open', 'acknowledged', 'in_progress', 'resolved', 'cancelled', 'escalated')
  ),
  summary text not null,
  details jsonb not null default '{}',
  visibility_scope text not null default 'private' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists pastoral_flags (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  teacher_profile_id uuid references teacher_profiles(id) on delete set null,
  class_id uuid references classes(id) on delete set null,
  flag_type text not null check (
    flag_type in ('attendance_change', 'mood_change', 'peer_issue', 'behavior_change', 'academic_stress', 'safeguarding', 'other')
  ),
  severity text not null default 'moderate' check (
    severity in ('low', 'moderate', 'high', 'emergency')
  ),
  status text not null default 'open' check (
    status in ('open', 'reviewed', 'closed', 'escalated')
  ),
  summary text not null,
  details jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists monitoring_signals (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  signal_type text not null check (
    signal_type in (
      'checkin_pattern',
      'chatbot_risk_phrase',
      'help_request',
      'teacher_flag',
      'game_behavior_signal',
      'manual_review',
      'privacy_override_trigger',
      'other'
    )
  ),
  signal_status text not null default 'new' check (
    signal_status in ('new', 'reviewing', 'dismissed', 'accepted', 'resolved', 'escalated')
  ),
  severity text not null default 'moderate' check (
    severity in ('low', 'moderate', 'high', 'emergency')
  ),
  confidence numeric(5,4),
  title text not null,
  signal_summary text,
  derived_facts jsonb not null default '{}',
  triggered_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by_user_id uuid references users(id) on delete set null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists signal_sources (
  id uuid primary key default gen_random_uuid(),
  monitoring_signal_id uuid not null references monitoring_signals(id) on delete cascade,
  source_type text not null check (
    source_type in (
      'checkin_response_set',
      'chat_session',
      'chat_message',
      'help_request',
      'pastoral_flag',
      'game_behavior_signal',
      'override_event',
      'manual_note'
    )
  ),
  source_record_id uuid not null,
  contribution_weight numeric(6,3),
  summary text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists escalation_cases (
  id uuid primary key default gen_random_uuid(),
  case_key text not null unique,
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  primary_signal_id uuid references monitoring_signals(id) on delete set null,
  opened_by_user_id uuid references users(id) on delete set null,
  case_type text not null check (
    case_type in ('wellbeing_support', 'parent_followup', 'teacher_followup', 'counselor_review', 'crisis', 'privacy_override')
  ),
  severity text not null check (
    severity in ('low', 'moderate', 'high', 'emergency')
  ),
  status text not null default 'open' check (
    status in ('open', 'triaged', 'assigned', 'in_progress', 'awaiting_external', 'resolved', 'closed', 'cancelled')
  ),
  safeguarding_owner_user_id uuid references users(id) on delete set null,
  privacy_override_active boolean not null default false,
  override_reason text,
  title text not null,
  summary text,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  next_review_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists case_assignments (
  id uuid primary key default gen_random_uuid(),
  escalation_case_id uuid not null references escalation_cases(id) on delete cascade,
  assigned_user_id uuid not null references users(id) on delete cascade,
  assignment_role text not null check (
    assignment_role in ('owner', 'reviewer', 'support', 'observer')
  ),
  status text not null default 'active' check (
    status in ('active', 'released', 'completed')
  ),
  assigned_by_user_id uuid references users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  released_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(escalation_case_id, assigned_user_id, assignment_role)
);

create table if not exists case_events (
  id uuid primary key default gen_random_uuid(),
  escalation_case_id uuid not null references escalation_cases(id) on delete cascade,
  event_type text not null check (
    event_type in (
      'case_opened',
      'signal_attached',
      'assignment_added',
      'status_changed',
      'guardian_contacted',
      'teacher_contacted',
      'student_contacted',
      'external_referral',
      'override_activated',
      'override_released',
      'case_resolved',
      'case_closed',
      'note_added'
    )
  ),
  actor_user_id uuid references users(id) on delete set null,
  event_summary text,
  event_payload jsonb not null default '{}',
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists case_notes (
  id uuid primary key default gen_random_uuid(),
  escalation_case_id uuid not null references escalation_cases(id) on delete cascade,
  author_user_id uuid references users(id) on delete set null,
  note_type text not null default 'internal' check (
    note_type in ('internal', 'summary', 'guardian_safe', 'teacher_safe', 'student_safe')
  ),
  visibility_scope text not null default 'safeguarding_only' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  body text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists support_contacts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) on delete set null,
  contact_type text not null check (
    contact_type in ('counselor', 'guardian', 'school_owner', 'crisis_line', 'external_referral', 'ngo_partner', 'other')
  ),
  audience_app text not null default 'shared' check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  label text not null,
  phone text,
  email text,
  contact_url text,
  service_hours text,
  priority integer not null default 3 check (priority between 1 and 5),
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists crisis_routing_rules (
  id uuid primary key default gen_random_uuid(),
  rule_key text not null unique,
  active boolean not null default true,
  severity text not null check (
    severity in ('moderate', 'high', 'emergency')
  ),
  trigger_category text not null check (
    trigger_category in ('self_harm', 'abuse_disclosure', 'panic', 'substance_use', 'violence', 'other')
  ),
  audience_app text not null default 'student' check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  route_to_contact_id uuid references support_contacts(id) on delete set null,
  action_summary text not null,
  escalation_sla_minutes integer,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (escalation_sla_minutes is null or escalation_sla_minutes > 0)
);

create index if not exists help_requests_student_idx
  on help_requests(student_profile_id, status, created_at desc);
create index if not exists help_requests_requester_idx
  on help_requests(requested_by_user_id, request_channel, created_at desc);

create index if not exists pastoral_flags_student_idx
  on pastoral_flags(student_profile_id, status, severity, created_at desc);
create index if not exists pastoral_flags_teacher_idx
  on pastoral_flags(teacher_profile_id, class_id, created_at desc);

create index if not exists monitoring_signals_student_idx
  on monitoring_signals(student_profile_id, signal_status, severity, triggered_at desc);
create index if not exists monitoring_signals_type_idx
  on monitoring_signals(signal_type, signal_status, triggered_at desc);
create index if not exists monitoring_signals_facts_gin_idx
  on monitoring_signals using gin(derived_facts);

create index if not exists signal_sources_signal_idx
  on signal_sources(monitoring_signal_id, source_type, source_record_id);

create index if not exists escalation_cases_student_idx
  on escalation_cases(student_profile_id, status, severity, opened_at desc);
create index if not exists escalation_cases_owner_idx
  on escalation_cases(safeguarding_owner_user_id, status, next_review_at);
create index if not exists escalation_cases_signal_idx
  on escalation_cases(primary_signal_id, status);

create index if not exists case_assignments_case_idx
  on case_assignments(escalation_case_id, status, assigned_at desc);
create index if not exists case_assignments_user_idx
  on case_assignments(assigned_user_id, status, assigned_at desc);

create index if not exists case_events_case_idx
  on case_events(escalation_case_id, occurred_at desc);
create index if not exists case_notes_case_idx
  on case_notes(escalation_case_id, created_at desc);
create index if not exists case_notes_visibility_idx
  on case_notes(visibility_scope, note_type, created_at desc);

create index if not exists support_contacts_school_idx
  on support_contacts(school_id, contact_type, active, priority);

create index if not exists crisis_routing_rules_lookup_idx
  on crisis_routing_rules(active, severity, trigger_category, audience_app);
