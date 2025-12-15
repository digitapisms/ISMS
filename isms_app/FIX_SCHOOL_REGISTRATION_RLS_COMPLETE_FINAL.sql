-- =========================================================
-- COMPLETE RLS FIX FOR SCHOOL REGISTRATION
-- This script fixes all RLS policies needed for school registration
-- =========================================================

-- =========================================================
-- 1. FIX SCHOOLS TABLE RLS
-- =========================================================

-- Enable RLS on schools (if not already enabled)
alter table schools enable row level security;

-- Drop existing policies
drop policy if exists "schools_insert_any" on schools;
drop policy if exists "schools_select_any" on schools;
drop policy if exists "schools_update_any" on schools;
drop policy if exists "schools_select_own" on schools;
drop policy if exists "schools_update_own" on schools;

-- Allow authenticated users to insert schools (for registration)
create policy "schools_insert_any"
on schools for insert
to authenticated
with check (true);

-- Allow authenticated users to select schools
create policy "schools_select_any"
on schools for select
to authenticated
using (true);

-- Allow authenticated users to update schools
create policy "schools_update_any"
on schools for update
to authenticated
using (true)
with check (true);

-- =========================================================
-- 2. FIX USERS TABLE RLS
-- =========================================================

-- Enable RLS on users (if not already enabled)
alter table users enable row level security;

-- Drop existing policies
drop policy if exists "users_insert_any" on users;
drop policy if exists "users_select_own" on users;
drop policy if exists "users_update_own" on users;
drop policy if exists "users_insert_authenticated" on users;
drop policy if exists "users_select_authenticated" on users;

-- Allow authenticated users to insert (for registration)
create policy "users_insert_authenticated"
on users for insert
to authenticated
with check (true);

-- Allow users to select their own record
create policy "users_select_own"
on users for select
to authenticated
using (auth_id = auth.uid());

-- Allow users to select any user (needed for registration flow)
create policy "users_select_authenticated"
on users for select
to authenticated
using (true);

-- Allow users to update their own record
create policy "users_update_own"
on users for update
to authenticated
using (auth_id = auth.uid())
with check (auth_id = auth.uid());

-- =========================================================
-- 3. FIX USER_PROFILES TABLE RLS
-- =========================================================

-- Enable RLS on user_profiles (if not already enabled)
alter table user_profiles enable row level security;

-- Drop existing policies
drop policy if exists "user_profiles_insert_any" on user_profiles;
drop policy if exists "user_profiles_select_own" on user_profiles;
drop policy if exists "user_profiles_update_own" on user_profiles;
drop policy if exists "user_profiles_insert_authenticated" on user_profiles;
drop policy if exists "user_profiles_select_authenticated" on user_profiles;

-- Allow authenticated users to insert profiles (for registration)
-- More permissive to allow registration flow
create policy "user_profiles_insert_authenticated"
on user_profiles for insert
to authenticated
with check (true);

-- Allow users to select their own profile
create policy "user_profiles_select_own"
on user_profiles for select
to authenticated
using (
  exists (
    select 1 from users
    where users.id = user_profiles.user_id
    and users.auth_id = auth.uid()
  )
);

-- Allow users to select any profile (needed during registration)
create policy "user_profiles_select_authenticated"
on user_profiles for select
to authenticated
using (true);

-- Allow users to update their own profile
create policy "user_profiles_update_own"
on user_profiles for update
to authenticated
using (
  exists (
    select 1 from users
    where users.id = user_profiles.user_id
    and users.auth_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from users
    where users.id = user_profiles.user_id
    and users.auth_id = auth.uid()
  )
);

-- =========================================================
-- 4. CREATE COMPREHENSIVE REGISTRATION RPC FUNCTION
-- =========================================================

-- Drop existing function if it exists
drop function if exists complete_school_registration(
  p_name text,
  p_email text,
  p_phone text,
  p_principal_name text,
  p_principal_email text,
  p_principal_auth_id uuid,
  p_logo_url text,
  p_address text,
  p_city text,
  p_state text,
  p_zip_code text,
  p_country text,
  p_website text,
  p_slogan text,
  p_school_type text,
  p_group_name text,
  p_boards_organizations text,
  p_charity_foundation_type text
);

-- Create the comprehensive registration function (bypasses all RLS)
create or replace function complete_school_registration(
  p_name text,
  p_email text,
  p_phone text,
  p_principal_name text,
  p_principal_email text,
  p_principal_auth_id uuid,
  p_logo_url text default null,
  p_address text default null,
  p_city text default null,
  p_state text default null,
  p_zip_code text default null,
  p_country text default 'Pakistan',
  p_website text default null,
  p_slogan text default null,
  p_school_type text default null,
  p_group_name text default null,
  p_boards_organizations text default null,
  p_charity_foundation_type text default null
)
returns jsonb
language plpgsql
security definer  -- This bypasses RLS
as $$
declare
  v_school_id uuid;
  v_user_id uuid;
  v_result jsonb;
