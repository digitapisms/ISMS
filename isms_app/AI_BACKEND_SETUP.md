# AI Backend Integration Setup Guide

This guide explains how to set up the AI backend processing system for the ISMS application.

## Overview

The AI backend integration consists of:
1. **Supabase Edge Function** (`process-ai-task`) - Processes AI tasks by calling LLM APIs
2. **Database Functions** - Automatically trigger processing when tasks are created
3. **Scheduled Jobs** (optional) - Process pending tasks periodically

## Step 1: Deploy Edge Function

### Prerequisites
- Supabase CLI installed
- Supabase project initialized

### Deploy Command
```bash
cd isms_app
supabase functions deploy process-ai-task
```

### Set Environment Variables
In Supabase Dashboard → Edge Functions → process-ai-task → Settings:

**Required:**
- `OPENAI_API_KEY` - Your OpenAI API key (or use `ANTHROPIC_API_KEY` for Anthropic)
- `SUPABASE_URL` - Your Supabase project URL (auto-set)
- `SUPABASE_SERVICE_ROLE_KEY` - Your service role key (auto-set)

**Optional:**
- `AI_PROVIDER` - `openai` (default) or `anthropic`
- `OPENAI_MODEL` - Model name (default: `gpt-4o-mini`)
- `ANTHROPIC_MODEL` - Model name (default: `claude-3-haiku-20240307`)

## Step 2: Run Database Migration

Execute the SQL script to set up database functions and triggers:

```sql
-- Run this in Supabase SQL Editor
\i CREATE_AI_BACKEND_INTEGRATION_SIMPLE.sql
```

Or manually run the SQL file from the Supabase Dashboard.

## Step 3: Configure Database Settings

Run these commands as a database superuser (in Supabase SQL Editor):

```sql
-- Set your Supabase project URL
ALTER DATABASE postgres SET app.supabase_url = 'https://your-project-id.supabase.co';

-- Set your service role key (get from Supabase Dashboard → Settings → API)
ALTER DATABASE postgres SET app.service_role_key = 'your-service-role-key-here';
```

**Note:** For security, consider using Supabase Vault or environment variables instead of storing the service role key in the database.

## Step 4: Set Up Automatic Processing

Choose one of the following methods:

### Option A: Webhook (Recommended)

1. Go to Supabase Dashboard → Database → Webhooks
2. Create a new webhook:
   - **Name:** `process-ai-tasks`
   - **Table:** `ai_tasks`
   - **Events:** `INSERT`
   - **Type:** `HTTP Request`
   - **URL:** `https://your-project-id.supabase.co/functions/v1/process-ai-task`
   - **Method:** `POST`
   - **Headers:**
     ```
     Content-Type: application/json
     Authorization: Bearer YOUR_SERVICE_ROLE_KEY
     ```
   - **Body:**
     ```json
     {"taskId": "{{NEW.id}}"}
     ```

### Option B: pg_cron (Alternative)

If `pg_cron` extension is enabled:

```sql
-- Schedule job to process pending tasks every 30 seconds
SELECT cron.schedule(
  'process-ai-tasks',
  '*/30 * * * *',  -- Cron expression: every 30 seconds
  $$SELECT process_pending_ai_tasks_batch(5)$$
);
```

### Option C: Manual Processing

You can manually trigger processing:

```sql
-- Process up to 5 pending tasks
SELECT * FROM process_pending_ai_tasks_batch(5);

-- Retry a specific failed task
SELECT retry_failed_ai_task('task-id-here');
```

## Step 5: Test the Integration

1. **Create a test task** via the Flutter app (AI Chat screen)
2. **Check task status:**
   ```sql
   SELECT id, status, error_message, output
   FROM ai_tasks
   ORDER BY created_at DESC
   LIMIT 5;
   ```
3. **Monitor Edge Function logs:**
   - Supabase Dashboard → Edge Functions → process-ai-task → Logs

## Troubleshooting

### Tasks stuck in "pending" status

1. **Check Edge Function logs** for errors
2. **Verify environment variables** are set correctly
3. **Check database settings:**
   ```sql
   SELECT current_setting('app.supabase_url', true) as supabase_url;
   SELECT current_setting('app.service_role_key', true) as has_key;
   ```
4. **Manually trigger processing:**
   ```sql
   SELECT process_pending_ai_tasks_batch(1);
   ```

### Edge Function errors

1. **Check API keys** are valid
2. **Verify model names** are correct
3. **Check API quotas** and billing
4. **Review function logs** in Supabase Dashboard

### Database function errors

1. **Ensure extensions are enabled:**
   ```sql
   CREATE EXTENSION IF NOT EXISTS http;
   CREATE EXTENSION IF NOT EXISTS pg_net;
   ```
2. **Check permissions:**
   ```sql
   GRANT EXECUTE ON FUNCTION process_ai_task_via_edge_function(uuid) TO authenticated;
   ```

## Cost Considerations

- **OpenAI gpt-4o-mini:** ~$0.15 per 1M input tokens, $0.60 per 1M output tokens
- **Anthropic Claude Haiku:** ~$0.25 per 1M input tokens, $1.25 per 1M output tokens

Monitor usage in the `ai_tasks` table (`tokens_used` and `cost` columns).

## Security Notes

1. **Service Role Key:** Never expose in client-side code
2. **API Keys:** Store securely in Supabase environment variables
3. **RLS Policies:** Ensure `ai_tasks` table has proper RLS policies
4. **Rate Limiting:** Consider implementing rate limits per school/user

## Next Steps

- Set up monitoring and alerts for failed tasks
- Implement retry logic with exponential backoff
- Add cost tracking and budget limits per school
- Optimize prompt templates for better responses

