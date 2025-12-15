# ISMS Supabase Edge Functions Deployment Script

Write-Host "🚀 Deploying Supabase Edge Functions" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check if Supabase CLI is installed
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI is not installed." -ForegroundColor Red
    Write-Host "Install it with: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host ""
Write-Host "Checking Supabase login status..." -ForegroundColor Cyan
$loginStatus = supabase projects list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not logged in. Please login first:" -ForegroundColor Yellow
    Write-Host "   supabase login" -ForegroundColor White
    exit 1
}

# Deploy Edge Functions
Write-Host ""
Write-Host "📦 Deploying Edge Functions..." -ForegroundColor Cyan

$functions = Get-ChildItem -Path "supabase/functions" -Directory
foreach ($function in $functions) {
    $functionName = $function.Name
    Write-Host "Deploying: $functionName" -ForegroundColor Yellow
    supabase functions deploy $functionName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $functionName deployed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to deploy $functionName" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Edge Functions deployment complete!" -ForegroundColor Green

