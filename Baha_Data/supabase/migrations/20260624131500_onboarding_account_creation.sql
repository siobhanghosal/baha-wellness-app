alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('student', 'parent', 'teacher', 'counselor', 'admin', 'platform_admin', 'school_admin'));

alter table public.profiles
  add column if not exists mobile_number text,
  add column if not exists gender text,
  add column if not exists grade_label text,
  add column if not exists employee_id text,
  add column if not exists department text,
  add column if not exists designation text,
  add column if not exists professional_license_number text,
  add column if not exists organization_name text,
  add column if not exists approval_status text not null default 'not_required',
  add column if not exists consent_status text not null default 'not_required',
  add constraint profiles_gender_check
    check (gender is null or gender in ('male', 'female', 'universal', 'prefer_not_to_say')),
  add constraint profiles_approval_status_check
    check (approval_status in ('not_required', 'pending', 'approved', 'rejected', 'revoked')),
  add constraint profiles_consent_status_check
    check (consent_status in ('not_required', 'pending', 'approved', 'revoked'));

alter table public.audit_logs
  drop constraint if exists audit_logs_event_type_check;

alter table public.audit_logs
  add constraint audit_logs_event_type_check
  check (event_type in (
    'login',
    'logout',
    'password_reset',
    'profile_update',
    'role_change',
    'signup',
    'mfa_enrolled',
    'mfa_removed',
    'consent_update',
    'approval_update',
    'child_linked'
  ));

create table if not exists public.parents (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  school_id uuid references public.schools(id) on delete set null,
  mobile_number text,
  relationship_to_student text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.school_admins (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  school_id uuid references public.schools(id) on delete cascade,
  designation text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role text not null,
  school_id uuid references public.schools(id) on delete set null,
  request_type text not null,
  status text not null default 'pending',
  requested_metadata jsonb not null default '{}'::jsonb,
  reviewer_user_id uuid references public.profiles(user_id) on delete set null,
  reviewer_notes text,
  requested_at timestamptz not null default timezone('utc', now()),
  reviewed_at timestamptz,
  check (role in ('teacher', 'counselor', 'school_admin')),
  check (status in ('pending', 'approved', 'rejected', 'revoked'))
);

create unique index if not exists approval_requests_pending_unique_idx
  on public.approval_requests(user_id, request_type)
  where status = 'pending';

create index if not exists profiles_approval_status_idx on public.profiles(approval_status, role);
create index if not exists profiles_consent_status_idx on public.profiles(consent_status, role);
create index if not exists parents_school_idx on public.parents(school_id);
create index if not exists school_admins_school_idx on public.school_admins(school_id);
create index if not exists approval_requests_school_status_idx on public.approval_requests(school_id, status, requested_at desc);

create trigger parents_set_updated_at
  before update on public.parents
  for each row execute procedure public.set_updated_at();

create trigger school_admins_set_updated_at
  before update on public.school_admins
  for each row execute procedure public.set_updated_at();

drop view if exists public.guardian_student_links;

create view public.guardian_student_links as
select
  guardian_user_id,
  student_user_id,
  relationship_to_student,
  is_primary,
  consent_authority,
  status,
  created_at,
  updated_at
from public.student_guardian_links;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    left join public.admins a on a.user_id = p.user_id
    where p.user_id = auth.uid()
      and (
        p.role = 'platform_admin'
        or (p.role = 'admin' and coalesce(a.admin_scope, 'platform') = 'platform')
      )
  );
$$;

create or replace function public.ensure_role_shadow_records(profile_row public.profiles)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if profile_row.role = 'student' and profile_row.school_id is not null then
    insert into public.students (user_id, school_id, grade_label, consent_status)
    values (
      profile_row.user_id,
      profile_row.school_id,
      profile_row.grade_label,
      case when profile_row.age_group = '17-19' then 'self_consent' else 'minor_guardian_required' end
    )
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      grade_label = excluded.grade_label,
      consent_status = excluded.consent_status,
      updated_at = timezone('utc', now());
  elsif profile_row.role = 'parent' then
    insert into public.guardians (user_id, school_id)
    values (profile_row.user_id, profile_row.school_id)
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      updated_at = timezone('utc', now());

    insert into public.parents (user_id, school_id, mobile_number)
    values (profile_row.user_id, profile_row.school_id, profile_row.mobile_number)
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      mobile_number = excluded.mobile_number,
      updated_at = timezone('utc', now());
  elsif profile_row.role = 'teacher' and profile_row.school_id is not null then
    insert into public.teachers (user_id, school_id, employee_code)
    values (profile_row.user_id, profile_row.school_id, profile_row.employee_id)
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      employee_code = excluded.employee_code,
      updated_at = timezone('utc', now());
  elsif profile_row.role = 'counselor' and profile_row.school_id is not null then
    insert into public.counselors (user_id, school_id, employee_code)
    values (profile_row.user_id, profile_row.school_id, profile_row.professional_license_number)
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      employee_code = excluded.employee_code,
      updated_at = timezone('utc', now());
  elsif profile_row.role in ('admin', 'platform_admin', 'school_admin') then
    insert into public.admins (user_id, school_id, admin_scope)
    values (
      profile_row.user_id,
      profile_row.school_id,
      case when profile_row.role = 'school_admin' then 'school' else 'platform' end
    )
    on conflict (user_id) do update set
      school_id = excluded.school_id,
      admin_scope = excluded.admin_scope,
      updated_at = timezone('utc', now());

    if profile_row.role = 'school_admin' then
      insert into public.school_admins (user_id, school_id, designation)
      values (profile_row.user_id, profile_row.school_id, profile_row.designation)
      on conflict (user_id) do update set
        school_id = excluded.school_id,
        designation = excluded.designation,
        updated_at = timezone('utc', now());
    end if;
  end if;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
  requested_age_group text;
  requested_school_id uuid;
  requested_school_name text;
  inferred_name text;
  approval_state text;
  consent_state text;
  inserted_profile public.profiles;
