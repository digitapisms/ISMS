-- =========================================================
-- ALTERNATIVE FIX: Temporarily disable RLS for inserts
-- Use this if the policy approach doesn't work
-- =========================================================

-- Option 1: Disable RLS completely (NOT RECOMMENDED for production)
-- Uncomment only if absolutely necessary:
-- alter table schools disable row level security;

-- Option 2: Drop all policies and recreate with proper structure
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

-- Create a permissive policy that definitely works
create policy "schools_allow_insert"
on schools for insert
to authenticated
with check (true);

-- Also create for public (unauthenticated) as absolute backup
create policy "schools_allow_insert_public"
on schools for insert
to public
with check (true);

-- Verify
select policyname, roles, cmd from pg_policies where tablename = 'schools';

