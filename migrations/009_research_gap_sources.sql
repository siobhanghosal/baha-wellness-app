insert into priority_sources (
  organization, priority_rank, source_weight, is_baha_source, is_iap_source,
  manual_upload_enabled, active
) values
('Europe PMC', 6, 0.750, false, false, false, true),
('Semantic Scholar', 6, 0.750, false, false, false, true)
on conflict (organization) do update set
  priority_rank = excluded.priority_rank,
  source_weight = excluded.source_weight,
  active = true,
  updated_at = now();
