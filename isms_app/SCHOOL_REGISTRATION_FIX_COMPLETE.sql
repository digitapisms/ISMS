-- =========================================================
-- COMPLETE FIX FOR SCHOOL REGISTRATION
-- This ensures registration works even without email confirmation
-- =========================================================

-- Step 1: Drop all existing policies
do $$
declare
  r record;
begin
  for r in (
    select policyname 
    from pg_policies 
    where tablename = 'schools'
  ) loop
    execute format('drop policy if exists %I on schools', r.policyname);
  end loop;
end $$;

-- Step 2: Create policies that work for both authenticated and unauthenticated
-- Policy for authenticated users
create policy "schools_insert_authenticated"
on schools for insert
to authenticated
with check (true);

-- Policy for public/unauthenticated (needed if email confirmation is required)
create policy "schools_insert_public"
on schools for insert
to public
with check (true);

-- Step 3: Verify policies
select policyname, roles, cmd 
from pg_policies 
where tablename = 'schools' and cmd = 'INSERT';

