create table if not exists content_items (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  content_type text not null check (
    content_type in (
      'learning_card',
      'learning_module',
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
  ),
  audience_app text not null default 'shared' check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  age_cohort text not null default 'all',
  theme text,
  topic text,
  subtopic text,
  language text not null default 'en',
  risk_level text not null default 'none' check (
    risk_level in ('none', 'low', 'moderate', 'high', 'emergency')
  ),
  consent_sensitivity text not null default 'tier1' check (
    consent_sensitivity in ('tier1', 'tier2', 'tier3', 'internal')
  ),
  lifecycle_status text not null default 'draft' check (
    lifecycle_status in ('draft', 'active', 'archived')
  ),
  review_status text not null default 'draft' check (
    review_status in ('draft', 'under_review', 'approved', 'rejected', 'flagged')
  ),
  source_kind text not null default 'manual' check (
    source_kind in ('manual', 'derived', 'generated', 'imported')
  ),
  summary text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists content_versions (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references content_items(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  version_status text not null default 'draft' check (
    version_status in ('draft', 'approved', 'published', 'archived', 'flagged')
  ),
  body jsonb not null default '{}',
  plain_text text,
  changelog text,
  source_hash text,
  reviewed_by text,
  reviewed_at timestamptz,
  effective_from timestamptz,
  effective_to timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(content_item_id, version_number)
);

create table if not exists content_assets (
  id uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references content_versions(id) on delete cascade,
  asset_type text not null check (
    asset_type in ('image', 'audio', 'video', 'document', 'animation', 'icon', 'attachment')
  ),
  storage_uri text not null,
  mime_type text,
  alt_text text,
  ordinal integer not null default 1,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(content_version_id, asset_type, storage_uri)
);

create table if not exists content_citations (
  id uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references content_versions(id) on delete cascade,
  resource_id uuid references acquired_resources(id) on delete set null,
  chunk_id uuid references resource_chunks(id) on delete set null,
  citation_label text,
  quote_text text,
  ordinal integer not null default 1,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  check (resource_id is not null or chunk_id is not null)
);

create table if not exists content_review_queue (
  id uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references content_versions(id) on delete cascade,
  status text not null default 'pending' check (
    status in ('pending', 'in_review', 'approved', 'rejected', 'changes_requested')
  ),
  priority integer not null default 3 check (priority between 1 and 5),
  requested_by text,
  assigned_reviewer text,
  reason text,
  notes text,
  decided_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists content_publish_targets (
  id uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references content_versions(id) on delete cascade,
  audience_app text not null check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  platform text not null default 'android' check (
    platform in ('android', 'ios', 'web', 'all')
  ),
  age_cohort text not null default 'all',
  activation_status text not null default 'inactive' check (
    activation_status in ('inactive', 'scheduled', 'active', 'retired')
  ),
  effective_from timestamptz,
  effective_to timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(content_version_id, audience_app, platform, age_cohort)
);

create table if not exists safe_questions (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null unique references content_items(id) on delete cascade,
  question_key text not null unique,
  canonical_question text not null,
  normalized_question text not null,
  topic text,
  subtopic text,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists safe_question_answers (
  id uuid primary key default gen_random_uuid(),
  safe_question_id uuid not null references safe_questions(id) on delete cascade,
  content_version_id uuid not null references content_versions(id) on delete cascade,
  audience_app text not null default 'student' check (
    audience_app in ('student', 'parent', 'teacher', 'counselor', 'shared')
  ),
  age_cohort text not null default 'all',
  answer_kind text not null default 'primary' check (
    answer_kind in ('primary', 'fallback', 'escalation')
  ),
  priority integer not null default 1,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(safe_question_id, content_version_id)
);

create table if not exists learning_modules (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null unique references content_items(id) on delete cascade,
  module_code text not null unique,
  role_track text not null check (
    role_track in ('student', 'parent', 'teacher', 'counselor')
  ),
  theme text not null,
  age_cohort text not null default 'all',
  estimated_minutes integer,
  sort_order integer not null default 1,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists learning_module_sections (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references learning_modules(id) on delete cascade,
  title text not null,
  ordinal integer not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(module_id, ordinal)
);

create table if not exists learning_module_steps (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references learning_module_sections(id) on delete cascade,
  content_item_id uuid references content_items(id) on delete set null,
  step_type text not null check (
    step_type in ('content', 'quiz', 'reflection', 'checklist', 'media', 'prompt', 'link')
  ),
  title text,
  ordinal integer not null,
  is_required boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(section_id, ordinal)
);

create table if not exists copy_blocks (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null unique references content_items(id) on delete cascade,
  copy_key text not null unique,
  surface text not null,
  locale text not null default 'en',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists content_items_type_idx
  on content_items(content_type, audience_app, age_cohort, lifecycle_status);
create index if not exists content_items_theme_idx
  on content_items(theme, topic, subtopic);
create index if not exists content_items_review_idx
  on content_items(review_status, lifecycle_status, language);
create index if not exists content_items_metadata_gin_idx
  on content_items using gin(metadata);

create index if not exists content_versions_item_status_idx
  on content_versions(content_item_id, version_status, created_at desc);
create index if not exists content_versions_effective_idx
  on content_versions(effective_from, effective_to);
create index if not exists content_versions_body_gin_idx
  on content_versions using gin(body);

create index if not exists content_assets_version_idx
  on content_assets(content_version_id, ordinal);

create index if not exists content_citations_version_idx
  on content_citations(content_version_id, ordinal);
create index if not exists content_citations_resource_idx
  on content_citations(resource_id, chunk_id);

create index if not exists content_review_queue_status_idx
  on content_review_queue(status, priority, created_at);

create index if not exists content_publish_targets_status_idx
  on content_publish_targets(audience_app, platform, activation_status, effective_from);

create index if not exists safe_questions_lookup_idx
  on safe_questions(normalized_question, active);
create index if not exists safe_question_answers_lookup_idx
  on safe_question_answers(safe_question_id, audience_app, age_cohort, answer_kind, active);

create index if not exists learning_modules_lookup_idx
  on learning_modules(role_track, theme, age_cohort, active, sort_order);
create index if not exists learning_module_sections_module_idx
  on learning_module_sections(module_id, ordinal);
create index if not exists learning_module_steps_section_idx
  on learning_module_steps(section_id, ordinal);

create index if not exists copy_blocks_surface_idx
  on copy_blocks(surface, locale, copy_key);
