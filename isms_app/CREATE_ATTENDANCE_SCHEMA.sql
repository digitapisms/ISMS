-- =============================================================
-- ATTENDANCE MANAGEMENT SCHEMA
-- Tracks student attendance with multi-tenant support
-- =============================================================

-- 1. Attendance records table
create table if not exists attendance_records (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  class_id int references classes(id) on delete set null,
  section_id int references sections(id) on delete set null,
  attendance_date date not null,
  status text not null default 'present', -- present, absent, late, excused, half_day
  marked_by uuid references users(id) on delete set null,
  marked_at timestamptz not null default now(),
  notes text,
  period_number int, -- For period-wise attendance (optional)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  -- Ensure one record per student per date (or per date+period if period is set)
  constraint attendance_records_unique_student_date 
    unique (student_id, attendance_date, period_number)
);

create index if not exists idx_attendance_records_school 
  on attendance_records(school_id);
create index if not exists idx_attendance_records_student 
  on attendance_records(student_id);
create index if not exists idx_attendance_records_date 
  on attendance_records(attendance_date);
create index if not exists idx_attendance_records_class_section 
  on attendance_records(class_id, section_id);
create index if not exists idx_attendance_records_status 
  on attendance_records(status);

drop trigger if exists update_attendance_records_updated_at on attendance_records;
create trigger update_attendance_records_updated_at
before update on attendance_records
for each row execute function update_updated_at_column();

-- 2. Attendance sessions (for period-based attendance)
create table if not exists attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  class_id int not null references classes(id) on delete cascade,
  section_id int references sections(id) on delete set null,
  session_date date not null,
  period_number int, -- null for full-day attendance
  marked_by uuid references users(id) on delete set null,
  marked_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now(),
  
  -- Ensure one session per class/section/date/period
  constraint attendance_sessions_unique 
    unique (school_id, class_id, section_id, session_date, period_number)
);

create index if not exists idx_attendance_sessions_school 
  on attendance_sessions(school_id);
create index if not exists idx_attendance_sessions_class_section 
  on attendance_sessions(class_id, section_id);
create index if not exists idx_attendance_sessions_date 
  on attendance_sessions(session_date);

-- 3. RLS Policies for attendance_records
alter table if exists attendance_records enable row level security;

drop policy if exists attendance_records_select_school on attendance_records;
create policy attendance_records_select_school
on attendance_records
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_records.school_id
  )
);

drop policy if exists attendance_records_insert_school on attendance_records;
create policy attendance_records_insert_school
on attendance_records
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_records.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

drop policy if exists attendance_records_update_school on attendance_records;
create policy attendance_records_update_school
on attendance_records
for update
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_records.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
)
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_records.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

drop policy if exists attendance_records_delete_school on attendance_records;
create policy attendance_records_delete_school
on attendance_records
for delete
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_records.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 4. RLS Policies for attendance_sessions
alter table if exists attendance_sessions enable row level security;

drop policy if exists attendance_sessions_select_school on attendance_sessions;
create policy attendance_sessions_select_school
on attendance_sessions
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_sessions.school_id
  )
);

drop policy if exists attendance_sessions_insert_school on attendance_sessions;
create policy attendance_sessions_insert_school
on attendance_sessions
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_sessions.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

drop policy if exists attendance_sessions_update_school on attendance_sessions;
create policy attendance_sessions_update_school
on attendance_sessions
for update
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_sessions.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

