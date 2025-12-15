-- =========================================================
-- FIX RLS POLICY FOR SCHOOL REGISTRATION
-- This allows school registration to work
-- =========================================================

-- Drop the existing insert policy
drop policy if exists "schools_insert_any" on schools;

-- Create a new policy that allows ANYONE (including unauthenticated) to insert
-- This is needed for the registration flow
create policy "schools_insert_any"
on schools for insert
to public  -- Changed from 'authenticated' to 'public' to allow registration
with check (true);

-- Also ensure authenticated users can insert (backup)
create policy "schools_insert_authenticated"
on schools for insert
to authenticated
with check (true);

