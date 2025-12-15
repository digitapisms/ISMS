-- =========================================================
-- CLASSES AND SECTIONS SCHEMA
-- This creates tables for managing classes and sections
-- =========================================================

-- =========================================================
-- 1. DROP EXISTING POLICIES (if any)
-- =========================================================

drop policy if exists "classes_select_school" on classes;
drop policy if exists "classes_insert_school_admin" on classes;
drop policy if exists "classes_update_school_admin" on classes;
drop policy if exists "classes_delete_school_admin" on classes;
drop policy if exists "sections_select_school" on sections;
drop policy if exists "sections_insert_school_admin" on sections;
drop policy if exists "sections_update_school_admin" on sections;
drop policy if exists "sections_delete_school_admin" on sections;

-- =========================================================
-- 2. CREATE CLASSES TABLE
-- =========================================================

create table if not exists classes (
  id          serial primary key,
  name        text not null, -- e.g., "Grade 1", "Class 1", "Year 1"
  code        text, -- Optional: "G1", "C1", etc.
  level       integer, -- Optional: numeric level (1, 2, 3, etc.)
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Add school_id column if it doesn't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'classes' and column_name = 'school_id'
  ) then
    -- Add column as nullable first
    alter table classes add column school_id uuid references schools(id) on delete cascade;
    
    -- Delete any existing rows without school_id (orphaned data)
    -- If you want to keep them, you'll need to manually assign a school_id first
    delete from classes where school_id is null;
    
    -- Now set to not null (safe since we deleted NULL rows)
    alter table classes alter column school_id set not null;
  else
    -- Column exists but might have NULL values - clean them up
    delete from classes where school_id is null;
    -- Try to set not null (might fail if there are still NULLs due to constraints)
    begin
      alter table classes alter column school_id set not null;
    exception when others then
      -- If it fails, the column might already be not null or there are still issues
      raise notice 'Could not set school_id to NOT NULL. Please check for NULL values manually.';
    end;
  end if;
end $$;

-- Add unique constraint if it doesn't exist
do $$
begin
  if not exists (
    select 1 from pg_constraint 
    where conname = 'classes_school_id_name_key'
  ) then
    alter table classes add constraint classes_school_id_name_key unique(school_id, name);
  end if;
end $$;

-- Add is_active column if it doesn't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'classes' and column_name = 'is_active'
  ) then
    alter table classes add column is_active boolean not null default true;
  end if;
end $$;

-- Add created_at and updated_at columns if they don't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'classes' and column_name = 'created_at'
  ) then
    alter table classes add column created_at timestamptz not null default now();
  end if;
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'classes' and column_name = 'updated_at'
  ) then
    alter table classes add column updated_at timestamptz not null default now();
  end if;
end $$;

-- =========================================================
-- 3. CREATE SECTIONS TABLE
-- =========================================================

create table if not exists sections (
  id          serial primary key,
  class_id    integer not null references classes(id) on delete cascade,
  name        text not null, -- e.g., "A", "B", "Morning", "Afternoon"
  code        text, -- Optional: "A", "B", "M", "A", etc.
  capacity    integer, -- Optional: max students in section
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Add school_id column if it doesn't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'sections' and column_name = 'school_id'
  ) then
    -- Add column as nullable first
    alter table sections add column school_id uuid references schools(id) on delete cascade;
    
    -- If there are existing rows, update them based on their class's school_id
    update sections s
    set school_id = c.school_id
    from classes c
    where s.class_id = c.id and s.school_id is null;
    
    -- Delete any sections that couldn't be updated (orphaned - class doesn't exist or has no school_id)
    delete from sections where school_id is null;
    
    -- Now set to not null
    alter table sections alter column school_id set not null;
  else
    -- Column exists - update any NULL values from their class
    update sections s
    set school_id = c.school_id
    from classes c
    where s.class_id = c.id and s.school_id is null;
    
    -- Delete any sections that still have NULL (orphaned)
    delete from sections where school_id is null;
    
    -- Try to set not null
    begin
      alter table sections alter column school_id set not null;
    exception when others then
      raise notice 'Could not set school_id to NOT NULL. Please check for NULL values manually.';
    end;
  end if;
