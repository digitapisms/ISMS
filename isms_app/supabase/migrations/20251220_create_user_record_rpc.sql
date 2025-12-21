-- Create missing RPC used during signup to create app-level user row.
-- This matches the Flutter app call: rpc('create_user_record', { p_auth_id, p_email, p_role, p_school_id })

create or replace function public.create_user_record(
  p_auth_id uuid,
  p_email text,
  p_role text,
  p_school_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_email text;
  v_user_id uuid;
  v_requires_school boolean;
  v_school_ok boolean;
begin
  v_role := lower(trim(coalesce(p_role, '')));
  v_email := lower(trim(coalesce(p_email, '')));

  if v_email = '' then
    raise exception 'Email is required';
  end if;

  if v_role = '' then
    raise exception 'Role is required';
  end if;

  v_requires_school := v_role in ('student','parent','teacher','staff','admin','principal');
  if v_requires_school and p_school_id is null then
    raise exception 'School context is required for role %', v_role;
  end if;

  if p_school_id is not null then
    select exists(
      select 1 from public.schools s
      where s.id = p_school_id
        and lower(coalesce(s.status,'')) = 'active'
    ) into v_school_ok;

    if not v_school_ok then
      raise exception 'School not found or not active';
    end if;
  end if;

  insert into public.users (
    auth_id,
    email,
    role,
    school_id,
    status,
    created_at,
    last_login_at
  )
  values (
    p_auth_id,
    v_email,
    v_role,
    p_school_id,
    'active',
    now(),
    null
  )
  on conflict (auth_id)
  do update set
    email = excluded.email,
    role = excluded.role,
    school_id = excluded.school_id,
    status = coalesce(public.users.status, excluded.status)
  returning id into v_user_id;

  -- Ensure a user_profile row exists for joins used throughout the UI.
  if not exists (select 1 from public.user_profiles up where up.user_id = v_user_id) then
    insert into public.user_profiles (user_id, full_name, created_at, updated_at)
    values (v_user_id, null, now(), now());
  end if;

  return v_user_id;
end;
$$;

grant execute on function public.create_user_record(uuid, text, text, uuid) to anon;
grant execute on function public.create_user_record(uuid, text, text, uuid) to authenticated;

