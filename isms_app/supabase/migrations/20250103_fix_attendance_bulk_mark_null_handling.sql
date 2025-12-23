-- =============================================================
-- Migration: Fix Attendance Bulk Mark Null Handling
-- Date: 2025-01-03
-- Description: Fixes null handling for period_number in bulk_mark_attendance function
-- =============================================================

-- Fix the bulk_mark_attendance function to properly handle null period_number
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
      -- Fixed: Properly handle null period_number
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

-- Add comment
comment on function bulk_mark_attendance is 'Bulk mark attendance for multiple students - Fixed null handling for period_number';