end $$;

-- Add unique constraint if it doesn't exist
do $$
begin
  if not exists (
    select 1 from pg_constraint 
    where conname = 'sections_class_id_name_key'
  ) then
    alter table sections add constraint sections_class_id_name_key unique(class_id, name);
  end if;
end $$;

-- Add is_active column if it doesn't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'sections' and column_name = 'is_active'
  ) then
    alter table sections add column is_active boolean not null default true;
  end if;
end $$;

-- Add created_at and updated_at columns if they don't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'sections' and column_name = 'created_at'
  ) then
    alter table sections add column created_at timestamptz not null default now();
  end if;
  if not exists (
    select 1 from information_schema.columns 
    where table_name = 'sections' and column_name = 'updated_at'
  ) then
    alter table sections add column updated_at timestamptz not null default now();
  end if;
end $$;

-- =========================================================
-- 4. CREATE INDEXES
-- =========================================================

create index if not exists idx_classes_school_id on classes(school_id);
create index if not exists idx_classes_is_active on classes(is_active);
create index if not exists idx_sections_class_id on sections(class_id);
create index if not exists idx_sections_school_id on sections(school_id);
create index if not exists idx_sections_is_active on sections(is_active);

-- =========================================================
-- 5. ENABLE RLS
-- =========================================================

alter table classes enable row level security;
alter table sections enable row level security;

-- =========================================================
-- 6. RLS POLICIES FOR CLASSES
-- =========================================================

-- Allow authenticated users to view classes for their school
create policy "classes_select_school"
on classes for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
);

-- Allow school admins/principals to manage classes
create policy "classes_insert_school_admin"
on classes for insert
to authenticated
with check (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

create policy "classes_update_school_admin"
on classes for update
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
)
with check (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

create policy "classes_delete_school_admin"
on classes for delete
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

-- =========================================================
-- 7. RLS POLICIES FOR SECTIONS
-- =========================================================

-- Allow authenticated users to view sections for their school
create policy "sections_select_school"
on sections for select
to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
);

-- Allow school admins/principals to manage sections
create policy "sections_insert_school_admin"
on sections for insert
to authenticated
with check (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

create policy "sections_update_school_admin"
on sections for update
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
)
with check (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

create policy "sections_delete_school_admin"
on sections for delete
to authenticated
using (
  school_id in (
    select school_id from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal')
  )
);

-- =========================================================
-- 8. TRIGGERS FOR UPDATED_AT
-- =========================================================

create or replace function update_updated_at_column()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists update_classes_updated_at on classes;
create trigger update_classes_updated_at
before update on classes
for each row
execute function update_updated_at_column();

drop trigger if exists update_sections_updated_at on sections;
create trigger update_sections_updated_at
before update on sections
for each row
execute function update_updated_at_column();

-- =========================================================
-- 9. HELPER FUNCTIONS
-- =========================================================

-- Function to get class with section count
create or replace function get_class_with_section_count(p_class_id integer)
returns table (
  id integer,
  school_id uuid,
  name text,
  code text,
  level integer,
  description text,
  is_active boolean,
  section_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select 
    c.id,
    c.school_id,
    c.name,
    c.code,
    c.level,
    c.description,
    c.is_active,
    count(s.id) as section_count,
    c.created_at,
    c.updated_at
  from classes c
  left join sections s on s.class_id = c.id and s.is_active = true
  where c.id = p_class_id
  group by c.id, c.school_id, c.name, c.code, c.level, c.description, c.is_active, c.created_at, c.updated_at;
end;
$$;

grant execute on function get_class_with_section_count to authenticated;
grant execute on function get_class_with_section_count to anon;

