-- =========================================================
-- SUBSCRIPTION PLANS AND FEATURES SCHEMA
-- This creates tables for managing subscription plans and their features
-- =========================================================

-- =========================================================
-- 1. CREATE PLAN FEATURES TABLE
-- =========================================================

create table if not exists plan_features (
  id          uuid primary key default gen_random_uuid(),
  feature_key  text not null unique, -- e.g., 'student_management', 'bulk_import', 'custom_reports'
  feature_name text not null, -- Display name: 'Student Management', 'Bulk Import', etc.
  description  text,
  category     text, -- 'core', 'advanced', 'integration', 'analytics', etc.
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

drop trigger if exists update_plan_features_updated_at on plan_features;
create trigger update_plan_features_updated_at
before update on plan_features
for each row execute function update_updated_at_column();

-- =========================================================
-- 2. CREATE PLAN FEATURE MAPPING TABLE
-- =========================================================

create table if not exists plan_feature_mapping (
  id           uuid primary key default gen_random_uuid(),
  plan_name    text not null, -- 'free', 'basic', 'premium', 'enterprise'
  feature_id   uuid not null references plan_features(id) on delete cascade,
  is_enabled   boolean not null default true,
  limit_value  integer, -- Optional: limit for this feature (e.g., max 100 students)
  created_at   timestamptz not null default now(),
  unique(plan_name, feature_id)
);

-- =========================================================
-- 3. CREATE INDEXES
-- =========================================================

create index if not exists idx_plan_features_key on plan_features(feature_key);
create index if not exists idx_plan_features_category on plan_features(category);
create index if not exists idx_plan_feature_mapping_plan on plan_feature_mapping(plan_name);
create index if not exists idx_plan_feature_mapping_feature on plan_feature_mapping(feature_id);

-- =========================================================
-- 4. INSERT DEFAULT FEATURES
-- =========================================================

-- Core Features
insert into plan_features (feature_key, feature_name, description, category) values
  ('student_management', 'Student Management', 'Add, edit, and manage student records', 'core'),
  ('student_registration', 'Student Registration', '5-page student registration form', 'core'),
  ('application_tracking', 'Application Tracking', 'Track student applications and status', 'core'),
  ('basic_reports', 'Basic Reports', 'View basic student and application reports', 'core'),
  ('user_management', 'User Management', 'Manage teachers, staff, and admin accounts', 'core'),
  ('class_management', 'Class Management', 'Create and manage classes and sections', 'core'),
  ('school_branding', 'School Branding', 'Customize logo and theme colors', 'core'),
  ('document_upload', 'Document Upload', 'Upload and manage student documents', 'advanced'),
  ('bulk_import', 'Bulk Student Import', 'Import multiple students via CSV/Excel', 'advanced'),
  ('advanced_reports', 'Advanced Reports', 'Custom reports with filters and exports', 'advanced'),
  ('email_notifications', 'Email Notifications', 'Send automated email notifications', 'advanced'),
  ('sms_notifications', 'SMS Notifications', 'Send SMS notifications to parents', 'integration'),
  ('parent_portal', 'Parent Portal', 'Dedicated portal for parents', 'integration'),
  ('student_portal', 'Student Portal', 'Dedicated portal for students', 'integration'),
  ('api_access', 'API Access', 'REST API access for integrations', 'integration'),
  ('custom_fields', 'Custom Fields', 'Add custom fields to student records', 'advanced'),
  ('attendance_tracking', 'Attendance Tracking', 'Track daily student attendance', 'advanced'),
  ('gradebook', 'Gradebook', 'Manage grades and assessments', 'advanced'),
  ('fee_management', 'Fee Management', 'Manage fee collection and payments', 'advanced'),
  ('transport_management', 'Transport Management', 'Manage transport routes and vehicles', 'advanced'),
  ('library_management', 'Library Management', 'Manage library books and loans', 'advanced'),
  ('inventory_management', 'Inventory Management', 'Manage school inventory', 'advanced'),
  ('timetable_management', 'Timetable Management', 'Create and manage class timetables', 'advanced'),
  ('exam_management', 'Exam Management', 'Schedule and manage examinations', 'advanced'),
  ('analytics_dashboard', 'Analytics Dashboard', 'Advanced analytics and insights', 'analytics'),
  ('data_export', 'Data Export', 'Export data in multiple formats', 'analytics'),
  ('backup_restore', 'Backup & Restore', 'Automated backups and restore', 'analytics'),
  ('priority_support', 'Priority Support', 'Priority customer support', 'support'),
  ('dedicated_support', 'Dedicated Support', 'Dedicated support representative', 'support'),
  ('custom_integrations', 'Custom Integrations', 'Custom third-party integrations', 'integration'),
  ('white_label', 'White Label', 'Remove ILMA branding', 'advanced'),
  ('multi_branch', 'Multi-Branch Support', 'Manage multiple school branches', 'advanced')
on conflict (feature_key) do nothing;

-- =========================================================
-- 5. SET UP DEFAULT PLAN FEATURES
-- =========================================================

-- FREE PLAN - Basic features only
insert into plan_feature_mapping (plan_name, feature_id, is_enabled, limit_value)
select 'free', id, true, 
  case 
    when feature_key = 'student_management' then 50 -- Max 50 students
    when feature_key = 'user_management' then 5 -- Max 5 users
    else null
  end
from plan_features
where feature_key in (
  'student_management',
  'student_registration',
  'application_tracking',
  'basic_reports',
  'user_management',
  'class_management',
  'school_branding'
)
on conflict (plan_name, feature_id) do nothing;

-- BASIC PLAN - More features with limits
insert into plan_feature_mapping (plan_name, feature_id, is_enabled, limit_value)
select 'basic', id, true,
  case
    when feature_key = 'student_management' then 500 -- Max 500 students
    when feature_key = 'user_management' then 50 -- Max 50 users
    when feature_key = 'document_upload' then 10 -- Max 10 documents per student
    else null
  end
from plan_features
where feature_key in (
  'student_management',
  'student_registration',
  'application_tracking',
  'basic_reports',
  'advanced_reports',
  'user_management',
  'class_management',
  'school_branding',
  'document_upload',
  'bulk_import',
  'email_notifications',
  'custom_fields',
  'attendance_tracking',
  'data_export'
)
on conflict (plan_name, feature_id) do nothing;

-- PREMIUM PLAN - Most features, higher limits
insert into plan_feature_mapping (plan_name, feature_id, is_enabled, limit_value)
select 'premium', id, true,
  case
    when feature_key = 'student_management' then 5000 -- Max 5000 students
    when feature_key = 'user_management' then 500 -- Max 500 users
    when feature_key = 'document_upload' then null -- Unlimited
    else null
  end
from plan_features
where feature_key in (
  'student_management',
  'student_registration',
  'application_tracking',
  'basic_reports',
  'advanced_reports',
  'user_management',
  'class_management',
  'school_branding',
  'document_upload',
  'bulk_import',
  'email_notifications',
  'sms_notifications',
  'parent_portal',
  'student_portal',
  'custom_fields',
  'attendance_tracking',
  'gradebook',
  'fee_management',
  'transport_management',
  'timetable_management',
  'exam_management',
  'analytics_dashboard',
  'data_export',
  'backup_restore',
  'priority_support'
)
on conflict (plan_name, feature_id) do nothing;

-- ENTERPRISE PLAN - All features, unlimited
insert into plan_feature_mapping (plan_name, feature_id, is_enabled, limit_value)
select 'enterprise', id, true, null -- All unlimited
from plan_features
on conflict (plan_name, feature_id) do nothing;

-- =========================================================
-- 6. ENABLE RLS (Optional - can be disabled for admin access)
-- =========================================================

alter table plan_features enable row level security;
alter table plan_feature_mapping enable row level security;

-- Allow authenticated users to read (for checking features)
drop policy if exists "plan_features_select_all" on plan_features;
create policy "plan_features_select_all"
on plan_features for select
to authenticated
using (true);

drop policy if exists "plan_feature_mapping_select_all" on plan_feature_mapping;
create policy "plan_feature_mapping_select_all"
on plan_feature_mapping for select
to authenticated
using (true);

-- Allow super admins to manage (you'll need to add role check)
-- For now, allow authenticated users to manage (tighten later)
drop policy if exists "plan_features_manage" on plan_features;
create policy "plan_features_manage"
on plan_features for all
to authenticated
using (true)
with check (true);

drop policy if exists "plan_feature_mapping_manage" on plan_feature_mapping;
create policy "plan_feature_mapping_manage"
on plan_feature_mapping for all
to authenticated
using (true)
with check (true);

-- =========================================================
-- 7. HELPER FUNCTIONS
-- =========================================================

-- Function to check if a feature is enabled for a plan
drop function if exists is_feature_enabled(text, text);
create or replace function is_feature_enabled(
  p_plan_name text,
  p_feature_key text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enabled boolean;
begin
  select pm.is_enabled into v_enabled
  from plan_feature_mapping pm
  join plan_features pf on pm.feature_id = pf.id
  where pm.plan_name = p_plan_name
    and pf.feature_key = p_feature_key;
  
  return coalesce(v_enabled, false);
end;
$$;

-- Function to get feature limit for a plan
drop function if exists get_feature_limit(text, text);
create or replace function get_feature_limit(
  p_plan_name text,
  p_feature_key text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit integer;
begin
  select pm.limit_value into v_limit
  from plan_feature_mapping pm
  join plan_features pf on pm.feature_id = pf.id
  where pm.plan_name = p_plan_name
    and pf.feature_key = p_feature_key;
  
  return v_limit;
end;
$$;

-- Function to get all features for a plan
drop function if exists get_plan_features(text);
create or replace function get_plan_features(p_plan_name text)
returns table (
  feature_key text,
  feature_name text,
  description text,
  category text,
  is_enabled boolean,
  limit_value integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select 
    pf.feature_key,
    pf.feature_name,
    pf.description,
    pf.category,
    coalesce(pm.is_enabled, false) as is_enabled,
    pm.limit_value
  from plan_features pf
  left join plan_feature_mapping pm on pf.id = pm.feature_id and pm.plan_name = p_plan_name
  order by pf.category, pf.feature_name;
end;
$$;

grant execute on function is_feature_enabled to authenticated;
grant execute on function is_feature_enabled to anon;
grant execute on function get_feature_limit to authenticated;
grant execute on function get_feature_limit to anon;
grant execute on function get_plan_features to authenticated;
grant execute on function get_plan_features to anon;

