alter table acquired_resources
  add column if not exists is_aha_resource boolean not null default false,
  add column if not exists is_nimhans_resource boolean not null default false,
  add column if not exists priority_score numeric(4,3) not null default 0.700;

update acquired_resources
set is_aha_resource = organization = 'IAP Adolescent Health Academy',
    is_nimhans_resource = organization = 'NIMHANS',
    priority_score = source_weight;

create index if not exists acquired_resources_aha_idx
  on acquired_resources(is_aha_resource)
  where is_aha_resource;

create index if not exists acquired_resources_nimhans_idx
  on acquired_resources(is_nimhans_resource)
  where is_nimhans_resource;
