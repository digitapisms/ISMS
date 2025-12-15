-- =========================================================
-- FINAL FIX FOR SCHOOL REGISTRATION RLS
-- The issue: User is NOT authenticated when inserting school
-- Solution: Allow public (unauthenticated) inserts
-- =========================================================

-- Drop ALL existing insert policies
drop policy if exists "schools_insert_any" on schools;
drop policy if exists "schools_insert_public" on schools;
drop policy if exists "schools_insert_authenticated" on schools;
drop policy if exists "schools_insert_registration" on schools;
drop policy if exists "schools_insert_anyone" on schools;

-- IMPORTANT: Allow PUBLIC (unauthenticated) inserts for registration
-- This is needed because school is created BEFORE principal user is authenticated
create policy "schools_insert_public"
on schools for insert
to public  -- This allows unauthenticated users
with check (true);

-- Also allow authenticated users (for future use)
create policy "schools_insert_authenticated"
on schools for insert
to authenticated
with check (true);

-- Verify the policies
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
from pg_policies 
where tablename = 'schools';

