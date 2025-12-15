# PowerShell script to verify AI Backend deployment
# Usage: .\scripts\verify-deployment.ps1

Write-Host "🔍 Verifying AI Backend Deployment..." -ForegroundColor Cyan

$errors = @()

# Check Edge Function exists
Write-Host "`n1. Checking Edge Function..." -ForegroundColor Yellow
if (Test-Path "supabase\functions\process-ai-task\index.ts") {
    Write-Host "   ✅ Edge Function code exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Edge Function code not found" -ForegroundColor Red
    $errors += "Edge Function code missing"
}

# Check database functions
Write-Host "`n2. Checking database functions..." -ForegroundColor Yellow
Write-Host "   Run this SQL to verify:" -ForegroundColor Gray
Write-Host "   SELECT proname FROM pg_proc WHERE proname LIKE '%ai_task%';" -ForegroundColor Gray

# Check environment variables
Write-Host "`n3. Environment Variables Check:" -ForegroundColor Yellow
Write-Host "   ⚠️  Manual check required:" -ForegroundColor Yellow
Write-Host "   - Go to Supabase Dashboard → Edge Functions → process-ai-task → Settings" -ForegroundColor Gray
Write-Host "   - Verify OPENAI_API_KEY or ANTHROPIC_API_KEY is set" -ForegroundColor Gray

# Check webhook
Write-Host "`n4. Webhook Check:" -ForegroundColor Yellow
Write-Host "   ⚠️  Manual check required:" -ForegroundColor Yellow
Write-Host "   - Go to Supabase Dashboard → Database → Webhooks" -ForegroundColor Gray
Write-Host "   - Verify webhook exists for ai_tasks table" -ForegroundColor Gray

# Summary
Write-Host "`n📊 Summary:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "   ✅ Basic checks passed" -ForegroundColor Green
    Write-Host "   ⚠️  Please verify environment variables and webhook manually" -ForegroundColor Yellow
} else {
    Write-Host "   ❌ Found $($errors.Count) issue(s):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "      - $error" -ForegroundColor Red
    }
}

Write-Host "`n💡 To test the deployment:" -ForegroundColor Cyan
Write-Host "   1. Open Flutter app" -ForegroundColor White
Write-Host "   2. Go to AI Tutor Chat" -ForegroundColor White
Write-Host "   3. Send a test message" -ForegroundColor White
Write-Host "   4. Check if response appears" -ForegroundColor White

