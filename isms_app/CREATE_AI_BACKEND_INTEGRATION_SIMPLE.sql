-- ============================================================
-- AI Backend Integration (Simplified Version)
-- This script sets up automatic processing of AI tasks
-- Uses Supabase Webhooks or pg_cron for scheduled processing
-- ============================================================

-- First, ensure we have the necessary extensions
-- Note: pg_net and pg_cron may need to be enabled by Supabase admin
create extension if not exists http;
create extension if not exists pg_net;

-- Function to call the Edge Function to process an AI task
-- This version uses pg_net for async HTTP calls (preferred)
create or replace function process_ai_task_via_edge_function(task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  edge_function_url text;
  supabase_url text;
  service_role_key text;
begin
  -- Get Supabase URL from environment
  -- In Supabase, this is typically available via current_setting
  -- For local development, you may need to set it manually
  supabase_url := coalesce(
    current_setting('app.supabase_url', true),
    current_setting('app.supabase_project_url', true),
    '' -- Will need to be configured
  );
  
  -- Get service role key (should be stored securely)
  service_role_key := coalesce(
    current_setting('app.service_role_key', true),
    '' -- Will need to be configured
  );
  
  if supabase_url = '' or service_role_key = '' then
    raise warning 'Supabase URL or service role key not configured. Task % will not be processed automatically.', task_id;
    return;
  end if;
  
  edge_function_url := supabase_url || '/functions/v1/process-ai-task';
  
  -- Use pg_net for async HTTP request (if available)
  begin
    perform net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object('taskId', task_id)::text
    );
  exception
    when others then
      -- Fallback: log error
      raise warning 'Failed to queue AI task % for processing: %', task_id, sqlerrm;
  end;
end;
$$;

-- Alternative: Simple trigger that marks tasks for processing
-- The actual processing will be done via pg_cron or webhook
create or replace function mark_ai_task_for_processing()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Ensure status is set correctly
  if new.status in ('queued', 'pending') then
    -- The task is ready for processing
    -- Processing will be triggered by pg_cron or webhook
    null; -- No action needed here, just ensure status is correct
  end if;
  
  return new;
end;
$$;

-- Create trigger to ensure tasks are marked correctly
drop trigger if exists ai_tasks_mark_for_processing on ai_tasks;
create trigger ai_tasks_mark_for_processing
after insert on ai_tasks
for each row
when (new.status in ('queued', 'pending'))
execute function mark_ai_task_for_processing();

-- Function to process pending tasks (to be called by pg_cron or webhook)
create or replace function process_pending_ai_tasks_batch(batch_size int default 5)
returns table(
  task_id uuid,
  status text,
  error_message text
)
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
    select id, prompt_key, school_id
    from ai_tasks
    where status in ('pending', 'queued')
    order by created_at asc
    limit batch_size
    for update skip locked  -- Prevent concurrent processing
  loop
    begin
      -- Queue task for processing via Edge Function
      perform process_ai_task_via_edge_function(task_record.id);
      
      -- Return success
      task_id := task_record.id;
      status := 'queued_for_processing';
      error_message := null;
      return next;
      
      processed_count := processed_count + 1;
    exception
      when others then
        -- Return error
        task_id := task_record.id;
        status := 'error';
        error_message := sqlerrm;
        return next;
    end;
  end loop;
  
  -- If no tasks found, return empty
  if processed_count = 0 then
    return;
  end if;
end;
$$;

-- Function to manually retry a failed task
create or replace function retry_failed_ai_task(task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Reset task to pending
  update ai_tasks
  set 
    status = 'pending',
    error_message = null,
    started_at = null,
    completed_at = null,
    output = null
  where id = task_id
    and status = 'failed';
  
  -- Queue for processing
  perform process_ai_task_via_edge_function(task_id);
end;
$$;

-- Grant permissions
grant execute on function process_ai_task_via_edge_function(uuid) to authenticated;
grant execute on function process_pending_ai_tasks_batch(int) to authenticated;
grant execute on function retry_failed_ai_task(uuid) to authenticated;

-- Comments
comment on function process_ai_task_via_edge_function(uuid) is 
  'Queues an AI task for processing via Edge Function. Requires app.supabase_url and app.service_role_key to be configured.';

comment on function process_pending_ai_tasks_batch(int) is 
  'Processes a batch of pending AI tasks. Designed to be called by pg_cron or webhook.';

comment on function retry_failed_ai_task(uuid) is 
  'Resets and retries a failed AI task.';

-- ============================================================
-- SETUP INSTRUCTIONS:
-- ============================================================
-- 1. Deploy the Edge Function:
--    supabase functions deploy process-ai-task
--
-- 2. Set environment variables in Supabase Dashboard:
--    - OPENAI_API_KEY (or ANTHROPIC_API_KEY)
--    - AI_PROVIDER (openai or anthropic)
--    - OPENAI_MODEL (default: gpt-4o-mini)
--    - ANTHROPIC_MODEL (default: claude-3-haiku-20240307)
--
-- 3. Configure database settings (run as superuser):
--    ALTER DATABASE postgres SET app.supabase_url = 'https://your-project.supabase.co';
--    ALTER DATABASE postgres SET app.service_role_key = 'your-service-role-key';
--
-- 4. Set up pg_cron job (optional, for automatic processing):
--    SELECT cron.schedule(
--      'process-ai-tasks',
--      '*/30 * * * *',  -- Every 30 seconds
--      $$SELECT process_pending_ai_tasks_batch(5)$$
--    );
--
-- 5. Or set up a webhook in Supabase Dashboard:
--    - Table: ai_tasks
--    - Event: INSERT
--    - Type: HTTP Request
--    - URL: https://your-project.supabase.co/functions/v1/process-ai-task
--    - Method: POST
--    - Headers: Authorization: Bearer YOUR_SERVICE_ROLE_KEY
--    - Body: {"taskId": "{{NEW.id}}"}
-- ============================================================

