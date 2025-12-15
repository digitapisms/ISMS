-- =============================================================
-- REPORTS & ANALYTICS HELPERS
-- Provides aggregation helpers for school-level dashboards
-- =============================================================

-- Helper: Overview metrics for a single school
drop function if exists get_school_report_overview(uuid);
create or replace function get_school_report_overview(
  p_school_id uuid
)
returns table (
  total_students bigint,
  new_students_30d bigint,
  total_applications bigint,
  pending_applications bigint,
  under_review_applications bigint,
  approved_applications bigint,
  rejected_applications bigint,
  staff_count bigint,
  teacher_count bigint,
  class_count bigint,
  section_count bigint,
  notifications_30d bigint,
  last_activity_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    coalesce((
      select count(*) from students where school_id = p_school_id
    ), 0)::bigint as total_students,
    coalesce((
      select count(*)
      from students
      where school_id = p_school_id
        and coalesce(created_at, now()) >= (now() - interval '30 days')
    ), 0)::bigint as new_students_30d,
    coalesce((
      select count(*) from applications where school_id = p_school_id
    ), 0)::bigint as total_applications,
    coalesce((
      select count(*)
      from applications
      where school_id = p_school_id
        and status = 'pending'
    ), 0)::bigint as pending_applications,
    coalesce((
      select count(*)
      from applications
      where school_id = p_school_id
        and status = 'under_review'
    ), 0)::bigint as under_review_applications,
    coalesce((
      select count(*)
      from applications
      where school_id = p_school_id
        and status = 'approved'
    ), 0)::bigint as approved_applications,
    coalesce((
      select count(*)
      from applications
      where school_id = p_school_id
        and status = 'rejected'
    ), 0)::bigint as rejected_applications,
    coalesce((
      select count(*)
      from users
      where school_id = p_school_id
        and role in ('admin','principal','staff')
    ), 0)::bigint as staff_count,
    coalesce((
      select count(*)
      from users
      where school_id = p_school_id
        and role = 'teacher'
    ), 0)::bigint as teacher_count,
    coalesce((
      select count(*)
      from classes
      where school_id = p_school_id
    ), 0)::bigint as class_count,
    coalesce((
      select count(*)
      from sections
      where school_id = p_school_id
    ), 0)::bigint as section_count,
    coalesce((
      select count(*)
      from notifications
      where school_id = p_school_id
        and coalesce(sent_at, created_at, now()) >= (now() - interval '30 days')
    ), 0)::bigint as notifications_30d,
    greatest(
      coalesce((
        select max(created_at) from students where school_id = p_school_id
      ), to_timestamp(0)),
      coalesce((
        select max(coalesce(submitted_at, created_at)) from applications where school_id = p_school_id
      ), to_timestamp(0)),
      coalesce((
        select max(coalesce(sent_at, created_at)) from notifications where school_id = p_school_id
      ), to_timestamp(0))
    ) as last_activity_at;
end;
$$;

grant execute on function get_school_report_overview(uuid) to anon, authenticated;

-- Helper: Time-series metrics for charts
drop function if exists get_school_report_timeseries(uuid, integer);
create or replace function get_school_report_timeseries(
  p_school_id uuid,
  p_days integer default 30
)
returns table (
  bucket_date date,
  metric text,
  value bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_days integer := greatest(coalesce(p_days, 30), 1);
begin
  return query
  with series as (
    select generate_series(
      current_date - (v_days - 1),
      current_date,
      interval '1 day'
    )::date as bucket_date
  ),
  student_counts as (
    select
      coalesce(date(created_at), current_date) as bucket_date,
      count(*) as value
    from students
    where school_id = p_school_id
      and coalesce(date(created_at), current_date) >= current_date - (v_days - 1)
    group by 1
  ),
  application_counts as (
    select
      coalesce(date(coalesce(submitted_at, created_at)), current_date) as bucket_date,
      count(*) as value
    from applications
    where school_id = p_school_id
      and coalesce(date(coalesce(submitted_at, created_at)), current_date) >= current_date - (v_days - 1)
    group by 1
  ),
  notification_counts as (
    select
      coalesce(date(coalesce(sent_at, created_at)), current_date) as bucket_date,
      count(*) as value
    from notifications
    where school_id = p_school_id
      and coalesce(date(coalesce(sent_at, created_at)), current_date) >= current_date - (v_days - 1)
    group by 1
  )
  (
    select
      s.bucket_date,
      'students'::text as metric,
      coalesce(sc.value, 0)::bigint as value
    from series s
    left join student_counts sc on sc.bucket_date = s.bucket_date
    union all
    select
      s.bucket_date,
      'applications'::text as metric,
      coalesce(ac.value, 0)::bigint as value
    from series s
    left join application_counts ac on ac.bucket_date = s.bucket_date
    union all
    select
      s.bucket_date,
      'notifications'::text as metric,
      coalesce(nc.value, 0)::bigint as value
    from series s
    left join notification_counts nc on nc.bucket_date = s.bucket_date
    order by 1, 2
  );
end;
$$;

grant execute on function get_school_report_timeseries(uuid, integer) to anon, authenticated;

