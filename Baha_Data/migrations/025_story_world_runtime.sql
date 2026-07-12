create table if not exists story_world_profiles (
  student_profile_id uuid primary key references student_profiles(id) on delete cascade,
  display_name text not null,
  theme_variant text not null default 'guided_adventure',
  pet_name text not null default 'Comet',
  xp integer not null default 120 check (xp >= 0),
  coins integer not null default 40 check (coins >= 0),
  stars integer not null default 0 check (stars >= 0),
  current_day integer not null default 1 check (current_day >= 1),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists story_world_location_progress (
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  location_id text not null,
  chapter integer not null default 1 check (chapter >= 1),
  last_choice text,
  completed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (student_profile_id, location_id)
);

create table if not exists story_world_npc_states (
  student_profile_id uuid not null references student_profiles(id) on delete cascade,
  npc_id text not null,
  npc_name text not null,
  friendship_level integer not null default 1 check (friendship_level >= 0),
  current_mood text not null default 'curious',
  memories jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (student_profile_id, npc_id)
);

create index if not exists story_world_location_progress_updated_idx
  on story_world_location_progress(student_profile_id, updated_at desc);

create index if not exists story_world_npc_states_updated_idx
  on story_world_npc_states(student_profile_id, updated_at desc);
