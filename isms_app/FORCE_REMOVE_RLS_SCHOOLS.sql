-- =========================================================
-- FORCE REMOVE RLS - Complete Solution
-- Run this to completely remove RLS restrictions
-- =========================================================

-- Step 1: Check current RLS status
select 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  'Current status' as note
from pg_tables 
where tablename = 'schools';

-- Step 2: List all existing policies
select 
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies 
where tablename = 'schools';

-- Step 3: Force drop ALL policies (more aggressive)
do $$
declare
  policy_record record;
begin
  -- Drop all policies
  for policy_record in (
    select policyname 
    from pg_policies 
    where tablename = 'schools'
  ) loop
    begin
      execute format('drop policy if exists %I on public.schools', policy_record.policyname);
      raise notice 'Dropped policy: %', policy_record.policyname;
    exception when others then
      raise notice 'Error dropping policy %: %', policy_record.policyname, sqlerrm;
    end;
  end loop;
end $$;

-- Step 4: Disable RLS completely
alter table public.schools disable row level security;

-- Step 5: Verify RLS is disabled
select 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  'After disable - should be false' as note
from pg_tables 
where tablename = 'schools' and schemaname = 'public';

-- Step 6: Grant insert permission to everyone (extra safety)
grant insert on table public.schools to authenticated;
grant insert on table public.schools to anon;
grant insert on table public.schools to public;

-- Step 7: Final verification - should return 0 policies
select count(*) as remaining_policies
from pg_policies 
where tablename = 'schools';

-- If count is 0 and rls_enabled is false, RLS is completely disabled

