-- STAFF MANAGEMENT SCHEMA
-- Provides tables and helpers for managing staff invitations and statuses

-- 1. Ensure users table has status metadata
alter table if exists users
  add column if not exists status text not null default 'active',
  add column if not exists last_login_at timestamptz;

create index if not exists idx_users_status on users(status);
create index if not exists idx_users_role on users(role);

-- 2. Create staff_invites table
create table if not exists staff_invites (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'staff',
  invite_code text not null unique,
  status text not null default 'pending',
  invited_by uuid references users(id) on delete set null,
  notes text,
  expires_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_staff_invites_school on staff_invites(school_id);
create index if not exists idx_staff_invites_status on staff_invites(status);
create index if not exists idx_staff_invites_email on staff_invites(email);
create index if not exists idx_staff_invites_code on staff_invites(invite_code);

drop trigger if exists update_staff_invites_updated_at on staff_invites;
create trigger update_staff_invites_updated_at
before update on staff_invites
for each row
execute function update_updated_at_column();

alter table staff_invites enable row level security;

-- Allow school administrators to manage invites
drop policy if exists staff_invites_select_admin on staff_invites;
create policy staff_invites_select_admin
on staff_invites for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid() and role in ('admin','principal')
  )
);

drop policy if exists staff_invites_insert_admin on staff_invites;
create policy staff_invites_insert_admin
on staff_invites for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid() and role in ('admin','principal')
  )
);

drop policy if exists staff_invites_update_admin on staff_invites;
create policy staff_invites_update_admin
on staff_invites for update to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid() and role in ('admin','principal')
  )
)
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid() and role in ('admin','principal')
  )
);

-- 3. Helper functions for invite validation and consumption
create or replace function validate_staff_invite(
  p_invite_code text,
  p_email text
)
returns table(
  invite_id uuid,
  school_id uuid,
  school_name text,
  role text,
  full_name text,
  email text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select i.id,
         i.school_id,
         s.name as school_name,
         i.role,
         i.full_name,
         i.email,
         i.expires_at
  from staff_invites i
  join schools s on s.id = i.school_id
  where upper(i.invite_code) = upper(p_invite_code)
    and lower(i.email) = lower(p_email)
    and i.status = 'pending'
    and (i.expires_at is null or i.expires_at > now());
end;
$$;

grant execute on function validate_staff_invite(text,text) to anon, authenticated;

create or replace function consume_staff_invite(
  p_invite_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update staff_invites
  set status = 'accepted',
      accepted_at = now()
  where upper(invite_code) = upper(p_invite_code)
    and status = 'pending';
end;
$$;

grant execute on function consume_staff_invite(text) to anon, authenticated;
