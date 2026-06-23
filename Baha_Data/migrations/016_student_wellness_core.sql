create table if not exists checkin_templates (
  id uuid primary key default gen_random_uuid(),
  template_key text not null unique,
  title text not null,
  cadence text not null default 'weekly' check (
    cadence in ('weekly', 'daily', 'custom')
  ),
  audience_app text not null default 'student' check (
    audience_app in ('student')
  ),
  age_cohort text not null default 'all',
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists checkin_questions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references checkin_templates(id) on delete cascade,
  question_key text not null,
  dimension text not null check (
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
      'sensitive_indirect'
    )
  ),
  question_type text not null check (
    question_type in ('scale', 'choice', 'multi_choice', 'text', 'boolean', 'scenario')
  ),
  prompt text not null,
  response_config jsonb not null default '{}',
  is_required boolean not null default true,
  ordinal integer not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(template_id, question_key),
  unique(template_id, ordinal)
);

create table if not exists checkin_response_sets (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  template_id uuid not null references checkin_templates(id) on delete restrict,
  scheduled_for timestamptz,
  submitted_at timestamptz,
  status text not null default 'draft' check (
    status in ('draft', 'submitted', 'superseded', 'deleted')
  ),
  source_mode text not null default 'scheduled' check (
    source_mode in ('scheduled', 'manual', 'daily_optional', 'challenge')
  ),
  visibility_scope text not null default 'private' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists checkin_responses (
  id uuid primary key default gen_random_uuid(),
  response_set_id uuid not null references checkin_response_sets(id) on delete cascade,
  question_id uuid not null references checkin_questions(id) on delete restrict,
  numeric_value numeric,
  text_value text,
  boolean_value boolean,
  selected_options jsonb not null default '[]',
  normalized_value jsonb not null default '{}',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(response_set_id, question_id)
);

create table if not exists trend_snapshots (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  snapshot_type text not null default 'weekly' check (
    snapshot_type in ('weekly', 'rolling_4_week', 'custom')
  ),
  period_start date not null,
  period_end date not null,
  source_response_set_ids uuid[] not null default '{}',
  summary jsonb not null default '{}',
  generated_by text not null default 'system',
  version integer not null default 1,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (period_end >= period_start)
);

create table if not exists reflection_entries (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  response_set_id uuid references checkin_response_sets(id) on delete set null,
  prompt_content_item_id uuid references content_items(id) on delete set null,
  title text,
  body text not null,
  source_type text not null default 'reflection' check (
    source_type in ('reflection', 'challenge', 'game', 'manual', 'module')
  ),
  visibility_scope text not null default 'private' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists challenge_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  challenge_content_item_id uuid not null references content_items(id) on delete restrict,
  status text not null default 'active' check (
    status in ('active', 'completed', 'abandoned', 'paused')
  ),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_profile_id, challenge_content_item_id, started_at)
);

create table if not exists challenge_progress (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references challenge_enrollments(id) on delete cascade,
  day_number integer,
  step_key text,
  status text not null default 'pending' check (
    status in ('pending', 'completed', 'skipped')
  ),
  completed_at timestamptz,
  reflection_entry_id uuid references reflection_entries(id) on delete set null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists badge_definitions (
  id uuid primary key default gen_random_uuid(),
  badge_key text not null unique,
  title text not null,
  description text,
  audience_app text not null default 'student' check (
    audience_app in ('student')
  ),
  category text not null check (
    category in ('checkin', 'learning', 'game', 'challenge', 'help', 'reflection')
  ),
  content_item_id uuid references content_items(id) on delete set null,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists badge_awards (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  badge_definition_id uuid not null references badge_definitions(id) on delete restrict,
  awarded_at timestamptz not null default now(),
  source_type text not null check (
    source_type in ('system', 'challenge', 'learning', 'game', 'help', 'manual')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique(student_profile_id, badge_definition_id, awarded_at)
);

create table if not exists game_sessions (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  scenario_content_item_id uuid references content_items(id) on delete set null,
  game_type text not null check (
    game_type in ('emotion_explorer', 'friendship_choices', 'calm_breathing', 'other')
  ),
  status text not null default 'started' check (
    status in ('started', 'completed', 'abandoned', 'timed_out')
  ),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds integer,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists game_session_events (
  id uuid primary key default gen_random_uuid(),
  game_session_id uuid not null references game_sessions(id) on delete cascade,
  event_type text not null,
  event_time timestamptz not null default now(),
  ordinal integer not null default 1,
  event_payload jsonb not null default '{}',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists game_behavioral_signals (
  id uuid primary key default gen_random_uuid(),
  game_session_id uuid not null references game_sessions(id) on delete cascade,
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  signal_type text not null,
  signal_value numeric,
  signal_label text,
  confidence numeric,
  visibility_scope text not null default 'private' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists checkin_templates_lookup_idx
  on checkin_templates(template_key, cadence, age_cohort, active);
create index if not exists checkin_questions_template_idx
  on checkin_questions(template_id, ordinal, dimension);
create index if not exists checkin_questions_response_config_gin_idx
  on checkin_questions using gin(response_config);

create index if not exists checkin_response_sets_student_idx
  on checkin_response_sets(student_profile_id, status, submitted_at desc);
create index if not exists checkin_response_sets_template_idx
  on checkin_response_sets(template_id, source_mode, created_at desc);
create index if not exists checkin_response_sets_metadata_gin_idx
  on checkin_response_sets using gin(metadata);

create index if not exists checkin_responses_set_idx
  on checkin_responses(response_set_id, question_id);
create index if not exists checkin_responses_normalized_gin_idx
  on checkin_responses using gin(normalized_value);

create index if not exists trend_snapshots_student_idx
  on trend_snapshots(student_profile_id, snapshot_type, period_end desc);
create index if not exists trend_snapshots_summary_gin_idx
  on trend_snapshots using gin(summary);

create index if not exists reflection_entries_student_idx
  on reflection_entries(student_profile_id, source_type, created_at desc);

create index if not exists challenge_enrollments_student_idx
  on challenge_enrollments(student_profile_id, status, started_at desc);
create index if not exists challenge_progress_enrollment_idx
  on challenge_progress(enrollment_id, status, day_number);

create index if not exists badge_definitions_category_idx
  on badge_definitions(category, active);
create index if not exists badge_awards_student_idx
  on badge_awards(student_profile_id, awarded_at desc);

create index if not exists game_sessions_student_idx
  on game_sessions(student_profile_id, game_type, started_at desc);
create index if not exists game_session_events_session_idx
  on game_session_events(game_session_id, ordinal);
create index if not exists game_behavioral_signals_student_idx
  on game_behavioral_signals(student_profile_id, signal_type, created_at desc);
create index if not exists game_behavioral_signals_session_idx
  on game_behavioral_signals(game_session_id, signal_type);
