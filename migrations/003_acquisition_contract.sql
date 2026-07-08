insert into approved_sources (organization, country, source_type, base_domains, active) values
('Bangalore Adolescent Health Academy', 'India', 'organization', array['baha.org.in', 'bahedu.in'], true),
('Indian Academy of Pediatrics', 'India', 'organization', array['iapindia.org'], true),
('NIMHANS', 'India', 'organization', array['nimhans.ac.in'], true),
('NCERT', 'India', 'organization', array['ncert.nic.in'], true),
('CBSE', 'India', 'organization', array['cbse.gov.in'], true),
('Ministry of Health and Family Welfare', 'India', 'organization', array['mohfw.gov.in'], true),
('National Mental Health Programme', 'India', 'organization', array['mohfw.gov.in', 'nhm.gov.in'], true),
('NCPCR', 'India', 'organization', array['ncpcr.gov.in'], true),
('WHO', null, 'organization', array['who.int'], true),
('UNICEF', null, 'organization', array['unicef.org'], true),
('UNESCO', null, 'organization', array['unesco.org'], true),
('CDC', 'United States', 'organization', array['cdc.gov'], true),
('NIH', 'United States', 'organization', array['nih.gov', 'nimh.nih.gov', 'ncbi.nlm.nih.gov'], true),
('NHS', 'United Kingdom', 'organization', array['nhs.uk'], true),
('NICE', 'United Kingdom', 'organization', array['nice.org.uk'], true),
('American Academy of Pediatrics', 'United States', 'organization', array['aap.org'], true),
('SAMHSA', 'United States', 'organization', array['samhsa.gov'], true),
('PubMed', null, 'research', array['pubmed.ncbi.nlm.nih.gov', 'ncbi.nlm.nih.gov'], true),
('Europe PMC', null, 'research', array['europepmc.org'], true),
('Semantic Scholar', null, 'research', array['semanticscholar.org'], true)
on conflict (organization) do update set
  country = excluded.country,
  source_type = excluded.source_type,
  base_domains = excluded.base_domains,
  active = true;

create table if not exists crawl_logs (
  id uuid primary key default gen_random_uuid(),
  job_id uuid,
  organization text,
  url text,
  level text not null default 'info',
  message text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create or replace view discovered_urls as
select
  id,
  url,
  normalized_url,
  organization,
  source,
  title,
  author,
  publication_date_raw as publication_date,
  country,
  language,
  topic,
  subtopic,
  resource_type,
  content_type,
  metadata ->> 'license' as license,
  metadata -> 'keywords' as keywords,
  discovered_via,
  status,
  error,
  discovered_at,
  updated_at
from acquisition_candidates;

create or replace view downloaded_documents as
select
  id,
  url,
  normalized_url,
  organization,
  source,
  title,
  author,
  publication_date_raw as publication_date,
  country,
  language,
  topic,
  subtopic,
  resource_type,
  content_type,
  metadata ->> 'license' as license,
  metadata -> 'keywords' as keywords,
  storage_uri,
  content_hash,
  byte_size,
  etag,
  last_modified,
  version,
  downloaded_at,
  updated_at
from acquired_resources
where resource_type <> 'dataset';

create or replace view datasets as
select *
from acquired_resources
where resource_type = 'dataset';

create or replace view research_papers as
select *
from acquired_resources
where resource_type = 'research_paper'
   or organization in ('PubMed', 'Europe PMC', 'Semantic Scholar');

create or replace view metadata as
select
  id,
  title,
  author,
  organization,
  source,
  url,
  publication_date_raw as publication_date,
  country,
  language,
  topic,
  subtopic,
  resource_type,
  metadata ->> 'license' as license,
  metadata -> 'keywords' as keywords,
  metadata
from acquired_resources;

create or replace view crawl_jobs as
select *
from acquisition_jobs;

create or replace view review_queue as
select *
from clinical_review_queue;
