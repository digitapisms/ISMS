-- =============================================================
-- AUTHENTICATION & ROLE MANAGEMENT SCHEMA
-- =============================================================

-- 1. Ensure users table has required metadata
alter table if exists users
  add column if not exists auth_id uuid unique,
  add column if not exists role text not null default 'applicant',
  add column if not exists status text not null default 'active',
  add column if not exists school_id uuid references schools(id) on delete cascade,
  add column if not exists last_login_at timestamptz,
  add column if not exists invited_by uuid references users(id) on delete set null,
  add column if not exists invited_at timestamptz;

create index if not exists idx_users_auth_id on users(auth_id);
create index if not exists idx_users_school_id on users(school_id);
create index if not exists idx_users_role on users(role);
create index if not exists idx_users_status on users(status);

-- 2. User roles directory
create table if not exists user_roles (
  role_key text primary key,
  display_name text not null,
  priority integer not null,
  is_staff boolean not null default false,
  is_student boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into user_roles (role_key, display_name, priority, is_staff, is_student) values
  ('super_admin', 'Super Admin', 100, true, false),
  ('admin', 'Admin', 90, true, false),
  ('principal', 'Principal', 80, true, false),
  ('teacher', 'Teacher', 70, true, false),
  ('staff', 'Staff', 60, true, false),
  ('student', 'Student', 20, false, true),
  ('parent', 'Parent', 10, false, false),
  ('applicant', 'Applicant', 0, false, false)
on conflict (role_key) do update set
  display_name = excluded.display_name,
  priority = excluded.priority,
  is_staff = excluded.is_staff,
  is_student = excluded.is_student,
  updated_at = now();

-- 3. Optional role permissions (feature keys)
create table if not exists role_permissions (
  role_key text references user_roles(role_key) on delete cascade,
  feature_key text not null,
  constraint role_permissions_pk primary key (role_key, feature_key)
);

insert into role_permissions (role_key, feature_key) values
  ('super_admin', 'tenants.manage'),
  ('super_admin', 'plans.manage'),
  ('admin', 'staff.manage'),
  ('admin', 'students.manage'),
  ('teacher', 'attendance.record'),
  ('teacher', 'homework.review'),
  ('parent', 'student.portal'),
  ('student', 'student.portal')
on conflict do nothing;

-- 4. Helper functions
drop function if exists current_user_school_id();
create or replace function current_user_school_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select users.school_id
  from users
  where users.auth_id = auth.uid()
  limit 1;
$$;

drop function if exists current_user_role();
create or replace function current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select users.role::text
  from users
  where users.auth_id = auth.uid()
  limit 1;
$$;

drop function if exists has_permission(text);
create or replace function has_permission(p_feature_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from role_permissions rp
    where rp.role_key = current_user_role()
      and rp.feature_key = p_feature_key
  );
$$;

-- 5. Row level security for users table
alter table users enable row level security;

drop policy if exists users_select_policy on users;
create policy users_select_policy
on users
for select
to authenticated
using (
  role = 'super_admin'
  or school_id = current_user_school_id()
  or auth_id = auth.uid()
);

drop policy if exists users_insert_policy on users;
create policy users_insert_policy
on users
for insert
to authenticated
with check (
  role = 'super_admin'
  or school_id = current_user_school_id()
);

drop policy if exists users_update_policy on users;
create policy users_update_policy
on users
for update
to authenticated
using (
  role = 'super_admin'
  or school_id = current_user_school_id()
  or auth_id = auth.uid()
) with check (
  role = 'super_admin'
  or school_id = current_user_school_id()
  or auth_id = auth.uid()
);

-- 6. Audit trigger for last_login_at
drop function if exists mark_last_login();
create or replace function mark_last_login()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update users
  set last_login_at = now()
  where auth_id = auth.uid();
  return new;
end;
$$;
-- This trigger is invoked from Supabase auth hooks (edge function) if desired.

