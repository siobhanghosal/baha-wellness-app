create table if not exists approval_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  requested_role text not null check (
    requested_role in ('teacher', 'counselor', 'administrator')
  ),
  school_id uuid references schools(id) on delete set null,
  request_type text not null default 'account_activation' check (
    request_type in ('account_activation')
  ),
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected', 'revoked')
  ),
  requested_metadata jsonb not null default '{}',
  reviewer_user_id uuid references users(id) on delete set null,
  reviewer_notes text,
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists approval_requests_pending_unique_idx
  on approval_requests(user_id, requested_role, request_type)
  where status = 'pending';

create index if not exists approval_requests_status_idx
  on approval_requests(status, requested_role, requested_at desc);

create index if not exists approval_requests_school_idx
  on approval_requests(school_id, status, requested_at desc);

create index if not exists users_lower_email_idx
  on users(lower(email));
