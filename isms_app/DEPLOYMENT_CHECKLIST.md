# AI Backend Deployment Checklist

Use this checklist to ensure everything is deployed correctly.

## ✅ Pre-Deployment

- [ ] Supabase CLI installed (`supabase --version`)
- [ ] Logged in to Supabase (`supabase login`)
- [ ] Project linked (`supabase link --project-ref YOUR_PROJECT_ID`)
- [ ] OpenAI or Anthropic API key obtained

## ✅ Edge Function Deployment

- [ ] Edge Function code exists (`supabase/functions/process-ai-task/index.ts`)
- [ ] Edge Function deployed (`supabase functions deploy process-ai-task`)
- [ ] Deployment successful (no errors)

## ✅ Environment Variables

- [ ] `OPENAI_API_KEY` set in Supabase Dashboard
  - OR `ANTHROPIC_API_KEY` set
- [ ] `AI_PROVIDER` set (optional, defaults to 'openai')
- [ ] `OPENAI_MODEL` set (optional, defaults to 'gpt-4o-mini')
- [ ] `ANTHROPIC_MODEL` set (optional, defaults to 'claude-3-haiku-20240307')

**Where to set:** Supabase Dashboard → Edge Functions → process-ai-task → Settings

## ✅ Database Setup

- [ ] Database migration applied (`CREATE_AI_BACKEND_INTEGRATION`)
- [ ] **Run legacy schema patch** `database/patches/20241121_add_missing_classes_columns.sql`
  - Ensures `classes.level` and `classes.description` columns exist
  - Prevents `PostgrestException PGRST204` when managing classes
- [ ] Functions exist:
  - [ ] `retry_ai_task(uuid)`
  - [ ] `get_pending_ai_tasks_count()`
- [ ] Can verify with: `SELECT retry_ai_task('test-id');`

## ✅ Webhook Configuration

- [ ] Webhook created in Supabase Dashboard
- [ ] Table: `ai_tasks`
- [ ] Event: `INSERT`
- [ ] Type: `HTTP Request`
- [ ] URL: `https://YOUR-PROJECT.supabase.co/functions/v1/process-ai-task`
- [ ] Method: `POST`
- [ ] Headers: `Authorization: Bearer YOUR_SERVICE_ROLE_KEY`
- [ ] Body: `{"taskId": "{{NEW.id}}"}`

**Where to create:** Supabase Dashboard → Database → Webhooks → New Webhook

## ✅ Testing

- [ ] Create test task via Flutter app
- [ ] Task appears in database with status 'pending'
- [ ] Webhook triggers (check webhook logs)
- [ ] Edge Function processes task (check Edge Function logs)
- [ ] Task status changes to 'processing' then 'completed'
- [ ] Response appears in Flutter app

## ✅ Verification Queries

Run these SQL queries to verify:

```sql
-- Check pending tasks
SELECT COUNT(*) FROM ai_tasks WHERE status IN ('pending', 'queued');

-- Check recent tasks
SELECT id, status, error_message, created_at 
FROM ai_tasks 
ORDER BY created_at DESC 
LIMIT 5;

-- Check if functions exist
SELECT proname FROM pg_proc WHERE proname LIKE '%ai_task%';
```

## 🐛 Troubleshooting

If something doesn't work:

1. **Tasks stuck in 'pending':**
   - [ ] Check webhook is configured correctly
   - [ ] Check webhook logs for errors
   - [ ] Verify Edge Function is deployed
   - [ ] Check Edge Function logs

2. **Edge Function errors:**
   - [ ] Verify API key is correct
   - [ ] Check API quotas/billing
   - [ ] Review Edge Function logs
   - [ ] Test Edge Function manually

3. **No response in app:**
   - [ ] Check task status in database
   - [ ] Verify polling is working
   - [ ] Check network connectivity
   - [ ] Review app logs

## 📞 Need Help?
 
- ✅ Fix configuration issues
- ✅ Debug errors
- ✅ Verify each step

Just ask! 🚀

