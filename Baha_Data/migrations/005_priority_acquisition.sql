create table if not exists priority_sources (
  organization text primary key,
  priority_rank integer not null unique check (priority_rank between 1 and 100),
  is_baha_source boolean not null default false,
  is_iap_source boolean not null default false,
  manual_upload_enabled boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into priority_sources (
  organization, priority_rank, is_baha_source, is_iap_source
) values
('Bangalore Adolescent Health Academy', 1, true, false),
('Indian Academy of Pediatrics', 2, false, true),
('NIMHANS', 3, false, false),
('WHO', 4, false, false),
('UNICEF', 5, false, false),
('UNESCO', 6, false, false)
on conflict (organization) do update set
  priority_rank = excluded.priority_rank,
  is_baha_source = excluded.is_baha_source,
  is_iap_source = excluded.is_iap_source,
  manual_upload_enabled = true,
  active = true,
  updated_at = now();

create table if not exists manual_ingestion_batches (
  id uuid primary key default gen_random_uuid(),
  organization text not null references priority_sources(organization),
  reviewer text not null,
  source text not null,
  status text not null default 'running',
  submitted_count integer not null default 0,
  imported_count integer not null default 0,
  duplicate_count integer not null default 0,
  rejected_count integer not null default 0,
  error_count integer not null default 0,
  metadata jsonb not null default '{}',
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create table if not exists manual_resource_ingestion (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references manual_ingestion_batches(id) on delete cascade,
  resource_id uuid references acquired_resources(id) on delete set null,
  parent_archive_id uuid references manual_resource_ingestion(id) on delete set null,
  organization text not null references priority_sources(organization),
  reviewer text not null,
  resource_type text not null,
  original_filename text not null,
  publication_date date,
  source text not null,
  topic text,
  audience text not null default 'general'
    check (audience in ('parent', 'teacher', 'counselor', 'adolescent', 'administrator', 'general')),
  content_hash text,
  storage_uri text,
  status text not null default 'pending',
  error text,
  is_baha_resource boolean not null default false,
  is_iap_resource boolean not null default false,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table acquired_resources
  add column if not exists reviewer text,
  add column if not exists audience text not null default 'general',
  add column if not exists priority_rank integer,
  add column if not exists is_baha_resource boolean not null default false,
  add column if not exists is_iap_resource boolean not null default false,
  add column if not exists ingestion_method text not null default 'automated';

create table if not exists priority_gap_targets (
  topic text primary key,
  minimum_documents integer not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into priority_gap_targets (topic, minimum_documents) values
('depression', 200),
('anxiety', 200),
('stress', 200),
('sleep', 200),
('bullying', 200),
('cyberbullying', 150),
('digital wellness', 200),
('self harm', 100),
('suicide prevention', 100)
on conflict (topic) do update set
  minimum_documents = excluded.minimum_documents,
  active = true,
  updated_at = now();

create table if not exists priority_gap_searches (
  id uuid primary key default gen_random_uuid(),
  topic text not null references priority_gap_targets(topic),
  organization text not null references priority_sources(organization),
  priority_rank integer not null,
  query text not null,
  search_url text,
  status text not null default 'planned',
  result_count integer not null default 0,
  run_key text not null,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique(topic, organization, query, run_key)
);

create table if not exists weekly_priority_gap_reports (
  id uuid primary key default gen_random_uuid(),
  week_start date not null,
  report jsonb not null,
  created_at timestamptz not null default now(),
  unique(week_start)
);

create index if not exists manual_ingestion_batch_idx
  on manual_resource_ingestion(batch_id, status);
create index if not exists manual_ingestion_org_topic_idx
  on manual_resource_ingestion(organization, topic, audience);
create index if not exists acquired_resources_priority_idx
  on acquired_resources(priority_rank, organization, topic);
create index if not exists acquired_resources_audience_idx
  on acquired_resources(audience, organization);
create index if not exists priority_gap_searches_status_idx
  on priority_gap_searches(status, priority_rank, topic);

update acquired_resources r
set priority_rank = p.priority_rank,
    is_baha_resource = p.is_baha_source,
    is_iap_resource = p.is_iap_source,
    audience = case
      when coalesce(r.extracted_metadata ->> 'audience', r.metadata ->> 'audience')
        in ('parent', 'teacher', 'counselor', 'adolescent', 'administrator', 'general')
      then coalesce(r.extracted_metadata ->> 'audience', r.metadata ->> 'audience')
      else r.audience
    end
from priority_sources p
where p.organization = r.organization;

create or replace view baha_iap_coverage as
select
  organization,
  topic,
  audience,
  count(*) as resource_count,
  count(*) filter (where resource_type = 'pdf') as pdf_count,
  max(downloaded_at) as latest_resource_at
from acquired_resources
where (is_baha_resource or is_iap_resource)
  and quality_status <> 'rejected'
group by organization, topic, audience;
