# PowerShell script to deploy Supabase Edge Function
# Usage: .\scripts\deploy-edge-function.ps1

Write-Host "🚀 Deploying AI Backend Edge Function..." -ForegroundColor Cyan

# Check if Supabase CLI is installed
Write-Host "`n📦 Checking Supabase CLI..." -ForegroundColor Yellow
try {
    $supabaseVersion = supabase --version
    Write-Host "✅ Supabase CLI found: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI not found!" -ForegroundColor Red
    Write-Host "Install it with: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "`n🔐 Checking Supabase login status..." -ForegroundColor Yellow
try {
    supabase projects list | Out-Null
    Write-Host "✅ Logged in to Supabase" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Not logged in. Please run: supabase login" -ForegroundColor Yellow
    $login = Read-Host "Do you want to login now? (y/n)"
    if ($login -eq "y") {
        supabase login
    } else {
        Write-Host "Exiting..." -ForegroundColor Red
        exit 1
    }
}

# Check if project is linked
Write-Host "`n🔗 Checking project link..." -ForegroundColor Yellow
if (Test-Path ".\.supabase\config.toml") {
    Write-Host "✅ Project is linked" -ForegroundColor Green
} else {
    Write-Host "⚠️  Project not linked" -ForegroundColor Yellow
    $projectId = Read-Host "Enter your Supabase project ID"
    if ($projectId) {
        supabase link --project-ref $projectId
    } else {
        Write-Host "Exiting..." -ForegroundColor Red
        exit 1
    }
}

# Deploy Edge Function
Write-Host "`n📤 Deploying Edge Function: process-ai-task..." -ForegroundColor Yellow
try {
    supabase functions deploy process-ai-task
    Write-Host "`n✅ Edge Function deployed successfully!" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Next steps
Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set environment variables in Supabase Dashboard:" -ForegroundColor White
Write-Host "   - Go to: Edge Functions → process-ai-task → Settings" -ForegroundColor Gray
Write-Host "   - Add: OPENAI_API_KEY or ANTHROPIC_API_KEY" -ForegroundColor Gray
Write-Host "`n2. Set up webhook (see AI_BACKEND_QUICK_START.md)" -ForegroundColor White
Write-Host "`n3. Test the integration!" -ForegroundColor White

