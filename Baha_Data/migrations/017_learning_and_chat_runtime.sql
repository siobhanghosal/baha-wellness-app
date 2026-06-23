alter table content_items
  drop constraint if exists content_items_content_type_check;

alter table content_items
  add constraint content_items_content_type_check check (
    content_type in (
      'learning_card',
      'learning_module',
      'quiz',
      'safe_question',
      'safe_answer',
      'game_scenario',
      'challenge_template',
      'conversation_guide',
      'escalation_copy',
      'privacy_copy',
      'onboarding_copy',
      'copy_block',
      'checklist',
      'reflection_prompt',
      'article',
      'media'
    )
  );

create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null unique references content_items(id) on delete cascade,
  quiz_key text not null unique,
  audience_app text not null default 'student' check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  age_cohort text not null default 'all',
  passing_score numeric(5,2),
  max_attempts integer,
  shuffle_items boolean not null default false,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (passing_score is null or (passing_score >= 0 and passing_score <= 100)),
  check (max_attempts is null or max_attempts > 0)
);

create table if not exists quiz_items (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  question_key text not null,
  prompt text not null,
  question_type text not null check (
    question_type in ('single_choice', 'multi_choice', 'true_false', 'short_text', 'scale', 'scenario')
  ),
  response_options jsonb not null default '[]',
  correct_answer jsonb not null default '{}',
  explanation text,
  points numeric(7,2) not null default 1,
  ordinal integer not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(quiz_id, question_key),
  unique(quiz_id, ordinal),
  check (points >= 0)
);

create table if not exists module_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  context_student_profile_id uuid references student_profiles(id) on delete set null,
  module_id uuid not null references learning_modules(id) on delete restrict,
  content_version_id uuid references content_versions(id) on delete set null,
  audience_app text not null check (
    audience_app in ('student', 'parent', 'teacher', 'counselor')
  ),
  status text not null default 'not_started' check (
    status in ('not_started', 'in_progress', 'completed', 'paused', 'abandoned')
  ),
  started_at timestamptz,
  completed_at timestamptz,
  last_activity_at timestamptz,
  completion_percent numeric(5,2) not null default 0 check (
    completion_percent >= 0 and completion_percent <= 100
  ),
  current_section_ordinal integer,
  current_step_ordinal integer,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists module_step_progress (
  id uuid primary key default gen_random_uuid(),
  module_progress_id uuid not null references module_progress(id) on delete cascade,
  step_id uuid not null references learning_module_steps(id) on delete restrict,
  status text not null default 'not_started' check (
    status in ('not_started', 'viewed', 'completed', 'skipped', 'locked')
  ),
  viewed_at timestamptz,
  completed_at timestamptz,
  attempts_count integer not null default 0,
  response_summary jsonb not null default '{}',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(module_progress_id, step_id),
  check (attempts_count >= 0)
);

create table if not exists quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  context_student_profile_id uuid references student_profiles(id) on delete set null,
  module_progress_id uuid references module_progress(id) on delete set null,
  module_step_progress_id uuid references module_step_progress(id) on delete set null,
  quiz_id uuid not null references quizzes(id) on delete restrict,
  status text not null default 'started' check (
    status in ('started', 'submitted', 'evaluated', 'abandoned')
  ),
  attempt_number integer not null default 1,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score_percent numeric(5,2),
  score_points numeric(9,2),
  passed boolean,
  evaluator_type text not null default 'system' check (
    evaluator_type in ('system', 'manual', 'hybrid')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (attempt_number > 0),
  check (score_percent is null or (score_percent >= 0 and score_percent <= 100))
);

create table if not exists quiz_attempt_items (
  id uuid primary key default gen_random_uuid(),
  quiz_attempt_id uuid not null references quiz_attempts(id) on delete cascade,
  quiz_item_id uuid not null references quiz_items(id) on delete restrict,
  response_value jsonb not null default '{}',
  response_text text,
  is_correct boolean,
  score_awarded numeric(9,2),
  answered_at timestamptz,
  feedback text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(quiz_attempt_id, quiz_item_id)
);

create table if not exists chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  context_student_profile_id uuid references student_profiles(id) on delete set null,
  audience_app text not null check (
    audience_app in ('student', 'parent', 'teacher', 'counselor')
  ),
  session_type text not null default 'general_support' check (
    session_type in (
      'general_support',
      'learning_helper',
      'checkin_followup',
      'parent_guidance',
      'teacher_guidance',
      'counselor_support',
      'crisis_triage'
    )
  ),
  status text not null default 'active' check (
    status in ('active', 'ended', 'archived', 'flagged')
  ),
  safety_disposition text not null default 'none' check (
    safety_disposition in ('none', 'checkin_prompt', 'guardian_notice', 'teacher_notice', 'counselor_review', 'emergency')
  ),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  last_message_at timestamptz,
  message_count integer not null default 0,
  summary_visibility_scope text not null default 'private' check (
    summary_visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (message_count >= 0)
);

