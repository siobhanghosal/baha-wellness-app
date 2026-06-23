create extension if not exists vector;

create table if not exists resource_chunks (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references acquired_resources(id) on delete cascade,
  ordinal integer not null,
  text text not null,
  token_count integer not null,
  content_hash text not null,
  metadata jsonb not null default '{}',
  search_vector tsvector generated always as (to_tsvector('english', text)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(resource_id, ordinal, content_hash)
);

create table if not exists resource_embeddings (
  id uuid primary key default gen_random_uuid(),
  chunk_id uuid not null references resource_chunks(id) on delete cascade,
  document_id uuid not null references acquired_resources(id) on delete cascade,
  source text not null,
  organization text not null,
  topic text,
  audience text,
  model text not null,
  dimensions integer not null default 1024,
  embedding vector(1024) not null,
  content_hash text not null,
  created_at timestamptz not null default now(),
  unique(chunk_id, model, content_hash)
);

create table if not exists condition_embeddings (
  id uuid primary key default gen_random_uuid(),
  condition_profile_id uuid not null references condition_profiles(id) on delete cascade,
  condition text not null,
  text text not null,
  model text not null,
  dimensions integer not null default 1024,
  embedding vector(1024) not null,
  content_hash text not null,
  created_at timestamptz not null default now(),
  unique(condition_profile_id, model, content_hash)
);

create table if not exists knowledge_embeddings (
  id uuid primary key default gen_random_uuid(),
  knowledge_node_id uuid not null references knowledge_graph_nodes(id) on delete cascade,
  node_type text not null,
  label text not null,
  text text not null,
  model text not null,
  dimensions integer not null default 1024,
  embedding vector(1024) not null,
  content_hash text not null,
  created_at timestamptz not null default now(),
  unique(knowledge_node_id, model, content_hash)
);

create table if not exists embedding_runs (
  id uuid primary key default gen_random_uuid(),
  model text not null,
  chunk_size integer not null,
  chunk_overlap integer not null,
  status text not null default 'running',
  resources_embedded integer not null default 0,
  chunks_embedded integer not null default 0,
  conditions_embedded integer not null default 0,
  knowledge_nodes_embedded integer not null default 0,
  errors integer not null default 0,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  report jsonb not null default '{}'
);

create index if not exists resource_chunks_resource_idx on resource_chunks(resource_id, ordinal);
create index if not exists resource_chunks_search_idx on resource_chunks using gin(search_vector);
create index if not exists resource_embeddings_metadata_idx
  on resource_embeddings(organization, topic, audience);

create index if not exists resource_embeddings_ivfflat_idx
  on resource_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 100);
create index if not exists condition_embeddings_ivfflat_idx
  on condition_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 25);
create index if not exists knowledge_embeddings_ivfflat_idx
  on knowledge_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 100);

insert into priority_sources (
  organization, priority_rank, source_weight, is_baha_source, is_iap_source,
  manual_upload_enabled, active
) values
('NICE', 7, 0.800, false, false, false, true),
('NIMH', 7, 0.800, false, false, false, true),
('NIH', 7, 0.800, false, false, false, true),
('CDC', 7, 0.800, false, false, false, true),
('NHS', 7, 0.800, false, false, false, true),
('SAMHSA', 7, 0.800, false, false, false, true),
('American Academy of Pediatrics', 7, 0.800, false, false, false, true),
('CBSE', 7, 0.800, false, false, false, true),
('NCPCR', 7, 0.800, false, false, false, true)
on conflict (organization) do update set
  priority_rank = excluded.priority_rank,
  source_weight = excluded.source_weight,
  active = true,
  updated_at = now();