drop policy if exists attendance_sessions_delete_school on attendance_sessions;
create policy attendance_sessions_delete_school
on attendance_sessions
for delete
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = attendance_sessions.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 5. Helper function: Get attendance statistics for a student
create or replace function get_student_attendance_stats(
  p_student_id uuid,
  p_start_date date,
  p_end_date date
)
returns table (
  total_days int,
  present_days int,
  absent_days int,
  late_days int,
  excused_days int,
  half_day_days int,
  attendance_percentage numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_present int;
  v_absent int;
  v_late int;
  v_excused int;
  v_half_day int;
begin
  -- Count total records in date range
  select count(*) into v_total
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date;
  
  -- Count by status
  select count(*) into v_present
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date
    and status = 'present';
  
  select count(*) into v_absent
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date
    and status = 'absent';
  
  select count(*) into v_late
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date
    and status = 'late';
  
  select count(*) into v_excused
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date
    and status = 'excused';
  
  select count(*) into v_half_day
  from attendance_records
  where student_id = p_student_id
    and attendance_date between p_start_date and p_end_date
    and status = 'half_day';
  
  -- Calculate percentage (present + late + half_day count as attendance)
  return query select
    v_total,
    v_present,
    v_absent,
    v_late,
    v_excused,
    v_half_day,
    case 
      when v_total > 0 then 
        round((v_present + v_late + v_half_day)::numeric / v_total::numeric * 100, 2)
      else 0
    end as attendance_percentage;
end;
$$;

-- 6. Helper function: Get class attendance summary for a date
create or replace function get_class_attendance_summary(
  p_school_id uuid,
  p_class_id int,
  p_section_id int,
  p_attendance_date date
)
returns table (
  total_students int,
  present_count int,
  absent_count int,
  late_count int,
  excused_count int,
  half_day_count int,
  marked_count int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_present int;
  v_absent int;
  v_late int;
  v_excused int;
  v_half_day int;
  v_marked int;
begin
  -- Count total students in class/section
  select count(*) into v_total
  from students
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and status = 'active';
  
  -- Count attendance by status
  select count(*) into v_present
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date
    and status = 'present';
  
  select count(*) into v_absent
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date
    and status = 'absent';
  
  select count(*) into v_late
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date
    and status = 'late';
  
  select count(*) into v_excused
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date
    and status = 'excused';
  
  select count(*) into v_half_day
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date
    and status = 'half_day';
  
  -- Count total marked (any status)
  select count(*) into v_marked
  from attendance_records
  where school_id = p_school_id
    and class_id = p_class_id
    and (p_section_id is null or section_id = p_section_id)
    and attendance_date = p_attendance_date;
  
  return query select
    v_total,
    v_present,
    v_absent,
    v_late,
    v_excused,
    v_half_day,
    v_marked;
end;
$$;

-- 7. Function to bulk mark attendance
create or replace function bulk_mark_attendance(
  p_school_id uuid,
  p_class_id int,
  p_section_id int,
  p_attendance_date date,
  p_records jsonb,
  p_marked_by uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_record jsonb;
  v_count int := 0;
begin
  -- Validate user has permission
  if not exists (
    select 1 from users
    where id = p_marked_by
    and school_id = p_school_id
    and role in ('admin', 'principal', 'teacher')
  ) then
    raise exception 'User does not have permission to mark attendance';
  end if;
  
  -- Insert or update attendance records
  for v_record in select * from jsonb_array_elements(p_records)
  loop
    insert into attendance_records (
      school_id,
      student_id,
      class_id,
      section_id,
      attendance_date,
      status,
      marked_by,
      notes,
      period_number
    )
    values (
      p_school_id,
      (v_record->>'student_id')::uuid,
      p_class_id,
      p_section_id,
      p_attendance_date,
      v_record->>'status',
      p_marked_by,
      v_record->>'notes',
      case 
        when v_record->>'period_number' is null or v_record->>'period_number' = '' 
        then null 
        else (v_record->>'period_number')::int 
      end
    )
    on conflict (student_id, attendance_date, period_number)
    do update set
      status = excluded.status,
      notes = excluded.notes,
      marked_by = excluded.marked_by,
      marked_at = now(),
      updated_at = now();
    
    v_count := v_count + 1;
  end loop;
  
  return v_count;
end;
$$;

-- 8. Insert sample data (optional - for testing)
-- This can be removed in production

comment on table attendance_records is 'Records of student attendance';
comment on table attendance_sessions is 'Attendance marking sessions for classes';
comment on function get_student_attendance_stats is 'Get attendance statistics for a student in a date range';
comment on function get_class_attendance_summary is 'Get attendance summary for a class/section on a specific date';
comment on function bulk_mark_attendance is 'Bulk mark attendance for multiple students';

