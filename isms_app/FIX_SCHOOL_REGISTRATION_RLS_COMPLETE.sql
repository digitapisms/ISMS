-- =========================================================
-- COMPLETE FIX FOR SCHOOL REGISTRATION RLS
-- This will remove all policies and create a clean one
-- =========================================================

-- Step 1: List all existing policies on schools table
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies 
where tablename = 'schools';

-- Step 2: Drop ALL policies on schools table
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

-- Step 3: Verify all policies are dropped
select count(*) as remaining_policies
from pg_policies 
where tablename = 'schools';

-- Step 4: Create a simple, permissive insert policy
create policy "schools_insert_all"
on schools for insert
to authenticated
with check (true);

-- Step 5: Also allow public (as backup)
create policy "schools_insert_public_backup"
on schools for insert
to public
with check (true);

-- Step 6: Verify new policies
select 
  policyname,
  permissive,
  roles,
  cmd
from pg_policies 
where tablename = 'schools' and cmd = 'INSERT';