begin
  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'role', 'student'));
  if requested_role not in ('student', 'parent', 'teacher', 'counselor', 'admin', 'platform_admin', 'school_admin') then
    requested_role := 'student';
  end if;

  requested_age_group := coalesce(new.raw_user_meta_data ->> 'age_group', null);
  if requested_age_group not in ('9-12', '13-16', '17-19') then
    requested_age_group := null;
  end if;

  begin
    requested_school_id := nullif(new.raw_user_meta_data ->> 'school_id', '')::uuid;
  exception when others then
    requested_school_id := null;
  end;

  requested_school_name := nullif(new.raw_user_meta_data ->> 'school_name', '');
  if requested_school_id is null and requested_school_name is not null then
    select id into requested_school_id
    from public.schools
    where lower(school_name) = lower(requested_school_name)
    limit 1;

    if requested_school_id is null then
      insert into public.schools (school_name, contact_email, subscription_tier)
      values (requested_school_name, coalesce(new.email, requested_school_name || '@pending.baha.local'), 'starter')
      on conflict do nothing;

      select id into requested_school_id
      from public.schools
      where lower(school_name) = lower(requested_school_name)
      limit 1;
    end if;
  end if;

  inferred_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(coalesce(new.email, 'user'), '@', 1)
  );

  approval_state := case
    when requested_role in ('teacher', 'counselor', 'school_admin') then 'pending'
    else 'not_required'
  end;
  consent_state := case
    when requested_role = 'student' and requested_age_group in ('9-12', '13-16') then 'pending'
    else 'not_required'
  end;

  insert into public.profiles (
    user_id,
    full_name,
    email,
    role,
    age_group,
    school_id,
    avatar_url,
    email_verified_at,
    mobile_number,
    gender,
    grade_label,
    employee_id,
    department,
    designation,
    professional_license_number,
    organization_name,
    approval_status,
    consent_status
  ) values (
    new.id,
    inferred_name,
    coalesce(new.email, ''),
    requested_role,
    requested_age_group,
    requested_school_id,
    new.raw_user_meta_data ->> 'avatar_url',
    new.email_confirmed_at,
    new.raw_user_meta_data ->> 'mobile_number',
    new.raw_user_meta_data ->> 'gender',
    new.raw_user_meta_data ->> 'grade',
    new.raw_user_meta_data ->> 'employee_id',
    new.raw_user_meta_data ->> 'department',
    new.raw_user_meta_data ->> 'designation',
    new.raw_user_meta_data ->> 'license_number',
    new.raw_user_meta_data ->> 'organization',
    approval_state,
    consent_state
  )
  on conflict (user_id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    role = excluded.role,
    age_group = excluded.age_group,
    school_id = excluded.school_id,
    avatar_url = excluded.avatar_url,
    email_verified_at = excluded.email_verified_at,
    mobile_number = excluded.mobile_number,
    gender = excluded.gender,
    grade_label = excluded.grade_label,
    employee_id = excluded.employee_id,
    department = excluded.department,
    designation = excluded.designation,
    professional_license_number = excluded.professional_license_number,
    organization_name = excluded.organization_name,
    approval_status = excluded.approval_status,
    consent_status = excluded.consent_status,
    updated_at = timezone('utc', now())
  returning * into inserted_profile;

  perform public.ensure_role_shadow_records(inserted_profile);

  if requested_role in ('teacher', 'counselor', 'school_admin') then
    insert into public.approval_requests (user_id, role, school_id, request_type, requested_metadata)
    values (
      new.id,
      requested_role,
      requested_school_id,
      requested_role || '_signup',
      coalesce(new.raw_user_meta_data, '{}'::jsonb)
    )
    on conflict (user_id, request_type) where status = 'pending'
    do update set
      school_id = excluded.school_id,
      requested_metadata = excluded.requested_metadata,
      requested_at = timezone('utc', now());
  end if;

  insert into public.audit_logs (actor_user_id, school_id, event_type, metadata)
  values (new.id, inserted_profile.school_id, 'signup', jsonb_build_object('email', new.email, 'role', inserted_profile.role));

  return new;
end;
$$;

alter table public.parents enable row level security;
alter table public.school_admins enable row level security;
alter table public.approval_requests enable row level security;

create policy "parents_read_self_or_admin" on public.parents
for select to authenticated
using (
  user_id = auth.uid()
  or public.is_platform_admin()
  or public.is_school_admin(school_id)
);

create policy "parents_write_self_or_admin" on public.parents
for all to authenticated
using (
  user_id = auth.uid()
  or public.is_platform_admin()
  or public.is_school_admin(school_id)
)
with check (
  user_id = auth.uid()
  or public.is_platform_admin()
  or public.is_school_admin(school_id)
);

create policy "school_admins_read_self_or_platform" on public.school_admins
for select to authenticated
using (user_id = auth.uid() or public.is_platform_admin());

create policy "school_admins_write_platform_only" on public.school_admins
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "approval_requests_read_scoped" on public.approval_requests
for select to authenticated
using (
  user_id = auth.uid()
  or public.is_platform_admin()
  or public.is_school_admin(school_id)
);

create policy "approval_requests_insert_self" on public.approval_requests
for insert to authenticated
with check (user_id = auth.uid() or public.is_platform_admin() or public.is_school_admin(school_id));

create policy "approval_requests_update_reviewers" on public.approval_requests
for update to authenticated
using (public.is_platform_admin() or public.is_school_admin(school_id))
with check (public.is_platform_admin() or public.is_school_admin(school_id));
