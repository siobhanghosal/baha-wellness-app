create table if not exists student_weekly_summaries (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  privacy_tier_applied text not null default 'tier1' check (
    privacy_tier_applied in ('tier1', 'tier2', 'tier3', 'safeguarding_only')
  ),
  summary_status text not null default 'ready' check (
    summary_status in ('pending', 'ready', 'suppressed', 'flagged')
  ),
  summary jsonb not null default '{}',
  source_window jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_profile_id, week_start, week_end),
  check (week_end >= week_start)
);

create table if not exists parent_weekly_summaries (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  guardian_id uuid not null references guardians(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  consent_status text not null default 'approved' check (
    consent_status in ('approved', 'withheld', 'suppressed', 'override_only')
  ),
  visible_tiers jsonb not null default '[]',
  summary jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_profile_id, guardian_id, week_start, week_end),
  check (week_end >= week_start)
);

create table if not exists teacher_cohort_summaries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  class_id uuid references classes(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  summary_scope text not null default 'class' check (
    summary_scope in ('class', 'grade', 'school')
  ),
  student_count integer not null default 0,
  anonymized_summary jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(school_id, class_id, week_start, week_end, summary_scope),
  check (student_count >= 0),
  check (week_end >= week_start)
);

create table if not exists baha_pilot_dashboard_metrics (
  id uuid primary key default gen_random_uuid(),
  metric_scope text not null default 'global' check (
    metric_scope in ('global', 'school', 'class', 'content', 'support')
  ),
  scope_key text not null default 'all',
  period_start date not null,
  period_end date not null,
  metrics jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(metric_scope, scope_key, period_start, period_end),
  check (period_end >= period_start)
);

create table if not exists content_usage_snapshots (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references content_items(id) on delete cascade,
  audience_app text not null check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  period_start date not null,
  period_end date not null,
  usage_metrics jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(content_item_id, audience_app, period_start, period_end),
  check (period_end >= period_start)
);

create table if not exists engagement_snapshots (
  id uuid primary key default gen_random_uuid(),
  audience_app text not null check (
    audience_app in ('student', 'parent', 'teacher', 'counselor')
  ),
  cohort_key text not null,
  period_start date not null,
  period_end date not null,
  metrics jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(audience_app, cohort_key, period_start, period_end),
  check (period_end >= period_start)
);

create table if not exists escalation_review_metrics (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) on delete set null,
  period_start date not null,
  period_end date not null,
  metrics jsonb not null default '{}',
  generation_version text not null default 'v1',
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(school_id, period_start, period_end),
  check (period_end >= period_start)
);

create index if not exists student_weekly_summaries_student_idx
  on student_weekly_summaries(student_profile_id, week_end desc, summary_status);
create index if not exists student_weekly_summaries_summary_gin_idx
  on student_weekly_summaries using gin(summary);

create index if not exists parent_weekly_summaries_guardian_idx
  on parent_weekly_summaries(guardian_id, week_end desc, consent_status);
create index if not exists parent_weekly_summaries_student_idx
  on parent_weekly_summaries(student_profile_id, week_end desc);

create index if not exists teacher_cohort_summaries_class_idx
  on teacher_cohort_summaries(class_id, week_end desc, summary_scope);
create index if not exists teacher_cohort_summaries_school_idx
  on teacher_cohort_summaries(school_id, week_end desc);

create index if not exists baha_pilot_dashboard_metrics_scope_idx
  on baha_pilot_dashboard_metrics(metric_scope, scope_key, period_end desc);

create index if not exists content_usage_snapshots_content_idx
  on content_usage_snapshots(content_item_id, audience_app, period_end desc);

create index if not exists engagement_snapshots_audience_idx
  on engagement_snapshots(audience_app, cohort_key, period_end desc);

create index if not exists escalation_review_metrics_school_idx
  on escalation_review_metrics(school_id, period_end desc);
