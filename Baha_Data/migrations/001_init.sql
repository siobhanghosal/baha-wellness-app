create extension if not exists vector;
create extension if not exists pgcrypto;

create table if not exists approved_sources (
  id uuid primary key default gen_random_uuid(),
  organization text not null unique,
  country text,
  source_type text not null default 'organization',
  base_domains text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists taxonomy (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  condition text not null unique,
  topics text[] not null default '{}',
  severity_defaults text[] not null default '{low,moderate,high,emergency}',
  created_at timestamptz not null default now()
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text not null unique,
  source text not null,
  organization text not null,
  author text,
  publication_date date,
  country text,
  audience text not null default 'general',
  content_hash text not null,
  etag text,
  last_modified text,
  version integer not null default 1,
  status text not null default 'active',
  metadata jsonb not null default '{}',
  ingested_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references documents(id) on delete cascade,
  version integer not null,
  content_hash text not null,
  storage_uri text,
  created_at timestamptz not null default now(),
  unique(document_id, version)
);

create table if not exists chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references documents(id) on delete cascade,
  ordinal integer not null,
  text text not null,
  token_count integer not null,
  metadata jsonb not null,
  search_vector tsvector generated always as (to_tsvector('english', text)) stored,
  created_at timestamptz not null default now(),
  unique(document_id, ordinal)
);

create table if not exists embeddings (
  id uuid primary key default gen_random_uuid(),
  chunk_id uuid not null references chunks(id) on delete cascade,
  model text not null,
  dimensions integer not null,
  embedding vector(1024) not null,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  unique(chunk_id, model, version)
);

create table if not exists citations (
  id uuid primary key default gen_random_uuid(),
  chunk_id uuid not null references chunks(id) on delete cascade,
  document_id uuid not null references documents(id) on delete cascade,
  title text not null,
  organization text not null,
  url text,
  publication_date date,
  quote text,
  created_at timestamptz not null default now()
);

create table if not exists condition_profiles (
  id uuid primary key default gen_random_uuid(),
  condition text not null references taxonomy(condition),
  profile jsonb not null,
  evidence_chunk_ids uuid[] not null default '{}',
  review_status text not null default 'draft',
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(condition)
);

create table if not exists crawl_state (
  id uuid primary key default gen_random_uuid(),
  url text not null unique,
  organization text not null,
  etag text,
  last_modified text,
  last_content_hash text,
  last_crawled_at timestamptz,
  next_crawl_at timestamptz,
  status text not null default 'pending',
  error text
);

create table if not exists retrieval_events (
  id uuid primary key default gen_random_uuid(),
  query text not null,
  filters jsonb not null default '{}',
  result_count integer not null,
  top_confidence numeric not null default 0,
  audience text,
  created_at timestamptz not null default now()
);

create index if not exists documents_org_idx on documents(organization);
create index if not exists documents_publication_date_idx on documents(publication_date);
create index if not exists chunks_metadata_gin_idx on chunks using gin(metadata);
create index if not exists chunks_search_vector_idx on chunks using gin(search_vector);
create index if not exists embeddings_vector_hnsw_idx on embeddings using hnsw (embedding vector_cosine_ops);
create index if not exists crawl_state_next_crawl_idx on crawl_state(next_crawl_at, status);

insert into taxonomy (category, condition, topics) values
('Emotional', 'Anxiety', array['worry', 'fear', 'panic', 'avoidance']),
('Emotional', 'Depression', array['low mood', 'withdrawal', 'hopelessness']),
('Emotional', 'Loneliness', array['connection', 'social support']),
('Emotional', 'Stress', array['coping', 'pressure', 'relaxation']),
('Emotional', 'Burnout', array['exhaustion', 'school pressure']),
('Emotional', 'Grief', array['loss', 'bereavement']),
('Academic', 'Exam Stress', array['exams', 'study skills', 'pressure']),
('Academic', 'Performance Anxiety', array['performance', 'evaluation']),
('Academic', 'School Avoidance', array['attendance', 'avoidance']),
('Social', 'Bullying', array['peer harm', 'school safety']),
('Social', 'Cyberbullying', array['online harm', 'digital safety']),
('Social', 'Peer Pressure', array['decision making', 'boundaries']),
('Social', 'Social Isolation', array['belonging', 'withdrawal']),
('Behavioral', 'Anger', array['emotion regulation', 'conflict']),
('Behavioral', 'Aggression', array['harm', 'discipline', 'safety']),
('Behavioral', 'Risk Taking', array['impulsivity', 'safety']),
('Neurodevelopmental', 'ADHD', array['attention', 'impulsivity', 'hyperactivity']),
('Neurodevelopmental', 'Autism', array['communication', 'sensory needs']),
('Neurodevelopmental', 'Learning Difficulties', array['learning support', 'screening']),
('Lifestyle', 'Sleep Disorders', array['sleep hygiene', 'fatigue']),
('Lifestyle', 'Gaming Addiction', array['gaming', 'digital wellbeing']),
('Lifestyle', 'Internet Addiction', array['internet use', 'screen time']),
('Lifestyle', 'Physical Inactivity', array['movement', 'exercise']),
('High Risk', 'Self Harm', array['injury', 'coping', 'safety']),
('High Risk', 'Suicide Risk', array['suicidal thoughts', 'crisis', 'emergency']),
('High Risk', 'Substance Abuse', array['alcohol', 'tobacco', 'drugs'])
on conflict (condition) do nothing;
