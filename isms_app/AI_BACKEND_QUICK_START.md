# AI Backend Integration - Quick Start

## ✅ What's Been Set Up

1. **Edge Function** (`supabase/functions/process-ai-task/index.ts`)
   - Processes AI tasks by calling OpenAI/Anthropic APIs
   - Updates task status and stores responses
   - Handles errors gracefully

2. **Database Functions**
   - `retry_ai_task(uuid)` - Retry failed tasks
   - `get_pending_ai_tasks_count()` - Check pending tasks

3. **Flutter App Updates**
   - Tasks are created with `status: 'pending'`
   - UI polls for task completion

## 🚀 Next Steps (Required)

### 1. Deploy Edge Function

```bash
cd isms_app
supabase functions deploy process-ai-task
```

### 2. Set Environment Variables

In **Supabase Dashboard → Edge Functions → process-ai-task → Settings**:

**Required:**
- `OPENAI_API_KEY` = `your-openai-api-key`
- OR `ANTHROPIC_API_KEY` = `your-anthropic-api-key`

**Optional:**
- `AI_PROVIDER` = `openai` (default) or `anthropic`
- `OPENAI_MODEL` = `gpt-4o-mini` (default)
- `ANTHROPIC_MODEL` = `claude-3-haiku-20240307` (default)

### 3. Set Up Webhook (Recommended)

**Supabase Dashboard → Database → Webhooks → New Webhook:**

- **Name:** `process-ai-tasks`
- **Table:** `ai_tasks`
- **Events:** `INSERT`
- **Type:** `HTTP Request`
- **URL:** `https://YOUR-PROJECT-ID.supabase.co/functions/v1/process-ai-task`
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

**Get Service Role Key:** Supabase Dashboard → Settings → API → `service_role` key

### 4. Test It!

1. Open the Flutter app
2. Go to **AI Tutor Chat**
3. Send a message
4. Wait a few seconds
5. Check the response!

## 🔍 Verify It's Working

### Check Task Status
```sql
SELECT id, status, error_message, output->>'response' as response
FROM ai_tasks
ORDER BY created_at DESC
LIMIT 5;
```

### Check Edge Function Logs
**Supabase Dashboard → Edge Functions → process-ai-task → Logs**

### Manual Retry (if needed)
```sql
SELECT retry_ai_task('task-id-here');
```

## ⚠️ Troubleshooting

**Tasks stuck in "pending":**
- Check webhook is configured correctly
- Verify Edge Function is deployed
- Check Edge Function logs for errors
- Ensure API keys are set

**Edge Function errors:**
- Check API key is valid
- Verify model names are correct
- Check API quotas/billing

**No webhook option?**
- Use pg_cron (if enabled): See `AI_BACKEND_SETUP.md`
- Or manually call Edge Function from your app

## 📚 Full Documentation

See `AI_BACKEND_SETUP.md` for detailed setup instructions and advanced configuration.

