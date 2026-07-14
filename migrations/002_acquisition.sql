create table if not exists acquisition_sources (
  id uuid primary key default gen_random_uuid(),
  organization text not null unique,
  source_type text not null,
  country text,
  base_domains text[] not null default '{}',
  seed_urls text[] not null default '{}',
  rate_limit_seconds numeric not null default 1.0,
  robots_required boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists acquisition_candidates (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  normalized_url text not null unique,
  organization text not null,
  source text not null,
  title text,
  author text,
  publication_date_raw text,
  country text,
  language text not null default 'en',
  topic text,
  subtopic text,
  resource_type text not null default 'html',
  content_type text,
  discovered_via text not null,
  metadata jsonb not null default '{}',
  status text not null default 'discovered',
  error text,
  discovered_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists acquired_resources (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  normalized_url text not null unique,
  organization text not null,
  source text not null,
  title text,
  author text,
  publication_date_raw text,
  country text,
  language text not null default 'en',
  topic text,
  subtopic text,
  resource_type text not null,
  content_type text,
  storage_uri text not null,
  content_hash text not null,
  byte_size bigint not null,
  etag text,
  last_modified text,
  metadata jsonb not null default '{}',
  version integer not null default 1,
  downloaded_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists resource_duplicates (
  id uuid primary key default gen_random_uuid(),
  canonical_resource_id uuid not null references acquired_resources(id) on delete cascade,
  duplicate_resource_id uuid not null references acquired_resources(id) on delete cascade,
  duplicate_type text not null,
  score numeric not null default 1.0,
  created_at timestamptz not null default now(),
  unique(canonical_resource_id, duplicate_resource_id)
);

create table if not exists acquisition_jobs (
  id uuid primary key default gen_random_uuid(),
  job_type text not null,
  status text not null default 'pending',
  payload jsonb not null default '{}',
  discovered_count integer not null default 0,
  downloaded_count integer not null default 0,
  error_count integer not null default 0,
  error text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists clinical_review_queue (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null unique references acquired_resources(id) on delete cascade,
  status text not null default 'pending',
  priority integer not null default 3,
  reason text,
  reviewer text,
  notes text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists acquisition_candidates_org_idx on acquisition_candidates(organization);
create index if not exists acquisition_candidates_status_idx on acquisition_candidates(status, discovered_at);
create index if not exists acquisition_candidates_topic_idx on acquisition_candidates(topic);
create index if not exists acquisition_candidates_metadata_gin_idx on acquisition_candidates using gin(metadata);
create index if not exists acquired_resources_org_idx on acquired_resources(organization);
create index if not exists acquired_resources_topic_idx on acquired_resources(topic);
create index if not exists acquired_resources_hash_idx on acquired_resources(content_hash);
create index if not exists acquired_resources_metadata_gin_idx on acquired_resources using gin(metadata);
create index if not exists clinical_review_queue_status_idx on clinical_review_queue(status, priority, created_at);
create index if not exists acquisition_jobs_status_idx on acquisition_jobs(status, job_type, created_at);

insert into acquisition_sources (
  organization, source_type, country, base_domains, seed_urls, rate_limit_seconds, robots_required, active
) values
('WHO', 'organization', null, array['who.int'], array['https://www.who.int/'], 1.0, true, true),
('UNICEF', 'organization', null, array['unicef.org'], array['https://www.unicef.org/'], 1.0, true, true),
('UNESCO', 'organization', null, array['unesco.org'], array['https://www.unesco.org/'], 1.0, true, true),
('NIMHANS', 'organization', 'India', array['nimhans.ac.in'], array['https://nimhans.ac.in/'], 1.0, true, true),
('Indian Academy of Pediatrics', 'organization', 'India', array['iapindia.org'], array['https://iapindia.org/'], 1.0, true, true),
('NCERT', 'organization', 'India', array['ncert.nic.in'], array['https://ncert.nic.in/'], 1.0, true, true),
('CBSE', 'organization', 'India', array['cbse.gov.in'], array['https://www.cbse.gov.in/'], 1.0, true, true),
('NCPCR', 'organization', 'India', array['ncpcr.gov.in'], array['https://ncpcr.gov.in/'], 1.0, true, true),
('Ministry of Health and Family Welfare', 'organization', 'India', array['mohfw.gov.in'], array['https://www.mohfw.gov.in/'], 1.0, true, true),
('NICE', 'organization', 'United Kingdom', array['nice.org.uk'], array['https://www.nice.org.uk/'], 1.0, true, true),
('NHS', 'organization', 'United Kingdom', array['nhs.uk'], array['https://www.nhs.uk/'], 1.0, true, true),
('CDC', 'organization', 'United States', array['cdc.gov'], array['https://www.cdc.gov/'], 1.0, true, true),
('SAMHSA', 'organization', 'United States', array['samhsa.gov'], array['https://www.samhsa.gov/'], 1.0, true, true),
('American Academy of Pediatrics', 'organization', 'United States', array['aap.org'], array['https://www.aap.org/'], 1.0, true, true),
('PubMed', 'research', null, array['pubmed.ncbi.nlm.nih.gov', 'ncbi.nlm.nih.gov'], array['https://pubmed.ncbi.nlm.nih.gov/'], 1.0, true, true),
('Europe PMC', 'research', null, array['europepmc.org'], array['https://europepmc.org/'], 1.0, true, true),
('Semantic Scholar', 'research', null, array['semanticscholar.org'], array['https://www.semanticscholar.org/'], 1.0, true, true)
on conflict (organization) do update set
  source_type = excluded.source_type,
  country = excluded.country,
  base_domains = excluded.base_domains,
  seed_urls = excluded.seed_urls,
  rate_limit_seconds = excluded.rate_limit_seconds,
  robots_required = excluded.robots_required,
  active = true,
  updated_at = now();
