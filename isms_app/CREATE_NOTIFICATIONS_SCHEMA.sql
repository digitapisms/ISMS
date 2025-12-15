-- =========================================================
-- NOTIFICATIONS SYSTEM SCHEMA
-- This creates tables for managing email and SMS notifications
-- =========================================================

-- =========================================================
-- 1. CREATE NOTIFICATION TEMPLATES TABLE
-- =========================================================

create table if not exists notification_templates (
  id          uuid primary key default gen_random_uuid(),
  template_key text not null unique, -- e.g., 'application_submitted', 'application_approved', 'application_rejected'
  name        text not null, -- Display name
  description text,
  category    text, -- 'application', 'student', 'system', 'payment', etc.
  email_subject text,
  email_body   text,
  sms_body     text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- =========================================================
-- 2. CREATE NOTIFICATIONS TABLE
-- =========================================================

create table if not exists notifications (
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid not null references schools(id) on delete cascade,
  user_id       uuid references users(id) on delete set null,
  template_id   uuid references notification_templates(id),
  type          text not null, -- 'email', 'sms', 'push', 'in_app'
  status        text not null default 'pending', -- 'pending', 'sent', 'failed', 'delivered'
  recipient     text not null, -- email or phone number
  subject       text, -- for email
  body          text not null,
  metadata      jsonb, -- Additional data (template variables, etc.)
  error_message text,
  sent_at       timestamptz,
  delivered_at  timestamptz,
  created_at    timestamptz not null default now()
);

-- =========================================================
-- 3. CREATE NOTIFICATION PREFERENCES TABLE
-- =========================================================

create table if not exists notification_preferences (
  id            uuid primary key default gen_random_uuid(),
  school_id     uuid not null references schools(id) on delete cascade,
  user_id       uuid references users(id) on delete cascade,
  template_key  text not null, -- References notification_templates.template_key
  email_enabled boolean not null default true,
  sms_enabled   boolean not null default false,
  push_enabled  boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique(school_id, user_id, template_key)
);

-- =========================================================
-- 4. CREATE INDEXES
-- =========================================================

create index if not exists idx_notifications_school_id on notifications(school_id);
create index if not exists idx_notifications_user_id on notifications(user_id);
create index if not exists idx_notifications_status on notifications(status);
create index if not exists idx_notifications_created_at on notifications(created_at);
create index if not exists idx_notification_templates_key on notification_templates(template_key);
create index if not exists idx_notification_templates_category on notification_templates(category);
create index if not exists idx_notification_preferences_school_user on notification_preferences(school_id, user_id);

-- =========================================================
-- 5. ENSURE USERS TABLE HAS SCHOOL_ID COLUMN
-- =========================================================

-- Add school_id to users table if it doesn't exist
-- This MUST succeed before policies can reference it
do $$
declare
  v_table_exists boolean;
  v_column_exists boolean;
begin
  -- First check if users table exists
  select exists (
    select 1 from information_schema.tables 
    where table_schema = 'public'
      and table_name = 'users'
  ) into v_table_exists;
  
  if not v_table_exists then
    raise exception 'Users table does not exist. Please create it first.';
  end if;
  
  -- Check if column exists
  select exists (
    select 1 from information_schema.columns 
    where table_schema = 'public'
      and table_name = 'users' 
      and column_name = 'school_id'
  ) into v_column_exists;
  
  -- Add column if it doesn't exist
  if not v_column_exists then
    begin
      -- Check if schools table exists first
      if not exists (
        select 1 from information_schema.tables 
        where table_schema = 'public' and table_name = 'schools'
      ) then
        raise exception 'Schools table does not exist. Cannot add foreign key.';
      end if;
      
      alter table public.users add column school_id uuid references public.schools(id) on delete set null;
      raise notice 'Added school_id column to users table';
    exception
      when duplicate_column then
        raise notice 'Column school_id already exists (race condition)';
      when others then
        raise exception 'Failed to add school_id column: %', SQLERRM;
    end;
  else
    raise notice 'Column school_id already exists in users table';
  end if;
end $$;

-- =========================================================
-- 6. ENABLE RLS
-- =========================================================

alter table notifications enable row level security;
alter table notification_preferences enable row level security;
alter table notification_templates enable row level security;

-- =========================================================
-- 7. RLS POLICIES
-- =========================================================

-- Drop existing policies if they exist
drop policy if exists "notification_templates_select_all" on notification_templates;
drop policy if exists "notifications_select_own" on notifications;
drop policy if exists "notifications_select_school_admin" on notifications;
drop policy if exists "notifications_insert_school_admin" on notifications;
drop policy if exists "notification_preferences_select_own" on notification_preferences;
drop policy if exists "notification_preferences_manage_own" on notification_preferences;

-- Notification Templates - readable by all authenticated users
create policy "notification_templates_select_all"
on notification_templates for select
to authenticated
using (true);

-- Notifications - users can view their own, admins can view all for their school
create policy "notifications_select_own"
on notifications for select
to authenticated
using (
  user_id in (
    select id from users where auth_id = auth.uid()
  )
);

-- Create admin policies only if school_id column exists in users table
-- This prevents errors if the column doesn't exist
-- Using dynamic SQL (EXECUTE) so PostgreSQL doesn't validate column references at parse time
do $$
declare
  v_column_exists boolean;
begin
  -- Check if school_id column exists in users table
  select exists (
    select 1 from information_schema.columns 
    where table_schema = 'public'
      and table_name = 'users' 
      and column_name = 'school_id'
  ) into v_column_exists;
  
  if v_column_exists then
    -- Create policy for admins to view notifications
    execute '
      create policy "notifications_select_school_admin"
      on notifications for select
      to authenticated
      using (
        exists (
          select 1 from users 
          where users.auth_id = auth.uid() 
            and users.role in (''admin'', ''principal'')
            and users.school_id = notifications.school_id
        )
      )';
    
    -- Create policy for admins to insert notifications
    execute '
      create policy "notifications_insert_school_admin"
      on notifications for insert
      to authenticated
      with check (
        exists (
          select 1 from users 
          where users.auth_id = auth.uid() 
            and users.role in (''admin'', ''principal'')
            and users.school_id = notifications.school_id
        )
      )';
    
    raise notice 'Created notification policies with school_id check';
  else
    -- Create simpler policies without school_id check (fallback)
    execute '
      create policy "notifications_select_school_admin"
      on notifications for select
      to authenticated
      using (
        exists (
          select 1 from users 
          where users.auth_id = auth.uid() 
            and users.role in (''admin'', ''principal'')
        )
      )';
    
    execute '
      create policy "notifications_insert_school_admin"
      on notifications for insert
      to authenticated
      with check (
        exists (
          select 1 from users 
          where users.auth_id = auth.uid() 
            and users.role in (''admin'', ''principal'')
        )
      )';
    
    raise notice 'Created notification policies without school_id check (column does not exist)';
  end if;
end $$;

-- Notification Preferences - users manage their own
create policy "notification_preferences_select_own"
on notification_preferences for select
to authenticated
using (
  user_id in (
    select id from users where auth_id = auth.uid()
  )
);

create policy "notification_preferences_manage_own"
on notification_preferences for all
to authenticated
using (
  user_id in (
    select id from users where auth_id = auth.uid()
  )
)
with check (
  user_id in (
    select id from users where auth_id = auth.uid()
  )
);

-- =========================================================
-- 8. INSERT DEFAULT NOTIFICATION TEMPLATES
-- =========================================================

insert into notification_templates (template_key, name, description, category, email_subject, email_body, sms_body) values
  (
    'application_submitted',
    'Application Submitted',
    'Sent when a student submits an application',
    'application',
    'Application Submitted - {{school_name}}',
    'Dear {{student_name}},\n\nYour application to {{school_name}} has been successfully submitted.\n\nApplication ID: {{application_id}}\n\nWe will review your application and notify you of the status.\n\nThank you for your interest.',
    'Your application to {{school_name}} has been submitted. Application ID: {{application_id}}'
  ),
  (
    'application_approved',
    'Application Approved',
    'Sent when an application is approved',
    'application',
    'Congratulations! Your Application Has Been Approved - {{school_name}}',
    'Dear {{student_name}},\n\nWe are pleased to inform you that your application to {{school_name}} has been APPROVED.\n\nApplication ID: {{application_id}}\n\nNext Steps:\n- Complete your student registration\n- Submit required documents\n- Pay any applicable fees\n\nWelcome to {{school_name}}!',
    'Great news! Your application to {{school_name}} has been APPROVED. Application ID: {{application_id}}'
  ),
  (
    'application_rejected',
    'Application Rejected',
    'Sent when an application is rejected',
    'application',
    'Application Status Update - {{school_name}}',
    'Dear {{student_name}},\n\nWe regret to inform you that your application to {{school_name}} has not been approved at this time.\n\nApplication ID: {{application_id}}\n\nReason: {{rejection_reason}}\n\nIf you have any questions, please contact us.\n\nThank you for your interest.',
    'Your application to {{school_name}} was not approved. Application ID: {{application_id}}'
  ),
  (
    'application_under_review',
    'Application Under Review',
    'Sent when application status changes to under review',
    'application',
    'Application Under Review - {{school_name}}',
    'Dear {{student_name}},\n\nYour application to {{school_name}} is currently under review.\n\nApplication ID: {{application_id}}\n\nWe will notify you once a decision has been made.\n\nThank you for your patience.',
    'Your application to {{school_name}} is under review. Application ID: {{application_id}}'
  ),
  (
    'payment_required',
    'Payment Required',
    'Sent when payment is required',
    'payment',
    'Payment Required - {{school_name}}',
    'Dear {{student_name}},\n\nA payment is required for your application.\n\nAmount: {{amount}}\nDue Date: {{due_date}}\n\nPlease make the payment to complete your application process.',
    'Payment required: {{amount}} for application {{application_id}}. Due: {{due_date}}'
  ),
  (
    'payment_received',
    'Payment Received',
    'Sent when payment is received',
    'payment',
    'Payment Received - {{school_name}}',
    'Dear {{student_name}},\n\nWe have received your payment of {{amount}}.\n\nTransaction ID: {{transaction_id}}\n\nThank you for your payment.',
    'Payment of {{amount}} received. Transaction ID: {{transaction_id}}'
  ),
  (
    'welcome_student',
    'Welcome Student',
    'Sent to newly enrolled students',
    'student',
    'Welcome to {{school_name}}!',
    'Dear {{student_name}},\n\nWelcome to {{school_name}}!\n\nWe are excited to have you as part of our school community.\n\nYour student ID: {{student_id}}\nClass: {{class_name}}\nSection: {{section_name}}\n\nWe look forward to seeing you soon!',
    'Welcome to {{school_name}}! Your student ID: {{student_id}}, Class: {{class_name}}'
  ),
  (
    'document_uploaded',
    'Document Uploaded',
    'Sent when a document is uploaded',
    'student',
    'Document Uploaded - {{school_name}}',
    'Dear {{student_name}},\n\nA document has been uploaded to your profile.\n\nDocument: {{document_name}}\n\nPlease review and ensure all required documents are submitted.',
    'Document {{document_name}} uploaded to your profile.'
  )
on conflict (template_key) do nothing;

-- =========================================================
-- 9. TRIGGERS
-- =========================================================

drop trigger if exists update_notification_templates_updated_at on notification_templates;
create trigger update_notification_templates_updated_at
before update on notification_templates
for each row
execute function update_updated_at_column();

drop trigger if exists update_notification_preferences_updated_at on notification_preferences;
create trigger update_notification_preferences_updated_at
before update on notification_preferences
for each row
execute function update_updated_at_column();

-- =========================================================
-- 10. HELPER FUNCTIONS
-- =========================================================

-- Function to render template with variables
drop function if exists render_notification_template(text, jsonb);
create or replace function render_notification_template(
  p_template_key text,
  p_variables jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_template record;
  v_email_subject text;
  v_email_body text;
  v_sms_body text;
  v_result jsonb;
  v_key text;
  v_value text;
begin
  select * into v_template
  from notification_templates
  where template_key = p_template_key
    and is_active = true;

  if not found then
    raise exception 'Template not found: %', p_template_key;
  end if;

  -- Simple variable replacement ({{variable_name}})
  v_email_subject := v_template.email_subject;
  v_email_body := v_template.email_body;
  v_sms_body := v_template.sms_body;

  -- Replace variables in subject
  if v_email_subject is not null then
    for v_key, v_value in select * from jsonb_each_text(p_variables) loop
      v_email_subject := replace(v_email_subject, '{{' || v_key || '}}', v_value);
    end loop;
  end if;

  -- Replace variables in email body
  if v_email_body is not null then
    for v_key, v_value in select * from jsonb_each_text(p_variables) loop
      v_email_body := replace(v_email_body, '{{' || v_key || '}}', v_value);
    end loop;
  end if;

  -- Replace variables in SMS body
  if v_sms_body is not null then
    for v_key, v_value in select * from jsonb_each_text(p_variables) loop
      v_sms_body := replace(v_sms_body, '{{' || v_key || '}}', v_value);
    end loop;
  end if;

  v_result := jsonb_build_object(
    'email_subject', v_email_subject,
    'email_body', v_email_body,
    'sms_body', v_sms_body
  );

  return v_result;
end;
$$;

grant execute on function render_notification_template to authenticated;
grant execute on function render_notification_template to anon;

