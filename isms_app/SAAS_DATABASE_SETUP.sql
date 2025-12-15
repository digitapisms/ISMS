-- =========================================================
-- SAAS MULTI-TENANT DATABASE SETUP FOR ILMA CLOUD PORTAL
-- =========================================================

-- =========================================================
-- SCHOOLS TABLE (Tenant Master)
-- =========================================================
create table if not exists schools (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  email         text not null unique,
  phone         text not null,
  logo_url      text,
  address       text,
  city          text,
  state         text,
  zip_code      text,
  country       text default 'India',
  website       text,
  status        text not null default 'pending', -- pending, active, suspended, expired
  subscription_plan text default 'free', -- free, basic, premium, enterprise
  subscription_expires_at timestamptz,
  primary_color text, -- Hex color code
  secondary_color text, -- Hex color code
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- =========================================================
-- UPDATE EXISTING TABLES TO ADD SCHOOL_ID (Tenant Isolation)
-- =========================================================

-- Add school_id to users table
alter table users add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to students table
alter table students add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to classes table
alter table classes add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to sections table
alter table sections add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to applications table
alter table applications add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to student_documents table
alter table student_documents add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to family_members table
alter table family_members add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to emergency_contacts table
alter table emergency_contacts add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to student_details table
alter table student_details add column if not exists school_id uuid references schools(id) on delete cascade;

-- Add school_id to application_fees table
alter table application_fees add column if not exists school_id uuid references schools(id) on delete cascade;

-- =========================================================
-- UPDATE STUDENTS_VIEW TO INCLUDE SCHOOL_ID
-- =========================================================
drop view if exists students_view;

create view students_view as
select 
  s.id,
  s.admission_no,
  s.user_id,
  s.class_id,
  s.section_id,
  s.status,
  s.school_id,
  s.created_at,
  up.full_name,
  c.name as class_name,
  c.code as class_code,
  sec.name as section_name
from students s
left join users u on u.id = s.user_id
left join user_profiles up on up.user_id = u.id
left join classes c on c.id = s.class_id
left join sections sec on sec.id = s.section_id;

-- =========================================================
-- RLS POLICIES FOR MULTI-TENANCY
-- =========================================================

-- Schools table - only super_admin can view all, schools can view their own
alter table schools enable row level security;

create policy "schools_select_own"
on schools for select
to authenticated
using (
  id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "schools_insert_any"
on schools for insert
to authenticated
with check (true); -- Allow registration

create policy "schools_update_own"
on schools for update
to authenticated
using (
  id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('principal', 'admin', 'super_admin')
  )
);

-- Update users RLS to include school_id
drop policy if exists "users_select_self" on users;
drop policy if exists "users_insert_self" on users;

create policy "users_select_same_school"
on users for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "users_insert_same_school"
on users for insert
to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or school_id is null -- Allow during registration
);

-- Update students RLS to include school_id
drop policy if exists "applicants_insert_pending_student" on students;
drop policy if exists "applicants_view_own_pending_student" on students;

create policy "students_select_same_school"
on students for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "students_insert_same_school"
on students for insert
to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
);

-- Update classes RLS
alter table classes enable row level security;

create policy "classes_select_same_school"
on classes for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "classes_manage_same_school"
on classes for all
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'super_admin')
  )
);

-- Update sections RLS
alter table sections enable row level security;

create policy "sections_select_same_school"
on sections for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "sections_manage_same_school"
on sections for all
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'super_admin')
  )
);

-- Update applications RLS
drop policy if exists "applicants_insert_own_application" on applications;
drop policy if exists "applicants_view_own_applications" on applications;
drop policy if exists "admins_view_all_applications" on applications;
drop policy if exists "admins_update_applications" on applications;

create policy "applications_select_same_school"
on applications for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role = 'super_admin'
  )
);

create policy "applications_insert_same_school"
on applications for insert
to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
);

create policy "applications_update_same_school"
on applications for update
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'super_admin')
  )
);

-- Similar policies for other tables (student_documents, family_members, etc.)
-- They should all filter by school_id

-- =========================================================
-- SUPER ADMIN USER (for managing all schools)
-- =========================================================
-- Note: Create this user manually in Supabase Auth and then run:
-- insert into users (auth_id, email, role, school_id) 
-- values ('<auth_user_id>', 'admin@ilma.cloud', 'super_admin', null);

-- =========================================================
-- INDEXES FOR PERFORMANCE
-- =========================================================
create index if not exists idx_users_school_id on users(school_id);
create index if not exists idx_students_school_id on students(school_id);
create index if not exists idx_classes_school_id on classes(school_id);
create index if not exists idx_sections_school_id on sections(school_id);
create index if not exists idx_applications_school_id on applications(school_id);

