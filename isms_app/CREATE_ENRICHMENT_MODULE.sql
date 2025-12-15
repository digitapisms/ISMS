-- =============================================================
-- ENRICHMENT & PLAY MODULE
-- =============================================================
-- This module provides quizzes, games, clubs, and rewards
-- for student engagement and informal learning.
--
-- PREREQUISITES (RUN THESE IN ORDER):
-- 1. CREATE_AUTH_ROLES_SCHEMA.sql (defines current_user_school_id, current_user_role)
-- 2. CREATE_MULTI_TENANT_CORE.sql (creates schools table and tenant infrastructure)
-- 3. PREREQUISITE_FOR_ENRICHMENT.sql (MUST RUN THIS FIRST - adds school_id to students/classes)
-- 4. Then run this script (CREATE_ENRICHMENT_MODULE.sql)
--
-- IMPORTANT: PostgreSQL validates column references at PARSE TIME.
-- You MUST run PREREQUISITE_FOR_ENRICHMENT.sql first to ensure
-- students.school_id and classes.school_id exist before this script runs.

-- =============================================================
-- PREREQUISITE VERIFICATION: Fail immediately if columns don't exist
-- =============================================================
-- This is a SAFETY CHECK only. The columns MUST already exist
-- (added by PREREQUISITE_FOR_ENRICHMENT.sql) because PostgreSQL
-- validates column references at PARSE TIME, not execution time.

do $$
begin
  -- Verify schools table exists
  if not exists (
    select 1 from information_schema.tables 
    where table_name = 'schools' and table_schema = 'public'
  ) then
    raise exception 'CRITICAL: schools table does not exist. Please run CREATE_MULTI_TENANT_CORE.sql first.';
  end if;

  -- Verify students.school_id exists (CRITICAL - referenced in policies)
  if exists (
    select 1 from information_schema.tables 
    where table_name = 'students' and table_schema = 'public'
  ) then
    if not exists (
      select 1 from information_schema.columns
      where table_name = 'students' and column_name = 'school_id' and table_schema = 'public'
    ) then
      raise exception 'CRITICAL: students.school_id column does not exist. 

YOU MUST RUN PREREQUISITE_FOR_ENRICHMENT.sql FIRST!

This column must exist BEFORE this script runs because PostgreSQL
validates column references at parse time. Run:
  1. PREREQUISITE_FOR_ENRICHMENT.sql
  2. Then re-run this script';
    end if;
  end if;

  -- Verify classes.school_id exists (if classes table exists)
  if exists (
    select 1 from information_schema.tables 
    where table_name = 'classes' and table_schema = 'public'
  ) then
    if not exists (
      select 1 from information_schema.columns
      where table_name = 'classes' and column_name = 'school_id' and table_schema = 'public'
    ) then
      raise exception 'CRITICAL: classes.school_id column does not exist. Please run PREREQUISITE_FOR_ENRICHMENT.sql first.';
    end if;
  end if;

  raise notice 'Prerequisite verification passed: All required columns exist.';
end $$;

-- Helper function for updated_at triggers (if not exists)
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
$$;

-- =============================================================
-- 1. ENRICHMENT CATEGORIES
-- =============================================================
create table if not exists enrichment_categories (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  description text,
  icon text,
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enrichment_categories_school_name_unique unique (school_id, name)
);

create index if not exists idx_enrichment_categories_school_id
  on enrichment_categories(school_id);

create index if not exists idx_enrichment_categories_active
  on enrichment_categories(school_id, is_active, display_order);

drop trigger if exists update_enrichment_categories_updated_at on enrichment_categories;
create trigger update_enrichment_categories_updated_at
  before update on enrichment_categories
  for each row execute function update_updated_at_column();

alter table enrichment_categories enable row level security;

drop policy if exists enrichment_categories_select_school on enrichment_categories;
create policy enrichment_categories_select_school
  on enrichment_categories
  for select
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists enrichment_categories_insert_admin on enrichment_categories;
create policy enrichment_categories_insert_admin
  on enrichment_categories
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists enrichment_categories_update_admin on enrichment_categories;
create policy enrichment_categories_update_admin
  on enrichment_categories
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists enrichment_categories_delete_admin on enrichment_categories;
create policy enrichment_categories_delete_admin
  on enrichment_categories
  for delete
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 2. QUIZZES
-- =============================================================
create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  category_id uuid references enrichment_categories(id) on delete set null,
  title text not null,
  description text,
  mode text not null default 'practice', -- 'practice' or 'live'
  visibility text not null default 'public', -- 'public', 'class', 'private'
  target_class_id uuid references classes(id) on delete set null,
  created_by uuid not null references users(id) on delete restrict,
  ai_prompt_key text, -- references ai_prompts.prompt_key if AI-generated
  time_limit_seconds integer, -- null = no limit
  passing_score_percent integer default 50,
  max_attempts integer, -- null = unlimited
  status text not null default 'draft', -- 'draft', 'published', 'archived'
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_quizzes_school_id
  on quizzes(school_id);

