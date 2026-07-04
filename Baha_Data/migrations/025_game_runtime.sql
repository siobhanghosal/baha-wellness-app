create table if not exists game_players (
  id uuid primary key default gen_random_uuid(),
  player_key_hash char(64) not null unique,
  display_name text not null default 'Adventurer',
  age_years smallint not null default 10 check (age_years between 9 and 12),
  xp integer not null default 320 check (xp >= 0),
  coins integer not null default 84 check (coins >= 0),
  stars integer not null default 12 check (stars >= 0),
  current_day integer not null default 7 check (current_day >= 1),
  pet text not null default 'Fox',
  avatar jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists game_location_progress (
  player_id uuid not null references game_players(id) on delete cascade,
  location_id text not null,
  chapter integer not null default 1 check (chapter >= 1),
  last_choice text,
  updated_at timestamptz not null default now(),
  primary key (player_id, location_id)
);

create table if not exists game_npc_states (
  player_id uuid not null references game_players(id) on delete cascade,
  npc_id text not null,
  friendship_level integer not null default 1 check (friendship_level >= 0),
  current_mood text not null default 'curious',
  memories jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (player_id, npc_id)
);

create table if not exists game_behaviour_profiles (
  player_id uuid not null references game_players(id) on delete cascade,
  signal_key text not null,
  weighted_value double precision not null default 0.5
    check (weighted_value between 0 and 1),
  confidence double precision not null default 0.1
    check (confidence between 0 and 1),
  observation_count integer not null default 0 check (observation_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (player_id, signal_key)
);

create table if not exists game_story_events (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references game_players(id) on delete cascade,
  location_id text not null,
  chapter integer not null,
  choice_text text not null,
  choice_kind text not null check (choice_kind in ('guided', 'custom')),
  consequence jsonb not null default '{}'::jsonb,
  observed_signals jsonb not null default '[]'::jsonb,
  evidence_chunk_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_game_story_events_player_created
  on game_story_events (player_id, created_at desc);

create index if not exists idx_game_npc_states_player
  on game_npc_states (player_id);

comment on table game_behaviour_profiles is
  'Confidence-weighted gameplay observations only. Never use for diagnosis or expose as child-facing scores.';

insert into game_npc_states (
  player_id,
  npc_id,
  friendship_level,
  current_mood,
  memories
)
select
  gp.id,
  seed.npc_id,
  seed.friendship_level,
  seed.current_mood,
  seed.memories::jsonb
from game_players gp
cross join (
  values
    ('Pip', 3, 'cheerful', '["Pip knows your favourite place is the beach."]'),
    ('Maya', 2, 'hopeful', '["Maya remembers that you saved her a seat at lunch."]'),
    ('Niko', 1, 'curious', '[]')
) as seed(npc_id, friendship_level, current_mood, memories)
on conflict (player_id, npc_id) do nothing;
