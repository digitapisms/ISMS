-- SQL script to help verify webhook setup
-- Note: Webhooks must be created via Supabase Dashboard
-- This script helps verify the setup

-- Check if ai_tasks table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_tasks')
        THEN '✅ ai_tasks table exists'
        ELSE '❌ ai_tasks table not found'
    END as table_check;

-- Check pending tasks (should be processed by webhook)
SELECT 
    COUNT(*) as pending_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️  There are pending tasks - webhook should process them'
        ELSE '✅ No pending tasks'
    END as status
FROM ai_tasks
WHERE status IN ('pending', 'queued');

-- Check recent tasks to see if processing is working
SELECT 
    id,
    status,
    prompt_key,
    created_at,
    CASE 
        WHEN status = 'completed' THEN '✅ Processed'
        WHEN status = 'failed' THEN '❌ Failed'
        WHEN status = 'processing' THEN '⏳ Processing'
        ELSE '⏸️  Pending'
    END as processing_status
FROM ai_tasks
ORDER BY created_at DESC
LIMIT 5;

-- Check for stuck tasks (pending for more than 5 minutes)
SELECT 
    COUNT(*) as stuck_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️  Found stuck tasks - webhook may not be working'
        ELSE '✅ No stuck tasks'
    END as status
FROM ai_tasks
WHERE status IN ('pending', 'queued')
AND created_at < NOW() - INTERVAL '5 minutes';

-- Instructions
SELECT 
    '📝 Webhook Setup Instructions:' as instruction,
    '1. Go to Supabase Dashboard → Database → Webhooks' as step1,
    '2. Create new webhook for ai_tasks table' as step2,
    '3. Event: INSERT' as step3,
    '4. URL: https://YOUR-PROJECT.supabase.co/functions/v1/process-ai-task' as step4,
    '5. Method: POST' as step5,
    '6. Headers: Authorization: Bearer YOUR_SERVICE_ROLE_KEY' as step6,
    '7. Body: {"taskId": "{{NEW.id}}"' as step7;

