-- =========================================================
-- SIMPLE FIX: Ensure authenticated users can insert schools
-- =========================================================

-- Drop all existing insert policies
drop policy if exists "schools_insert_any" on schools;
drop policy if exists "schools_insert_public" on schools;
drop policy if exists "schools_insert_authenticated" on schools;
drop policy if exists "schools_insert_registration" on schools;
drop policy if exists "schools_insert_anyone" on schools;

-- Create a single policy that allows authenticated users to insert
-- This will work now that we authenticate the user BEFORE creating the school
create policy "schools_insert_authenticated"
on schools for insert
to authenticated
with check (true);

