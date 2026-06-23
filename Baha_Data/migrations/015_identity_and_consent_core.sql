create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  external_auth_id text unique,
  email text,
  phone text,
  display_name text not null,
  status text not null default 'active' check (
    status in ('pending', 'active', 'disabled', 'archived')
  ),
  preferred_language text not null default 'en',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (email is not null or phone is not null or external_auth_id is not null)
);

create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  role_key text not null unique check (
    role_key in ('student', 'guardian', 'teacher', 'counselor', 'administrator', 'baha_admin')
  ),
  description text,
  created_at timestamptz not null default now()
);

insert into roles (role_key, description) values
('student', 'Student user'),
('guardian', 'Parent or guardian user'),
('teacher', 'Teacher or school staff user'),
('counselor', 'Counselor or clinician user'),
('administrator', 'Operational administrator'),
('baha_admin', 'BAHA administrative owner')
on conflict (role_key) do nothing;

create table if not exists user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  role_id uuid not null references roles(id) on delete cascade,
  status text not null default 'active' check (
    status in ('active', 'revoked')
  ),
  granted_by text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, role_id)
);

create table if not exists schools (
  id uuid primary key default gen_random_uuid(),
  school_code text unique,
  name text not null,
  city text,
  state text,
  country text not null default 'India',
  status text not null default 'active' check (
    status in ('active', 'inactive', 'archived')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists student_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users(id) on delete cascade,
  student_code text unique,
  school_id uuid references schools(id) on delete set null,
  presentation_age_cohort text not null default 'all',
  legal_consent_band text not null check (
    legal_consent_band in ('minor', 'adult')
  ),
  gender text not null default 'unspecified',
  date_of_birth date,
  enrollment_status text not null default 'active' check (
    enrollment_status in ('active', 'inactive', 'graduated', 'withdrawn')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists guardians (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users(id) on delete cascade,
  guardian_type text not null default 'parent' check (
    guardian_type in ('parent', 'guardian', 'caregiver', 'other')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists student_guardian_links (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  guardian_id uuid not null references guardians(id) on delete cascade,
  relationship_to_student text not null,
  is_primary boolean not null default false,
  consent_authority boolean not null default true,
  status text not null default 'active' check (
    status in ('active', 'inactive', 'revoked')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_profile_id, guardian_id)
);

create table if not exists teacher_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users(id) on delete cascade,
  school_id uuid references schools(id) on delete set null,
  staff_code text,
  staff_type text not null default 'teacher' check (
    staff_type in ('teacher', 'counselor', 'administrator', 'pastoral_staff', 'other')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  class_code text,
  label text not null,
  academic_year text,
  grade_band text,
  status text not null default 'active' check (
    status in ('active', 'inactive', 'archived')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(school_id, class_code, academic_year)
);

create table if not exists class_memberships (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  membership_status text not null default 'active' check (
    membership_status in ('active', 'inactive', 'archived')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(class_id, student_profile_id)
);

create table if not exists teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  teacher_profile_id uuid not null references teacher_profiles(id) on delete cascade,
  class_id uuid not null references classes(id) on delete cascade,
  assignment_type text not null default 'teacher' check (
    assignment_type in ('teacher', 'class_teacher', 'pastoral_owner', 'counselor')
  ),
  status text not null default 'active' check (
    status in ('active', 'inactive', 'archived')
  ),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(teacher_profile_id, class_id, assignment_type)
);

create table if not exists school_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  school_id uuid not null references schools(id) on delete cascade,
  enrollment_status text not null default 'active' check (
    enrollment_status in ('active', 'inactive', 'graduated', 'withdrawn')
  ),
  enrolled_at timestamptz not null default now(),
  ended_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists consent_versions (
  id uuid primary key default gen_random_uuid(),
  consent_type text not null check (
    consent_type in (
      'platform_participation',
      'chatbot_use',
      'game_behavioral_signals',
      'learning_module_participation',
      'parent_summary_sharing',
      'teacher_referral_workflow',
      'research_use',
      'community_features',
      'nearby_events'
    )
  ),
  version_label text not null,
  policy_reference text,
  language text not null default 'en',
  summary_text text,
  full_text jsonb not null default '{}',
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  active boolean not null default true,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(consent_type, version_label, language)
);

create table if not exists consent_records (
  id uuid primary key default gen_random_uuid(),
  consent_version_id uuid not null references consent_versions(id) on delete restrict,
  subject_user_id uuid not null references users(id) on delete cascade,
  actor_user_id uuid references users(id) on delete set null,
  student_profile_id uuid references student_profiles(id) on delete set null,
  guardian_id uuid references guardians(id) on delete set null,
  consent_type text not null,
  actor_relationship text,
  scope text not null default 'general',
  status text not null check (
    status in ('granted', 'declined', 'withdrawn', 'expired', 'superseded')
  ),
  granted_at timestamptz,
  withdrawn_at timestamptz,
  expires_at timestamptz,
  evidence_ref text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists privacy_tier_settings (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  configured_by_user_id uuid references users(id) on delete set null,
  tier_1_enabled boolean not null default true,
  tier_2_enabled boolean not null default false,
  tier_3_enabled boolean not null default false,
  status text not null default 'active' check (
    status in ('active', 'superseded', 'revoked')
  ),
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists override_events (
  id uuid primary key default gen_random_uuid(),
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  subject_user_id uuid not null references users(id) on delete cascade,
  triggered_by_user_id uuid references users(id) on delete set null,
  category text not null check (
    category in (
      'self_harm',
      'suicidal_ideation',
      'abuse_disclosure',
      'sexual_assault',
      'danger_to_self_or_others',
      'substance_crisis',
      'other_safeguarding'
    )
  ),
  source_type text not null check (
    source_type in ('chatbot', 'checkin', 'teacher_flag', 'manual', 'system')
  ),
  share_scope text not null default 'minimum_necessary' check (
    share_scope in ('minimum_necessary', 'guardian_and_counselor', 'school_and_counselor')
  ),
  notification_status text not null default 'pending' check (
    notification_status in ('pending', 'notified', 'acknowledged', 'closed')
  ),
  triggered_at timestamptz not null default now(),
  details jsonb not null default '{}',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists users_status_idx
  on users(status, created_at);
create index if not exists users_email_idx
  on users(email);
create index if not exists users_phone_idx
  on users(phone);
create index if not exists users_metadata_gin_idx
  on users using gin(metadata);

create index if not exists user_roles_user_idx
  on user_roles(user_id, status);
create index if not exists user_roles_role_idx
  on user_roles(role_id, status);

create index if not exists schools_status_idx
  on schools(status, city, state);

create index if not exists student_profiles_school_idx
  on student_profiles(school_id, presentation_age_cohort, legal_consent_band);
create index if not exists student_profiles_status_idx
  on student_profiles(enrollment_status, created_at);

create index if not exists guardians_type_idx
  on guardians(guardian_type);
create index if not exists student_guardian_links_student_idx
  on student_guardian_links(student_profile_id, status, is_primary);
create index if not exists student_guardian_links_guardian_idx
  on student_guardian_links(guardian_id, status);

create index if not exists teacher_profiles_school_idx
  on teacher_profiles(school_id, staff_type);

create index if not exists classes_school_idx
  on classes(school_id, academic_year, status);
create index if not exists class_memberships_class_idx
  on class_memberships(class_id, membership_status);
create index if not exists class_memberships_student_idx
  on class_memberships(student_profile_id, membership_status);
create index if not exists teacher_assignments_class_idx
  on teacher_assignments(class_id, assignment_type, status);
create index if not exists teacher_assignments_teacher_idx
  on teacher_assignments(teacher_profile_id, assignment_type, status);

create index if not exists school_enrollments_student_idx
  on school_enrollments(student_profile_id, enrollment_status);
create index if not exists school_enrollments_school_idx
  on school_enrollments(school_id, enrollment_status);

create index if not exists consent_versions_type_idx
  on consent_versions(consent_type, active, effective_from desc);
create index if not exists consent_versions_full_text_gin_idx
  on consent_versions using gin(full_text);

create index if not exists consent_records_subject_idx
  on consent_records(subject_user_id, consent_type, status, created_at desc);
create index if not exists consent_records_student_idx
  on consent_records(student_profile_id, consent_type, status, created_at desc);
create index if not exists consent_records_guardian_idx
  on consent_records(guardian_id, consent_type, status, created_at desc);
create index if not exists consent_records_version_idx
  on consent_records(consent_version_id, status);
create index if not exists consent_records_metadata_gin_idx
  on consent_records using gin(metadata);

create index if not exists privacy_tier_settings_student_idx
  on privacy_tier_settings(student_profile_id, status, effective_from desc);

create index if not exists override_events_student_idx
  on override_events(student_profile_id, category, notification_status, triggered_at desc);
create index if not exists override_events_source_idx
  on override_events(source_type, notification_status, triggered_at desc);
create index if not exists override_events_details_gin_idx
  on override_events using gin(details);
