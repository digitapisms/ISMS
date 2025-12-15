-- =========================================================
-- ADD SCHOOL CODE TO SCHOOLS TABLE
-- This adds a unique school code that can be used for registration
-- =========================================================

-- Add school_code column if it doesn't exist
do $$ 
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'schools' 
    and column_name = 'school_code'
  ) then
    alter table schools add column school_code text unique;
    
    -- Generate school codes for existing schools
    update schools
    set school_code = upper(
      substring(md5(random()::text || id::text || name) from 1 for 8)
    )
    where school_code is null;
    
    -- Make it required for new schools
    alter table schools alter column school_code set not null;
  end if;
exception when others then
  raise notice 'Could not add school_code: %', sqlerrm;
end $$;

-- Create index for faster lookups
create index if not exists idx_schools_code on schools(school_code);

-- Create a function to generate unique school codes
create or replace function generate_school_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_exists boolean;
begin
  loop
    -- Generate an 8-character alphanumeric code
    v_code := upper(
      substring(
        md5(random()::text || clock_timestamp()::text) 
        from 1 for 8
      )
    );
    
    -- Check if code already exists
    select exists(select 1 from schools where school_code = v_code) into v_exists;
    
    -- Exit loop if code is unique
    exit when not v_exists;
  end loop;
  
  return v_code;
end;
$$;

-- Update the complete_school_registration function to include school_code
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
  v_school_code text;
begin
  -- Generate unique school code
  v_school_code := generate_school_code();
  
  -- Step 1: Create school record
  insert into schools (
    name, email, phone, logo_url, address, city, state, zip_code, country,
    website, slogan, school_type, group_name, boards_organizations,
    charity_foundation_type, status, subscription_plan, school_code
  ) values (
    p_name, p_email, p_phone, p_logo_url, p_address, p_city, p_state, 
    p_zip_code, p_country, p_website, p_slogan, p_school_type, p_group_name,
    p_boards_organizations, p_charity_foundation_type, 'pending', 'free', v_school_code
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

-- Update create_school function to include school_code
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
  v_school_code text;
begin
  -- Generate unique school code
  v_school_code := generate_school_code();
  
  insert into schools (
    name, email, phone, logo_url, address, city, state, zip_code, country,
    website, slogan, school_type, group_name, boards_organizations,
    charity_foundation_type, status, subscription_plan, school_code
  ) values (
    p_name, p_email, p_phone, p_logo_url, p_address, p_city, p_state, 
    p_zip_code, p_country, p_website, p_slogan, p_school_type, p_group_name,
    p_boards_organizations, p_charity_foundation_type, p_status, p_subscription_plan, v_school_code
  ) returning id into v_school_id;
  
  return v_school_id;
end;
$$;

