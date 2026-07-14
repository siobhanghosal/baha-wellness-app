insert into approved_sources (
  organization, country, source_type, base_domains, active
) values
('CASEL', 'United States', 'organization', array['casel.org'], true),
('Common Sense Media', 'United States', 'organization',
  array['commonsensemedia.org', 'commonsense.org'], true),
('Internet Matters', 'United Kingdom', 'organization',
  array['internetmatters.org'], true),
('eSafety Commissioner', 'Australia', 'organization',
  array['esafety.gov.au'], true),
('Attendance Works', 'United States', 'organization',
  array['attendanceworks.org'], true),
('Education Endowment Foundation', 'United Kingdom', 'organization',
  array['educationendowmentfoundation.org.uk'], true),
('National Center for School Mental Health', 'United States', 'organization',
  array['schoolmentalhealth.org'], true),
('American School Counselor Association', 'United States', 'organization',
  array['schoolcounselor.org'], true),
('National Association of School Psychologists', 'United States', 'organization',
  array['nasponline.org'], true),
('OECD', null, 'organization', array['oecd.org'], true),
('World Economic Forum', null, 'organization', array['weforum.org'], true),
('SCERT Karnataka', 'India', 'organization',
  array['scert.karnataka.gov.in'], true),
('National Institute of Open Schooling', 'India', 'organization',
  array['nios.ac.in'], true)
on conflict (organization) do update set
  country = excluded.country,
  source_type = excluded.source_type,
  base_domains = excluded.base_domains,
  active = true;

insert into priority_sources (
  organization, priority_rank, source_weight, is_baha_source, is_iap_source,
  manual_upload_enabled, active
) values
('CASEL', 8, 0.800, false, false, false, true),
('Common Sense Media', 8, 0.800, false, false, false, true),
('Internet Matters', 8, 0.780, false, false, false, true),
('eSafety Commissioner', 8, 0.800, false, false, false, true),
('Attendance Works', 8, 0.780, false, false, false, true),
('Education Endowment Foundation', 8, 0.800, false, false, false, true),
('National Center for School Mental Health', 8, 0.800, false, false, false, true),
('American School Counselor Association', 8, 0.780, false, false, false, true),
('National Association of School Psychologists', 8, 0.800, false, false, false, true),
('OECD', 8, 0.800, false, false, false, true),
('World Economic Forum', 8, 0.750, false, false, false, true),
('SCERT Karnataka', 8, 0.800, false, false, false, true),
('National Institute of Open Schooling', 8, 0.800, false, false, false, true)
on conflict (organization) do update set
  priority_rank = excluded.priority_rank,
  source_weight = excluded.source_weight,
  active = true,
  updated_at = now();

insert into topic_targets (topic, minimum_documents, priority) values
('digital wellness', 200, 1),
('bullying', 200, 1),
('cyberbullying', 150, 1),
('screen time', 75, 1),
('school refusal', 75, 1),
('school avoidance', 75, 1),
('communication skills', 50, 1),
('decision making', 50, 1),
('emotional intelligence', 50, 1),
('problem solving', 50, 1),
('resilience', 50, 1),
('self awareness', 50, 1),
('peer pressure', 75, 2),
('risk taking', 75, 2),
('performance anxiety', 75, 2)
on conflict (topic) do update set
  minimum_documents = excluded.minimum_documents,
  priority = excluded.priority,
  updated_at = now();

create table if not exists life_skills_campaign_reports (
  id uuid primary key default gen_random_uuid(),
  report_date date not null default current_date,
  report jsonb not null,
  created_at timestamptz not null default now(),
  unique(report_date)
);

create index if not exists acquired_resources_skills_gin_idx
  on acquired_resources using gin ((extracted_metadata -> 'skills'));

insert into retrieval_evaluation_queries (
  perspective, query, expected_topics
) values
('parent', 'My child spends too much time on screens', array['screen time', 'digital wellness']),
('parent', 'How can I build resilience in teenagers?', array['resilience']),
('teacher', 'How can I reduce bullying in my classroom?', array['bullying']),
('teacher', 'How do I identify school refusal?', array['school refusal', 'school avoidance']),
('counselor', 'How do I intervene in cyberbullying?', array['cyberbullying']),
('counselor', 'How do I support emotional intelligence development?', array['emotional intelligence']),
('adolescent', 'How can I improve decision making?', array['decision making']),
('adolescent', 'How can I handle peer pressure?', array['peer pressure'])
on conflict (query) do update set
  perspective = excluded.perspective,
  expected_topics = excluded.expected_topics,
  active = true;
