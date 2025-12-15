-- =========================================================
-- CREATE FUNCTION TO BYPASS RLS FOR SCHOOL REGISTRATION
-- This function runs with SECURITY DEFINER and bypasses RLS
-- =========================================================

-- Create function to insert school (bypasses RLS)
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

-- Grant execute to everyone
grant execute on function create_school to authenticated;
grant execute on function create_school to anon;
grant execute on function create_school to public;