create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_session_id uuid not null references chat_sessions(id) on delete cascade,
  sender_type text not null check (
    sender_type in ('user', 'assistant', 'system', 'reviewer')
  ),
  message_type text not null check (
    message_type in ('user_query', 'assistant_answer', 'assistant_followup', 'safety_event', 'system_note', 'review_note')
  ),
  ordinal integer not null,
  body text not null,
  structured_payload jsonb not null default '{}',
  retrieval_filters jsonb not null default '{}',
  safety_labels jsonb not null default '[]',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(chat_session_id, ordinal)
);

create table if not exists chat_answer_citations (
  id uuid primary key default gen_random_uuid(),
  chat_message_id uuid not null references chat_messages(id) on delete cascade,
  content_version_id uuid references content_versions(id) on delete set null,
  safe_question_answer_id uuid references safe_question_answers(id) on delete set null,
  resource_id uuid references acquired_resources(id) on delete set null,
  chunk_id uuid references resource_chunks(id) on delete set null,
  citation_label text,
  ordinal integer not null default 1,
  confidence numeric(5,4),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  check (
    content_version_id is not null
    or safe_question_answer_id is not null
    or resource_id is not null
    or chunk_id is not null
  )
);

create table if not exists chat_profile_summaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  student_profile_id uuid references student_profiles(id) on delete cascade,
  chat_session_id uuid references chat_sessions(id) on delete set null,
  summary_type text not null default 'rolling_context' check (
    summary_type in ('rolling_context', 'handoff', 'weekly_summary', 'case_summary')
  ),
  period_start timestamptz,
  period_end timestamptz,
  summary jsonb not null default '{}',
  visibility_scope text not null default 'private' check (
    visibility_scope in ('private', 'consented_summary', 'safeguarding_only')
  ),
  generated_by text not null default 'system',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (period_end is null or period_start is null or period_end >= period_start)
);

create index if not exists quizzes_lookup_idx
  on quizzes(audience_app, age_cohort, active);
create index if not exists quiz_items_quiz_idx
  on quiz_items(quiz_id, ordinal);
create index if not exists quiz_items_options_gin_idx
  on quiz_items using gin(response_options);

create index if not exists module_progress_user_idx
  on module_progress(user_id, audience_app, status, last_activity_at desc);
create index if not exists module_progress_student_idx
  on module_progress(context_student_profile_id, status, updated_at desc);
create index if not exists module_progress_module_idx
  on module_progress(module_id, status, updated_at desc);

create index if not exists module_step_progress_module_idx
  on module_step_progress(module_progress_id, status, completed_at desc);
create index if not exists module_step_progress_response_gin_idx
  on module_step_progress using gin(response_summary);

create index if not exists quiz_attempts_user_idx
  on quiz_attempts(user_id, quiz_id, started_at desc);
create index if not exists quiz_attempts_student_idx
  on quiz_attempts(context_student_profile_id, status, submitted_at desc);
create index if not exists quiz_attempts_module_idx
  on quiz_attempts(module_progress_id, module_step_progress_id);

create index if not exists quiz_attempt_items_attempt_idx
  on quiz_attempt_items(quiz_attempt_id, quiz_item_id);

create index if not exists chat_sessions_user_idx
  on chat_sessions(user_id, audience_app, status, last_message_at desc);
create index if not exists chat_sessions_student_idx
  on chat_sessions(context_student_profile_id, safety_disposition, updated_at desc);
create index if not exists chat_sessions_metadata_gin_idx
  on chat_sessions using gin(metadata);

create index if not exists chat_messages_session_idx
  on chat_messages(chat_session_id, ordinal);
create index if not exists chat_messages_payload_gin_idx
  on chat_messages using gin(structured_payload);

create index if not exists chat_answer_citations_message_idx
  on chat_answer_citations(chat_message_id, ordinal);
create index if not exists chat_answer_citations_resource_idx
  on chat_answer_citations(resource_id, chunk_id);

create index if not exists chat_profile_summaries_user_idx
  on chat_profile_summaries(user_id, summary_type, created_at desc);
create index if not exists chat_profile_summaries_student_idx
  on chat_profile_summaries(student_profile_id, visibility_scope, created_at desc);
create index if not exists chat_profile_summaries_summary_gin_idx
  on chat_profile_summaries using gin(summary);
