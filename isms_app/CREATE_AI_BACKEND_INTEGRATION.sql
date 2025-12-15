-- ============================================================
-- AI Backend Integration
-- This script sets up automatic processing of AI tasks
-- ============================================================

-- Function to call the Edge Function to process an AI task
create or replace function process_ai_task(task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  edge_function_url text;
  supabase_url text;
  service_role_key text;
  response jsonb;
begin
  -- Get Supabase configuration
  -- Note: In production, these should be stored securely (e.g., in vault or env vars)
  -- For now, we'll use a placeholder that needs to be configured
  supabase_url := current_setting('app.supabase_url', true);
  service_role_key := current_setting('app.service_role_key', true);
  
  -- If not set, try to get from environment or use a default
  if supabase_url is null or supabase_url = '' then
    -- This will need to be set via: ALTER DATABASE your_db SET app.supabase_url = 'https://your-project.supabase.co';
    raise exception 'Supabase URL not configured. Please set app.supabase_url';
  end if;
  
  edge_function_url := supabase_url || '/functions/v1/process-ai-task';
  
  -- Call the Edge Function via HTTP
  select content into response
  from http_post(
    edge_function_url,
    jsonb_build_object('taskId', task_id)::text,
    jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key
    )::text
  );
  
  -- Check response
  if response->>'error' is not null then
    raise exception 'Edge Function error: %', response->>'error';
  end if;
  
exception
  when others then
    -- Log error but don't fail the transaction
    raise warning 'Failed to process AI task %: %', task_id, sqlerrm;
end;
$$;

-- Alternative: Use pg_net extension for HTTP calls (if available)
-- This is more reliable than the http extension
create extension if not exists pg_net;

-- Function using pg_net (preferred if available)
create or replace function process_ai_task_async(task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  edge_function_url text;
  supabase_url text;
  service_role_key text;
  net_request_id bigint;
begin
  -- Get configuration
  supabase_url := current_setting('app.supabase_url', true);
  service_role_key := current_setting('app.service_role_key', true);
  
  if supabase_url is null or supabase_url = '' then
    raise exception 'Supabase URL not configured. Please set app.supabase_url';
  end if;
  
  edge_function_url := supabase_url || '/functions/v1/process-ai-task';
  
  -- Make async HTTP request using pg_net
  select net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key
    ),
    body := jsonb_build_object('taskId', task_id)
  ) into net_request_id;
  
  -- The request is now queued and will be processed asynchronously
  -- We don't wait for the response here
  
exception
  when others then
    raise warning 'Failed to queue AI task processing for %: %', task_id, sqlerrm;
end;
$$;

-- Trigger function to automatically process tasks when they're created
create or replace function trigger_process_ai_task()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only process tasks with status 'queued' or 'pending'
  if new.status in ('queued', 'pending') then
    -- Use async processing to avoid blocking the insert
    perform process_ai_task_async(new.id);
  end if;
  
  return new;
end;
$$;

-- Create trigger
drop trigger if exists ai_tasks_process_trigger on ai_tasks;
create trigger ai_tasks_process_trigger
after insert on ai_tasks
for each row
when (new.status in ('queued', 'pending'))
execute function trigger_process_ai_task();

-- Also create a function to manually retry failed tasks
create or replace function retry_ai_task(task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Reset task status and retry
  update ai_tasks
  set 
    status = 'pending',
    error_message = null,
    started_at = null,
    completed_at = null
  where id = task_id;
  
  -- Trigger processing
  perform process_ai_task_async(task_id);
end;
$$;

-- Function to process pending tasks (useful for batch processing or retries)
create or replace function process_pending_ai_tasks(limit_count int default 10)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  task_record record;
  processed_count int := 0;
begin
  -- Get pending tasks
  for task_record in
    select id
    from ai_tasks
    where status in ('pending', 'queued')
    order by created_at asc
    limit limit_count
  loop
    begin
      perform process_ai_task_async(task_record.id);
      processed_count := processed_count + 1;
    exception
      when others then
        raise warning 'Failed to process task %: %', task_record.id, sqlerrm;
    end;
  end loop;
  
  return processed_count;
end;
$$;

-- Grant execute permissions
grant execute on function process_ai_task(uuid) to authenticated;
grant execute on function process_ai_task_async(uuid) to authenticated;
grant execute on function retry_ai_task(uuid) to authenticated;
grant execute on function process_pending_ai_tasks(int) to authenticated;

-- Update task status default to 'pending' instead of 'queued' for consistency
-- (The schema already uses 'queued', but we'll support both)
comment on function process_ai_task(uuid) is 'Processes an AI task by calling the Edge Function. Requires app.supabase_url and app.service_role_key to be configured.';
comment on function process_ai_task_async(uuid) is 'Queues an AI task for async processing via Edge Function. Preferred method for automatic processing.';
comment on function trigger_process_ai_task() is 'Trigger function that automatically processes new AI tasks.';
comment on function retry_ai_task(uuid) is 'Resets and retries a failed AI task.';
comment on function process_pending_ai_tasks(int) is 'Batch processes pending AI tasks. Useful for manual retries or scheduled jobs.';