begin
  -- Step 1: Create school record
  insert into schools (
    name, email, phone, logo_url, address, city, state, zip_code, country,
    website, slogan, school_type, group_name, boards_organizations,
    charity_foundation_type, status, subscription_plan
  ) values (
    p_name, p_email, p_phone, p_logo_url, p_address, p_city, p_state, 
    p_zip_code, p_country, p_website, p_slogan, p_school_type, p_group_name,
    p_boards_organizations, p_charity_foundation_type, 'pending', 'free'
  ) returning id into v_school_id;

  -- Step 2: Create principal user record
  insert into users (
    auth_id, email, role, school_id
  ) values (
    p_principal_auth_id, p_principal_email, 'principal', v_school_id
  ) returning id into v_user_id;

  -- Step 3: Create principal profile
  insert into user_profiles (
    user_id, full_name
  ) values (
    v_user_id, p_principal_name
  );

  -- Step 4: Return the school data
  select row_to_json(s.*) into v_result
  from schools s
  where s.id = v_school_id;

  return v_result;
exception
  when others then
    raise exception 'Registration failed: %', sqlerrm;
end;
$$;

-- Grant execute permissions
grant execute on function complete_school_registration to authenticated;
grant execute on function complete_school_registration to anon;
grant execute on function complete_school_registration to public;

-- =========================================================
-- 5. CREATE SEPARATE RPC FUNCTIONS (as fallback)
-- =========================================================

-- Function to create user (bypasses RLS)
create or replace function create_principal_user(
  p_auth_id uuid,
  p_email text,
  p_school_id uuid,
  p_principal_name text
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  -- Create user record
  insert into users (
    auth_id, email, role, school_id
  ) values (
    p_auth_id, p_email, 'principal', p_school_id
  ) returning id into v_user_id;

  -- Create user profile
  insert into user_profiles (
    user_id, full_name
  ) values (
    v_user_id, p_principal_name
  );

  return v_user_id;
exception
  when others then
    raise exception 'Failed to create principal user: %', sqlerrm;
end;
$$;

-- Grant execute permissions
grant execute on function create_principal_user to authenticated;
grant execute on function create_principal_user to anon;
grant execute on function create_principal_user to public;

-- =========================================================
-- 6. ENSURE CREATE_SCHOOL RPC FUNCTION EXISTS
-- =========================================================

-- Create or replace the create_school function (bypasses RLS)
create or replace function create_school(
  p_name text,
  p_email text,
  p_phone text,
  p_logo_url text default null,
  p_address text default null,
  p_city text default null,
  p_state text default null,
  p_zip_code text default null,
  p_country text default 'Pakistan',
  p_website text default null,
  p_slogan text default null,
  p_school_type text default null,
  p_group_name text default null,
  p_boards_organizations text default null,
  p_charity_foundation_type text default null,
  p_status text default 'pending',
  p_subscription_plan text default 'free'
)
returns uuid
language plpgsql
security definer  -- This bypasses RLS
as $$
declare
  v_school_id uuid;
begin
  insert into schools (
    name, email, phone, logo_url, address, city, state, zip_code, country,
    website, slogan, school_type, group_name, boards_organizations,
    charity_foundation_type, status, subscription_plan
  ) values (
    p_name, p_email, p_phone, p_logo_url, p_address, p_city, p_state, 
    p_zip_code, p_country, p_website, p_slogan, p_school_type, p_group_name,
    p_boards_organizations, p_charity_foundation_type, p_status, p_subscription_plan
  ) returning id into v_school_id;
  
  return v_school_id;
end;
$$;

-- Grant execute permissions
grant execute on function create_school to authenticated;
grant execute on function create_school to anon;
grant execute on function create_school to public;

-- =========================================================
-- 5. OPTIONAL: CREATE CONFIRM_USER_EMAIL FUNCTION
-- =========================================================

-- This function can be used to auto-confirm users during registration
-- (useful if email confirmation is enabled in Supabase)
create or replace function confirm_user_email(user_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update auth.users
  set email_confirmed_at = now()
  where id = user_id;
end;
$$;

-- Grant execute permissions
grant execute on function confirm_user_email(uuid) to authenticated;
grant execute on function confirm_user_email(uuid) to anon;
grant execute on function confirm_user_email(uuid) to public;

-- =========================================================
-- VERIFICATION QUERIES (Run these to verify)
-- =========================================================

-- Check if RLS is enabled
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
and tablename in ('schools', 'users', 'user_profiles');

-- Check existing policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename in ('schools', 'users', 'user_profiles')
order by tablename, policyname;

-- =========================================================
-- NOTES:
-- =========================================================
-- 1. These policies are permissive to allow registration to work
-- 2. You can tighten them later for production security
-- 3. The create_school function uses SECURITY DEFINER to bypass RLS
-- 4. Make sure email confirmation is disabled in Supabase Auth settings
--    (Settings > Authentication > Email Auth > Confirm email)
-- =========================================================

