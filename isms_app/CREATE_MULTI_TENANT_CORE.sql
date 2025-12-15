-- =============================================================
-- MULTI-TENANT CORE (Tenants, Settings, Domains, Usage)
-- =============================================================

-- 1. Ensure schools table exists (acts as tenant master)
create table if not exists schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null unique,
  phone text not null,
  status text not null default 'pending',
  subscription_plan text not null default 'free',
  subscription_expires_at timestamptz,
  logo_url text,
  address text,
  city text,
  state text,
  country text default 'Pakistan',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists update_schools_updated_at on schools;
create trigger update_schools_updated_at
before update on schools
for each row execute function update_updated_at_column();

alter table schools enable row level security;

drop policy if exists schools_select_visible on schools;
create policy schools_select_visible
on schools
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = schools.id
  )
  or exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.role = 'super_admin'
  )
);

-- 2. Tenant settings / configuration
create table if not exists tenant_settings (
  school_id uuid primary key references schools(id) on delete cascade,
  timezone text not null default 'Asia/Karachi',
  locale text not null default 'en',
  currency text not null default 'PKR',
  academic_year_start date,
  academic_year_end date,
  feature_flags jsonb not null default '{}'::jsonb,
  preferences jsonb not null default '{}'::jsonb,
  branding jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists update_tenant_settings_updated_at on tenant_settings;
create trigger update_tenant_settings_updated_at
before update on tenant_settings
for each row execute function update_updated_at_column();

alter table tenant_settings enable row level security;

drop policy if exists tenant_settings_select_school on tenant_settings;
create policy tenant_settings_select_school
on tenant_settings
for select
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

drop policy if exists tenant_settings_manage_school on tenant_settings;
create policy tenant_settings_manage_school
on tenant_settings
for all
using (
  school_id in (
    select school_id from users
    where auth_id = auth.uid()
      and role in ('admin','principal')
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
) with check (
  school_id in (
    select school_id from users
    where auth_id = auth.uid()
      and role in ('admin','principal')
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

-- 3. Tenant domains (custom subdomains / hostnames)
create table if not exists tenant_domains (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  domain text not null unique,
  is_primary boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_tenant_domains_school on tenant_domains(school_id);

alter table tenant_domains enable row level security;

drop policy if exists tenant_domains_select_school on tenant_domains;
create policy tenant_domains_select_school
on tenant_domains
for select
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

drop policy if exists tenant_domains_manage_school on tenant_domains;
create policy tenant_domains_manage_school
on tenant_domains
for all
using (
  school_id in (
    select school_id from users
    where auth_id = auth.uid()
      and role in ('admin','principal')
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
) with check (
  school_id in (
    select school_id from users
    where auth_id = auth.uid()
      and role in ('admin','principal')
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

-- 4. Tenant feature usage / AI metering
create table if not exists tenant_usage_logs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  usage_type text not null, -- ai_chat, homework_explain, etc.
  units integer not null default 0,
  cost numeric(18,4),
  metadata jsonb,
  occurred_at timestamptz not null default now()
);

create index if not exists idx_tenant_usage_logs_school
  on tenant_usage_logs(school_id, usage_type);

alter table tenant_usage_logs enable row level security;

drop policy if exists tenant_usage_logs_select_school on tenant_usage_logs;
create policy tenant_usage_logs_select_school
on tenant_usage_logs
for select
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

drop policy if exists tenant_usage_logs_insert_school on tenant_usage_logs;
create policy tenant_usage_logs_insert_school
on tenant_usage_logs
for insert
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users
    where auth_id = auth.uid()
      and role = 'super_admin'
  )
);

-- 5. View to expose tenants with merged settings
drop view if exists tenants cascade;
create view tenants as
select
  s.id as id,
  s.name,
  s.email,
  s.phone,
  s.status,
  s.subscription_plan,
  s.subscription_expires_at,
  ts.timezone,
  ts.locale,
  ts.currency,
  ts.feature_flags,
  ts.preferences,
  ts.branding,
  s.created_at,
  s.updated_at
from schools s
left join tenant_settings ts on ts.school_id = s.id;

grant select on tenants to anon, authenticated;

-- 6. Helper function to upsert tenant settings
drop function if exists upsert_tenant_settings(uuid, jsonb);
create or replace function upsert_tenant_settings(
  p_school_id uuid,
  p_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into tenant_settings (school_id)
  values (p_school_id)
  on conflict (school_id) do nothing;

  update tenant_settings
  set
    timezone = coalesce(p_payload->>'timezone', timezone),
    locale = coalesce(p_payload->>'locale', locale),
    currency = coalesce(p_payload->>'currency', currency),
    academic_year_start = coalesce(
      (p_payload->>'academic_year_start')::date,
      academic_year_start
    ),
    academic_year_end = coalesce(
      (p_payload->>'academic_year_end')::date,
      academic_year_end
    ),
    feature_flags = feature_flags || coalesce(p_payload->'feature_flags', '{}'::jsonb),
    preferences = preferences || coalesce(p_payload->'preferences', '{}'::jsonb),
    branding = branding || coalesce(p_payload->'branding', '{}'::jsonb),
    updated_at = now()
  where school_id = p_school_id;
end;
$function$;

grant execute on function upsert_tenant_settings(uuid, jsonb) to authenticated;

-- 7. AI prompt registry
create table if not exists ai_prompts (
  id uuid primary key default gen_random_uuid(),
  prompt_key text not null unique,
  name text not null,
  description text,
  prompt_yaml text not null,
  version integer not null default 1,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists update_ai_prompts_updated_at on ai_prompts;
create trigger update_ai_prompts_updated_at
before update on ai_prompts
for each row execute function update_updated_at_column();

alter table ai_prompts enable row level security;

drop policy if exists ai_prompts_select_all on ai_prompts;
create policy ai_prompts_select_all
on ai_prompts
for select
to authenticated
using (true);

drop policy if exists ai_prompts_manage_admin on ai_prompts;
create policy ai_prompts_manage_admin
on ai_prompts
for all
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.role = 'super_admin'
  )
) with check (true);

-- 8. AI task queue
create table if not exists ai_tasks (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  user_id uuid references users(id) on delete set null,
  prompt_key text not null references ai_prompts(prompt_key),
  status text not null default 'queued',
  input jsonb not null,
  output jsonb,
  error_message text,
  tokens_used integer,
  cost numeric(18,4),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz
);

create index if not exists idx_ai_tasks_school on ai_tasks(school_id);
create index if not exists idx_ai_tasks_status on ai_tasks(status);

alter table ai_tasks enable row level security;

drop policy if exists ai_tasks_select_school on ai_tasks;
create policy ai_tasks_select_school
on ai_tasks
for select
using (
  school_id = current_user_school_id()
  or current_user_role() = 'super_admin'
);

drop policy if exists ai_tasks_insert_school on ai_tasks;
create policy ai_tasks_insert_school
on ai_tasks
for insert
with check (
  school_id = current_user_school_id()
  or current_user_role() = 'super_admin'
);

drop policy if exists ai_tasks_update_school on ai_tasks;
create policy ai_tasks_update_school
on ai_tasks
for update
using (
  school_id = current_user_school_id()
  or current_user_role() = 'super_admin'
) with check (
  school_id = current_user_school_id()
  or current_user_role() = 'super_admin'
);

-- Seed initial prompts (replace prompt_yaml with actual templates later)
insert into ai_prompts (prompt_key, name, description, prompt_yaml)
values
  ('ai_chat', 'AI Tutor Chat', 'General tutoring chat for students and teachers.', '# ai_chat prompt yaml'),
  ('homework_explain', 'Homework Explainer', 'Explain homework step-by-step using student context.', '# homework_explain prompt yaml'),
  ('notice_generator', 'Notice Generator', 'Generate official school notices.', '# notice_generator prompt yaml'),
  ('timetable_solver', 'Timetable Solver', 'Optimize schedule assignments.', '# timetable_solver prompt yaml')
on conflict (prompt_key) do update set
  name = excluded.name,
  description = excluded.description,
  prompt_yaml = excluded.prompt_yaml,
  updated_at = now();

