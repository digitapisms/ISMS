-- =========================================================
-- FORCE ENABLE REGISTRATION - MOST PERMISSIVE POLICIES
-- This creates the most permissive RLS policies possible
-- =========================================================

-- =========================================================
-- 1. SCHOOLS TABLE
-- =========================================================

-- Enable RLS
alter table schools enable row level security;

-- Drop ALL existing policies
drop policy if exists "schools_insert_any" on schools;
drop policy if exists "schools_select_any" on schools;
drop policy if exists "schools_update_any" on schools;
drop policy if exists "schools_select_own" on schools;
drop policy if exists "schools_update_own" on schools;
drop policy if exists "schools_insert_authenticated" on schools;
drop policy if exists "schools_insert_public" on schools;

-- Allow ANYONE (including anonymous) to insert
create policy "schools_insert_public"
on schools for insert
to public
with check (true);

-- Allow ANYONE to select
create policy "schools_select_public"
on schools for select
to public
using (true);

-- Allow ANYONE to update
create policy "schools_update_public"
on schools for update
to public
using (true)
with check (true);

-- =========================================================
-- 2. USERS TABLE
-- =========================================================

-- Enable RLS
alter table users enable row level security;

-- Drop ALL existing policies
drop policy if exists "users_insert_any" on users;
drop policy if exists "users_select_own" on users;
drop policy if exists "users_update_own" on users;
drop policy if exists "users_insert_authenticated" on users;
drop policy if exists "users_select_authenticated" on users;
drop policy if exists "users_insert_public" on users;
drop policy if exists "users_select_public" on users;

-- Allow ANYONE (including anonymous) to insert
create policy "users_insert_public"
on users for insert
to public
with check (true);

-- Allow ANYONE to select
create policy "users_select_public"
on users for select
to public
using (true);

-- Allow ANYONE to update
create policy "users_update_public"
on users for update
to public
using (true)
with check (true);

-- =========================================================
-- 3. USER_PROFILES TABLE
-- =========================================================

-- Enable RLS
alter table user_profiles enable row level security;

-- Drop ALL existing policies
drop policy if exists "user_profiles_insert_any" on user_profiles;
drop policy if exists "user_profiles_select_own" on user_profiles;
drop policy if exists "user_profiles_update_own" on user_profiles;
drop policy if exists "user_profiles_insert_authenticated" on user_profiles;
drop policy if exists "user_profiles_select_authenticated" on user_profiles;
drop policy if exists "user_profiles_insert_public" on user_profiles;
drop policy if exists "user_profiles_select_public" on user_profiles;

-- Allow ANYONE (including anonymous) to insert
create policy "user_profiles_insert_public"
on user_profiles for insert
to public
with check (true);

-- Allow ANYONE to select
create policy "user_profiles_select_public"
on user_profiles for select
to public
using (true);

-- Allow ANYONE to update
create policy "user_profiles_update_public"
on user_profiles for update
to public
using (true)
with check (true);

-- =========================================================
-- 4. ENSURE RPC FUNCTIONS EXIST
-- =========================================================

-- Create complete_school_registration function
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
security definer
set search_path = public
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

-- Create create_principal_user function
create or replace function create_principal_user(
  p_auth_id uuid,
  p_email text,
  p_school_id uuid,
  p_principal_name text
)
returns uuid
language plpgsql
security definer
set search_path = public
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

-- Create create_school function
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
security definer
set search_path = public
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

