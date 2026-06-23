create table if not exists topic_targets (
  topic text primary key,
  minimum_documents integer not null,
  priority integer not null default 3,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists topic_coverage (
  topic text primary key,
  document_count integer not null default 0,
  pdf_count integer not null default 0,
  research_count integer not null default 0,
  target_count integer not null default 0,
  gap_count integer not null default 0,
  target_met boolean not null default false,
  last_updated timestamptz not null default now()
);

create table if not exists knowledge_graph_nodes (
  id uuid primary key default gen_random_uuid(),
  node_type text not null,
  label text not null,
  normalized_label text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(node_type, normalized_label)
);

create table if not exists knowledge_graph_edges (
  id uuid primary key default gen_random_uuid(),
  source_node_id uuid not null references knowledge_graph_nodes(id) on delete cascade,
  target_node_id uuid not null references knowledge_graph_nodes(id) on delete cascade,
  relationship text not null,
  evidence_resource_id uuid references acquired_resources(id) on delete set null,
  confidence numeric not null default 0.5,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique(source_node_id, target_node_id, relationship, evidence_resource_id)
);

create table if not exists retrieval_evaluation_queries (
  id uuid primary key default gen_random_uuid(),
  perspective text not null,
  query text not null unique,
  expected_topics text[] not null default '{}',
  expected_evidence_level text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists retrieval_evaluation_runs (
  id uuid primary key default gen_random_uuid(),
  query_id uuid not null references retrieval_evaluation_queries(id) on delete cascade,
  recall numeric,
  citation_quality numeric,
  coverage numeric,
  confidence numeric,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists daily_acquisition_reports (
  id uuid primary key default gen_random_uuid(),
  report_date date not null default current_date,
  report jsonb not null,
  created_at timestamptz not null default now(),
  unique(report_date)
);

create table if not exists embedding_readiness_checks (
  id uuid primary key default gen_random_uuid(),
  documents_count integer not null,
  research_papers_count integer not null,
  unmet_topics text[] not null default '{}',
  ready boolean not null,
  checked_at timestamptz not null default now()
);

create table if not exists condition_profile_targets (
  condition text primary key,
  required boolean not null default true,
  profile_exists boolean not null default false,
  last_updated timestamptz not null default now()
);

alter table acquired_resources
  add column if not exists quality_status text not null default 'unchecked',
  add column if not exists quality_errors text[] not null default '{}',
  add column if not exists extracted_metadata jsonb not null default '{}',
  add column if not exists superseded_by uuid references acquired_resources(id) on delete set null;

create index if not exists topic_coverage_gap_idx on topic_coverage(target_met, gap_count desc);
create index if not exists kg_nodes_type_label_idx on knowledge_graph_nodes(node_type, normalized_label);
create index if not exists kg_edges_relationship_idx on knowledge_graph_edges(relationship);
create index if not exists acquired_resources_quality_idx on acquired_resources(quality_status);

insert into topic_targets (topic, minimum_documents, priority) values
('depression', 200, 1),
('anxiety', 200, 1),
('stress', 200, 1),
('bullying', 200, 1),
('cyberbullying', 150, 1),
('sleep', 200, 1),
('digital wellness', 200, 1),
('nutrition', 150, 1),
('physical activity', 150, 1),
('adhd', 100, 1),
('autism', 100, 1),
('self harm', 100, 1),
('suicide prevention', 100, 1),
('burnout', 75, 2),
('loneliness', 75, 2),
('grief', 75, 2),
('emotional regulation', 75, 2),
('exam stress', 75, 2),
('school avoidance', 75, 2),
('school refusal', 75, 2),
('performance anxiety', 75, 2),
('peer pressure', 75, 2),
('social isolation', 75, 2),
('friendship issues', 75, 2),
('aggression', 75, 2),
('anger', 75, 2),
('risk taking', 75, 2),
('learning difficulties', 75, 2),
('screen time', 75, 2),
('gaming addiction', 75, 2),
('internet addiction', 75, 2),
('substance abuse', 100, 1),
('vaping', 75, 2),
('alcohol abuse', 75, 2),
('decision making', 50, 3),
('communication skills', 50, 3),
('emotional intelligence', 50, 3),
('self awareness', 50, 3),
('resilience', 50, 3),
('problem solving', 50, 3)
on conflict (topic) do update set
  minimum_documents = excluded.minimum_documents,
  priority = excluded.priority,
  updated_at = now();

insert into retrieval_evaluation_queries (perspective, query, expected_topics) values
('parent', 'How do I identify anxiety in my child?', array['anxiety']),
('parent', 'Signs of depression in a teenager?', array['depression']),
('parent', 'What should I do if my child is being bullied?', array['bullying']),
('teacher', 'How do I identify burnout in students?', array['burnout']),
('teacher', 'Warning signs of cyberbullying?', array['cyberbullying']),
('teacher', 'Classroom interventions for stress?', array['stress']),
('counselor', 'Escalation indicators', array['self harm', 'suicide prevention']),
('counselor', 'Risk factors', array['depression', 'anxiety']),
('counselor', 'Referral guidance', array['self harm', 'suicide prevention'])
on conflict (query) do nothing;

insert into condition_profile_targets (condition) values
('Depression'),
('Anxiety'),
('Stress'),
('Burnout'),
('Loneliness'),
('Grief'),
('Bullying'),
('Cyberbullying'),
('Peer Pressure'),
('Social Isolation'),
('ADHD'),
('Autism'),
('Learning Difficulties'),
('Sleep Disorders'),
('Gaming Addiction'),
('Internet Addiction'),
('Substance Abuse'),
('Self Harm'),
('Suicide Risk'),
('Exam Stress'),
('School Avoidance'),
('Performance Anxiety'),
('Anger'),
('Risk Taking')
on conflict (condition) do nothing;