create index if not exists idx_quizzes_category_id
  on quizzes(category_id);

create index if not exists idx_quizzes_created_by
  on quizzes(created_by);

create index if not exists idx_quizzes_status
  on quizzes(school_id, status, created_at desc);

drop trigger if exists update_quizzes_updated_at on quizzes;
create trigger update_quizzes_updated_at
  before update on quizzes
  for each row execute function update_updated_at_column();

alter table quizzes enable row level security;

drop policy if exists quizzes_select_school on quizzes;
create policy quizzes_select_school
  on quizzes
  for select
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quizzes_insert_teacher on quizzes;
create policy quizzes_insert_teacher
  on quizzes
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quizzes_update_teacher on quizzes;
create policy quizzes_update_teacher
  on quizzes
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quizzes_delete_admin on quizzes;
create policy quizzes_delete_admin
  on quizzes
  for delete
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 3. QUIZ QUESTIONS
-- =============================================================
create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  question_type text not null, -- 'multiple_choice', 'true_false', 'short_answer'
  question_text text not null,
  options jsonb, -- for multiple_choice: ["A", "B", "C", "D"]
  correct_answer text not null, -- answer key
  points integer not null default 1,
  explanation text, -- shown after submission
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_quiz_questions_quiz_id
  on quiz_questions(quiz_id, display_order);

drop trigger if exists update_quiz_questions_updated_at on quiz_questions;
create trigger update_quiz_questions_updated_at
  before update on quiz_questions
  for each row execute function update_updated_at_column();

alter table quiz_questions enable row level security;

