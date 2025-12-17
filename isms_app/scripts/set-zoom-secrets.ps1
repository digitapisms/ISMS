# PowerShell script to set Zoom secrets in Supabase
# This script uses Supabase CLI to set environment variables

Write-Host "🔐 Setting Zoom API credentials in Supabase..." -ForegroundColor Cyan

$projectRef = "aduazpxwhvosrhgusrhn"

# Set each secret individually
Write-Host "Setting ZOOM_ACCOUNT_ID..." -ForegroundColor Yellow
supabase secrets set ZOOM_ACCOUNT_ID=C-e6_RSXR6er0hBagYLEzg --project-ref $projectRef

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ZOOM_ACCOUNT_ID set successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set ZOOM_ACCOUNT_ID" -ForegroundColor Red
    Write-Host "You may need to set these manually in the Supabase Dashboard" -ForegroundColor Yellow
}

Write-Host "Setting ZOOM_CLIENT_ID..." -ForegroundColor Yellow
supabase secrets set ZOOM_CLIENT_ID=WyTkFC63QzWttaLqsiYdPA --project-ref $projectRef

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ZOOM_CLIENT_ID set successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set ZOOM_CLIENT_ID" -ForegroundColor Red
    Write-Host "You may need to set these manually in the Supabase Dashboard" -ForegroundColor Yellow
}

Write-Host "Setting ZOOM_CLIENT_SECRET..." -ForegroundColor Yellow
supabase secrets set ZOOM_CLIENT_SECRET=siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47 --project-ref $projectRef

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ZOOM_CLIENT_SECRET set successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set ZOOM_CLIENT_SECRET" -ForegroundColor Red
    Write-Host "You may need to set these manually in the Supabase Dashboard" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Verification:" -ForegroundColor Cyan
Write-Host "Run: supabase secrets list --project-ref $projectRef" -ForegroundColor Gray
Write-Host ""
Write-Host "If CLI method fails, use the Dashboard:" -ForegroundColor Yellow
Write-Host "https://supabase.com/dashboard/project/$projectRef/functions/create-zoom-meeting/settings" -ForegroundColor Cyan

