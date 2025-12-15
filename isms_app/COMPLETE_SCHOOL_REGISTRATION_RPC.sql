-- =========================================================
-- COMPLETE SCHOOL REGISTRATION RPC FUNCTION
-- This function bypasses RLS and handles the entire registration
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

-- Create the comprehensive registration function
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
    -- Rollback is automatic in a function
    raise exception 'Registration failed: %', sqlerrm;
end;
$$;

-- Grant execute permissions
grant execute on function complete_school_registration to authenticated;
grant execute on function complete_school_registration to anon;
grant execute on function complete_school_registration to public;

-- =========================================================
-- ALTERNATIVE: Keep the existing create_school function
-- and create separate functions for users and profiles
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

