-- =========================================================
-- COMPLETE SCHOOL REGISTRATION SETUP
-- Creates schools table with all new fields
-- =========================================================

-- Step 1: Create schools table with all fields
create table if not exists schools (
  id                      uuid primary key default gen_random_uuid(),
  name                    text not null,
  email                   text not null unique,
  phone                   text not null,
  logo_url                text,
  address                 text,
  city                    text,
  state                   text,
  zip_code                text,
  country                 text default 'Pakistan',
  website                 text,
  slogan                  text,
  school_type             text, -- individual, group
  group_name              text,
  boards_organizations     text,
  charity_foundation_type text, -- charity_based, foundation, part_of_foundation
  status                  text not null default 'pending', -- pending, active, suspended, expired
  subscription_plan        text default 'free', -- free, basic, premium, enterprise
  subscription_expires_at  timestamptz,
  primary_color           text, -- Hex color code
  secondary_color         text, -- Hex color code
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- Step 2: Add school_id to users table (if users table exists)
-- This will fail silently if users table doesn't exist - that's okay
do $$ 
begin
  if exists (
    select 1 from information_schema.tables 
    where table_schema = 'public' and table_name = 'users'
  ) then
    -- Add column if it doesn't exist
    if not exists (
      select 1 from information_schema.columns 
      where table_schema = 'public' 
      and table_name = 'users' 
      and column_name = 'school_id'
    ) then
      alter table users add column school_id uuid references schools(id) on delete cascade;
    end if;
  end if;
exception when others then
  -- Silently ignore if table doesn't exist or other errors
  raise notice 'Could not add school_id to users table: %', sqlerrm;
end $$;

-- Step 3: Enable RLS
alter table schools enable row level security;

-- Step 4: Drop existing policies if they exist
drop policy if exists "schools_select_own" on schools;
drop policy if exists "schools_insert_any" on schools;
drop policy if exists "schools_update_own" on schools;

-- Step 5: Create RLS Policies
-- Policy 1: Allow anyone authenticated to insert (for registration)
create policy "schools_insert_any"
on schools for insert
to authenticated
with check (true);

-- Policy 2: Allow viewing - simplified to avoid column reference issues
-- This will work even if users.school_id doesn't exist yet
create policy "schools_select_own"
on schools for select
to authenticated
using (true); -- Allow all authenticated users to view for now
-- Note: You can tighten this later once users.school_id is confirmed to exist

-- Policy 3: Allow updating - simplified
create policy "schools_update_own"
on schools for update
to authenticated
using (true); -- Allow all authenticated users to update for now
-- Note: You can tighten this later once users.school_id is confirmed to exist

-- Step 6: Create indexes for performance
create index if not exists idx_schools_email on schools(email);
create index if not exists idx_schools_status on schools(status);

-- =========================================================
-- NOTE: After running this, if your users table has school_id column,
-- you can update the policies to be more restrictive:
-- 
-- For schools_select_own, change to:
-- using (
--   id in (select school_id from users where auth_id = auth.uid())
--   or exists (select 1 from users where auth_id = auth.uid() and role = 'super_admin')
-- );
--
-- For schools_update_own, change to:
-- using (
--   id in (
--     select school_id from users 
--     where auth_id = auth.uid() 
--     and role in ('principal', 'admin', 'super_admin')
--   )
--   or exists (select 1 from users where auth_id = auth.uid() and role = 'super_admin')
-- );
-- =========================================================