drop policy if exists quiz_questions_select_quiz on quiz_questions;
create policy quiz_questions_select_quiz
  on quiz_questions
  for select
  to authenticated
  using (
    exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_questions.quiz_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quiz_questions_insert_teacher on quiz_questions;
create policy quiz_questions_insert_teacher
  on quiz_questions
  for insert
  to authenticated
  with check (
    exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_questions.quiz_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quiz_questions_update_teacher on quiz_questions;
create policy quiz_questions_update_teacher
  on quiz_questions
  for update
  to authenticated
  using (
    exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_questions.quiz_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quiz_questions_delete_teacher on quiz_questions;
create policy quiz_questions_delete_teacher
  on quiz_questions
  for delete
  to authenticated
  using (
    exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_questions.quiz_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 4. QUIZ ATTEMPTS
-- =============================================================
create table if not exists quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  score integer not null default 0,
  total_points integer not null default 0,
  percentage numeric(5, 2) not null,
  answers jsonb not null default '{}'::jsonb, -- {question_id: "answer"}
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  time_taken_seconds integer,
  status text not null default 'in_progress', -- 'in_progress', 'completed', 'abandoned'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_quiz_attempts_quiz_id
  on quiz_attempts(quiz_id);

create index if not exists idx_quiz_attempts_student_id
  on quiz_attempts(student_id);

create index if not exists idx_quiz_attempts_status
  on quiz_attempts(quiz_id, student_id, status, submitted_at desc);

drop trigger if exists update_quiz_attempts_updated_at on quiz_attempts;
create trigger update_quiz_attempts_updated_at
  before update on quiz_attempts
  for each row execute function update_updated_at_column();

alter table quiz_attempts enable row level security;

drop policy if exists quiz_attempts_select_own on quiz_attempts;
create policy quiz_attempts_select_own
  on quiz_attempts
  for select
  to authenticated
  using (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = quiz_attempts.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_attempts.quiz_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quiz_attempts_insert_student on quiz_attempts;
create policy quiz_attempts_insert_student
  on quiz_attempts
  for insert
  to authenticated
  with check (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = quiz_attempts.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists quiz_attempts_update_student on quiz_attempts;
create policy quiz_attempts_update_student
  on quiz_attempts
  for update
  to authenticated
  using (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = quiz_attempts.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from quizzes q
      join users u on u.school_id = q.school_id
      where q.id = quiz_attempts.quiz_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 5. GAMES
-- =============================================================
create table if not exists games (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  title text not null,
  description text,
  game_type text not null, -- 'embedded_url', 'built_in', 'external'
  game_url text, -- for embedded/external games
  min_age integer,
  max_age integer,
  subject_tags text[], -- e.g., ['math', 'vocabulary']
  config jsonb default '{}'::jsonb, -- game-specific settings
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_games_school_id
  on games(school_id);

create index if not exists idx_games_active
  on games(school_id, is_active, display_order);

drop trigger if exists update_games_updated_at on games;
create trigger update_games_updated_at
  before update on games
  for each row execute function update_updated_at_column();

alter table games enable row level security;

drop policy if exists games_select_school on games;
create policy games_select_school
  on games
  for select
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists games_insert_admin on games;
create policy games_insert_admin
  on games
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists games_update_admin on games;
create policy games_update_admin
  on games
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists games_delete_admin on games;
create policy games_delete_admin
  on games
  for delete
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 6. GAME SESSIONS
-- =============================================================
create table if not exists game_sessions (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references games(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  score integer,
  duration_seconds integer,
  metadata jsonb default '{}'::jsonb, -- game-specific data
  played_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_game_sessions_game_id
  on game_sessions(game_id);

create index if not exists idx_game_sessions_student_id
  on game_sessions(student_id);

create index if not exists idx_game_sessions_played_at
  on game_sessions(played_at desc);

alter table game_sessions enable row level security;

drop policy if exists game_sessions_select_own on game_sessions;
create policy game_sessions_select_own
  on game_sessions
  for select
  to authenticated
  using (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = game_sessions.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from games g
      join users u on u.school_id = g.school_id
      where g.id = game_sessions.game_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists game_sessions_insert_student on game_sessions;
create policy game_sessions_insert_student
  on game_sessions
  for insert
  to authenticated
  with check (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = game_sessions.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 7. CLUBS
-- =============================================================
create table if not exists clubs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  category_id uuid references enrichment_categories(id) on delete set null,
  name text not null,
  description text,
  mentor_id uuid references users(id) on delete set null,
  meeting_schedule text, -- e.g., "Every Monday 3-4 PM"
  capacity integer,
  tags text[],
  status text not null default 'active', -- 'active', 'inactive', 'archived'
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_clubs_school_id
  on clubs(school_id);

create index if not exists idx_clubs_mentor_id
  on clubs(mentor_id);

create index if not exists idx_clubs_status
  on clubs(school_id, status, created_at desc);

drop trigger if exists update_clubs_updated_at on clubs;
create trigger update_clubs_updated_at
  before update on clubs
  for each row execute function update_updated_at_column();

alter table clubs enable row level security;

drop policy if exists clubs_select_school on clubs;
create policy clubs_select_school
  on clubs
  for select
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists clubs_insert_admin on clubs;
create policy clubs_insert_admin
  on clubs
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists clubs_update_admin on clubs;
create policy clubs_update_admin
  on clubs
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists clubs_delete_admin on clubs;
create policy clubs_delete_admin
  on clubs
  for delete
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 8. CLUB MEMBERS
-- =============================================================
create table if not exists club_members (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  role text not null default 'member', -- 'member', 'mentor', 'assistant'
  status text not null default 'pending', -- 'pending', 'approved', 'rejected', 'left'
  joined_at timestamptz,
  left_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint club_members_club_user_unique unique (club_id, user_id)
);

create index if not exists idx_club_members_club_id
  on club_members(club_id);

create index if not exists idx_club_members_user_id
  on club_members(user_id);

create index if not exists idx_club_members_status
  on club_members(club_id, status);

drop trigger if exists update_club_members_updated_at on club_members;
create trigger update_club_members_updated_at
  before update on club_members
  for each row execute function update_updated_at_column();

alter table club_members enable row level security;

drop policy if exists club_members_select_club on club_members;
create policy club_members_select_club
  on club_members
  for select
  to authenticated
  using (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_members.club_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists club_members_insert_self on club_members;
create policy club_members_insert_self
  on club_members
  for insert
  to authenticated
  with check (
    user_id in (
      select id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_members.club_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists club_members_update_mentor on club_members;
create policy club_members_update_mentor
  on club_members
  for update
  to authenticated
  using (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_members.club_id
        and (c.mentor_id = u.id or u.role in ('admin', 'principal'))
        and u.auth_id = auth.uid()
    )
    or user_id in (
      select id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 9. CLUB EVENTS
-- =============================================================
create table if not exists club_events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references clubs(id) on delete cascade,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz,
  location text,
  max_participants integer,
  status text not null default 'scheduled', -- 'scheduled', 'completed', 'cancelled'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_club_events_club_id
  on club_events(club_id);

create index if not exists idx_club_events_start_time
  on club_events(start_time);

drop trigger if exists update_club_events_updated_at on club_events;
create trigger update_club_events_updated_at
  before update on club_events
  for each row execute function update_updated_at_column();

alter table club_events enable row level security;

drop policy if exists club_events_select_club on club_events;
create policy club_events_select_club
  on club_events
  for select
  to authenticated
  using (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_events.club_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists club_events_insert_mentor on club_events;
create policy club_events_insert_mentor
  on club_events
  for insert
  to authenticated
  with check (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_events.club_id
        and (c.mentor_id = u.id or u.role in ('admin', 'principal', 'teacher'))
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists club_events_update_mentor on club_events;
create policy club_events_update_mentor
  on club_events
  for update
  to authenticated
  using (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_events.club_id
        and (c.mentor_id = u.id or u.role in ('admin', 'principal', 'teacher'))
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists club_events_delete_mentor on club_events;
create policy club_events_delete_mentor
  on club_events
  for delete
  to authenticated
  using (
    exists (
      select 1 from clubs c
      join users u on u.school_id = c.school_id
      where c.id = club_events.club_id
        and (c.mentor_id = u.id or u.role in ('admin', 'principal'))
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 10. ACTIVITY REWARDS
-- =============================================================
create table if not exists activity_rewards (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  description text,
  points_required integer not null default 0,
  reward_type text, -- 'badge', 'privilege', 'physical', 'virtual'
  icon_url text,
  is_active boolean not null default true,
  stock_quantity integer, -- null = unlimited
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_activity_rewards_school_id
  on activity_rewards(school_id);

create index if not exists idx_activity_rewards_active
  on activity_rewards(school_id, is_active, points_required);

drop trigger if exists update_activity_rewards_updated_at on activity_rewards;
create trigger update_activity_rewards_updated_at
  before update on activity_rewards
  for each row execute function update_updated_at_column();

alter table activity_rewards enable row level security;

drop policy if exists activity_rewards_select_school on activity_rewards;
create policy activity_rewards_select_school
  on activity_rewards
  for select
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists activity_rewards_insert_admin on activity_rewards;
create policy activity_rewards_insert_admin
  on activity_rewards
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists activity_rewards_update_admin on activity_rewards;
create policy activity_rewards_update_admin
  on activity_rewards
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists activity_rewards_delete_admin on activity_rewards;
create policy activity_rewards_delete_admin
  on activity_rewards
  for delete
  to authenticated
  using (
    school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 11. STUDENT REWARDS (Redemptions)
-- =============================================================
create table if not exists student_rewards (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  reward_id uuid not null references activity_rewards(id) on delete restrict,
  points_spent integer not null,
  redeemed_at timestamptz not null default now(),
  status text not null default 'pending', -- 'pending', 'fulfilled', 'cancelled'
  fulfilled_by uuid references users(id) on delete set null,
  fulfilled_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_student_rewards_student_id
  on student_rewards(student_id);

create index if not exists idx_student_rewards_reward_id
  on student_rewards(reward_id);

create index if not exists idx_student_rewards_status
  on student_rewards(status, redeemed_at desc);

alter table student_rewards enable row level security;

drop policy if exists student_rewards_select_own on student_rewards;
create policy student_rewards_select_own
  on student_rewards
  for select
  to authenticated
  using (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = student_rewards.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from activity_rewards ar
      join schools sc on sc.id = ar.school_id
      join users u on u.school_id = sc.id
      where ar.id = student_rewards.reward_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists student_rewards_insert_student on student_rewards;
create policy student_rewards_insert_student
  on student_rewards
  for insert
  to authenticated
  with check (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = student_rewards.student_id
        and u.auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists student_rewards_update_admin on student_rewards;
create policy student_rewards_update_admin
  on student_rewards
  for update
  to authenticated
  using (
    exists (
      select 1 from activity_rewards ar
      join schools sc on sc.id = ar.school_id
      join users u on u.school_id = sc.id
      where ar.id = student_rewards.reward_id
        and u.auth_id = auth.uid()
        and u.role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 12. STUDENT ENGAGEMENT STATS
-- =============================================================
create table if not exists student_engagement_stats (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  school_id uuid not null references schools(id) on delete cascade,
  metric_key text not null, -- 'quizzes_taken', 'games_played', 'clubs_joined', 'points_earned', etc.
  metric_value numeric not null default 0,
  period text not null, -- 'daily', 'weekly', 'monthly', 'all_time'
  period_start timestamptz,
  period_end timestamptz,
  metadata jsonb default '{}'::jsonb,
  last_updated timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint student_engagement_stats_unique unique (student_id, metric_key, period, period_start)
);

create index if not exists idx_student_engagement_stats_student_id
  on student_engagement_stats(student_id);

create index if not exists idx_student_engagement_stats_school_id
  on student_engagement_stats(school_id);

create index if not exists idx_student_engagement_stats_metric
  on student_engagement_stats(school_id, metric_key, period, period_start);

alter table student_engagement_stats enable row level security;

drop policy if exists student_engagement_stats_select_own on student_engagement_stats;
create policy student_engagement_stats_select_own
  on student_engagement_stats
  for select
  to authenticated
  using (
    exists (
      select 1 from students s
      join users u on u.id = s.user_id
      where s.id = student_engagement_stats.student_id
        and u.auth_id = auth.uid()
    )
    or school_id in (
      select school_id from users
      where auth_id = auth.uid()
        and role in ('admin', 'principal', 'teacher')
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists student_engagement_stats_insert_system on student_engagement_stats;
create policy student_engagement_stats_insert_system
  on student_engagement_stats
  for insert
  to authenticated
  with check (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

drop policy if exists student_engagement_stats_update_system on student_engagement_stats;
create policy student_engagement_stats_update_system
  on student_engagement_stats
  for update
  to authenticated
  using (
    school_id in (
      select school_id from users where auth_id = auth.uid()
    )
    or exists (
      select 1 from users
      where auth_id = auth.uid() and role = 'super_admin'
    )
  );

-- =============================================================
-- 13. SEED DATA: Default Categories
-- =============================================================
-- Note: These will be created per-school when a school is set up
-- For now, we'll create a function to seed default categories

create or replace function seed_default_enrichment_categories(p_school_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into enrichment_categories (school_id, name, description, icon, display_order)
  values
    (p_school_id, 'STEM', 'Science, Technology, Engineering, and Mathematics activities', 'science', 1),
    (p_school_id, 'Arts & Creativity', 'Art, music, drama, and creative expression', 'palette', 2),
    (p_school_id, 'Sports & Fitness', 'Physical activities and sports clubs', 'fitness_center', 3),
    (p_school_id, 'Language & Literature', 'Reading, writing, and language learning', 'book', 4),
    (p_school_id, 'Social & Leadership', 'Debate, student council, and leadership programs', 'groups', 5),
    (p_school_id, 'Community Service', 'Volunteering and community engagement', 'volunteer_activism', 6)
  on conflict (school_id, name) do nothing;
end;
$$;

grant execute on function seed_default_enrichment_categories(uuid) to authenticated;

-- =============================================================
-- 14. HELPER FUNCTION: Award Points
-- =============================================================
-- Only create this function if students table and required columns exist
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_name = 'students' and table_schema = 'public'
  ) and exists (
    select 1 from information_schema.tables
    where table_name = 'student_engagement_stats' and table_schema = 'public'
  ) then
    execute '
      create or replace function award_student_points(
        p_student_id uuid,
        p_points integer,
        p_reason text,
        p_source_type text,
        p_source_id uuid
      )
      returns void
      language plpgsql
      security definer
      set search_path = public
      as $func$
      declare
        v_school_id uuid;
      begin
        -- Get school_id from student (try direct column first, then via class/user)
        select coalesce(
          s.school_id,
          (select school_id from classes where id = s.class_id),
          (select school_id from users where id = s.user_id)
        ) into v_school_id
        from students s
        where s.id = p_student_id;

        if v_school_id is null then
          raise exception ''Student not found or school_id could not be determined'';
        end if;

        -- Update or insert engagement stats
        insert into student_engagement_stats (
          student_id, school_id, metric_key, metric_value, period, period_start, period_end
        )
        values (
          p_student_id, v_school_id, ''points_earned'', p_points, ''all_time'', null, null
        )
        on conflict (student_id, metric_key, period, period_start)
        do update set
          metric_value = student_engagement_stats.metric_value + p_points,
          last_updated = now();

        -- Log to tenant_usage_logs if needed
        if exists (
          select 1 from information_schema.tables
          where table_name = ''tenant_usage_logs'' and table_schema = ''public''
        ) then
          insert into tenant_usage_logs (school_id, usage_type, usage_value, timestamp)
          values (v_school_id, ''enrichment_points_awarded'', p_points, now())
          on conflict do nothing;
        end if;
      end;
      $func$;
    ';

    execute 'grant execute on function award_student_points(uuid, integer, text, text, uuid) to authenticated;';
  end if;
exception
  when others then
    raise notice 'Could not create award_student_points function: %', sqlerrm;
end $$;


