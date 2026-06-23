alter table priority_sources
  drop constraint if exists priority_sources_priority_rank_key;

alter table priority_sources
  add column if not exists source_weight numeric(4,3) not null default 0.700;

insert into priority_sources (
  organization, priority_rank, source_weight, is_baha_source, is_iap_source,
  manual_upload_enabled, active
) values
('Bangalore Adolescent Health Academy', 1, 1.000, true, false, true, true),
('IAP Adolescent Health Academy', 2, 0.950, false, true, true, true),
('Indian Academy of Pediatrics', 2, 0.950, false, true, true, true),
('NIMHANS', 3, 0.900, false, false, true, true),
('WHO', 4, 0.850, false, false, true, true),
('UNICEF', 5, 0.800, false, false, true, true),
('UNESCO', 5, 0.800, false, false, true, true),
('PubMed', 6, 0.750, false, false, false, true),
('Europe PMC', 6, 0.750, false, false, false, true),
('Semantic Scholar', 6, 0.750, false, false, false, true)
on conflict (organization) do update set
  priority_rank = excluded.priority_rank,
  source_weight = excluded.source_weight,
  is_baha_source = excluded.is_baha_source,
  is_iap_source = excluded.is_iap_source,
  manual_upload_enabled = excluded.manual_upload_enabled,
  active = true,
  updated_at = now();

insert into approved_sources (
  organization, country, source_type, base_domains, active
) values (
  'IAP Adolescent Health Academy',
  'India',
  'organization',
  array['aha.iapindia.org'],
  true
)
on conflict (organization) do update set
  country = excluded.country,
  source_type = excluded.source_type,
  base_domains = excluded.base_domains,
  active = true;

insert into acquisition_sources (
  organization, source_type, country, base_domains, seed_urls,
  rate_limit_seconds, robots_required, active
) values (
  'IAP Adolescent Health Academy',
  'organization',
  'India',
  array['aha.iapindia.org'],
  array[
    'https://aha.iapindia.org/',
    'https://aha.iapindia.org/MKU/',
    'https://aha.iapindia.org/AYA/',
    'https://aha.iapindia.org/knowledge-bank/',
    'https://aha.iapindia.org/resources-aha-webinars/',
    'https://aha.iapindia.org/t-teach-PPTs/',
    'https://aha.iapindia.org/t-teach-resource-material/',
    'https://aha.iapindia.org/other-manuals/',
    'https://aha.iapindia.org/Presentation/',
    'https://aha.iapindia.org/adolescon-today/',
    'https://aha.iapindia.org/indian-journal-of-adolescent-medicine/',
    'https://aha.iapindia.org/iap-consensus-guidelines/',
    'https://aha.iapindia.org/parents/',
    'https://aha.iapindia.org/adolescent/',
    'https://aha.iapindia.org/aha-module-for-teachers/',
    'https://aha.iapindia.org/drug-abuse/'
  ],
  1.5,
  true,
  true
)
on conflict (organization) do update set
  source_type = excluded.source_type,
  country = excluded.country,
  base_domains = excluded.base_domains,
  seed_urls = excluded.seed_urls,
  rate_limit_seconds = excluded.rate_limit_seconds,
  robots_required = true,
  active = true,
  updated_at = now();

update acquisition_sources
set seed_urls = array[
      'https://www.nimhans.ac.in/',
      'https://www.nimhans.ac.in/research',
      'https://www.nimhans.ac.in/projects',
      'https://www.nimhans.ac.in/publications/publications-list',
      'https://www.nimhans.ac.in/publications/posters',
      'https://www.nimhans.ac.in/publications/videos',
      'https://www.nimhans.ac.in/library/resources',
      'https://www.nimhans.ac.in/departments'
    ],
    base_domains = array['nimhans.ac.in', 'nimhansbkt.demo-appiness.com'],
    rate_limit_seconds = 1.5,
    robots_required = true,
    active = true,
    updated_at = now()
where organization = 'NIMHANS';

alter table acquired_resources
  add column if not exists source_weight numeric(4,3) not null default 0.700;

alter table documents
  add column if not exists source_weight numeric(4,3) not null default 0.700;

update acquired_resources r
set source_weight = p.source_weight,
    priority_rank = p.priority_rank
from priority_sources p
where p.organization = r.organization;

update documents d
set source_weight = p.source_weight
from priority_sources p
where p.organization = d.organization;

create table if not exists priority_acquisition_campaigns (
  id uuid primary key default gen_random_uuid(),
  campaign_name text not null,
  status text not null default 'running',
  organizations text[] not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  discovered_count integer not null default 0,
  downloaded_count integer not null default 0,
  accepted_count integer not null default 0,
  rejected_count integer not null default 0,
  error_count integer not null default 0,
  report jsonb not null default '{}'
);

create index if not exists acquired_resources_source_weight_idx
  on acquired_resources(source_weight desc, organization);
create index if not exists documents_source_weight_idx
  on documents(source_weight desc, organization);
create index if not exists priority_campaign_status_idx
  on priority_acquisition_campaigns(status, started_at desc);
