# Script to inject .env variables into web/config.js for Firebase deployment
# This allows environment variables to be available in the web build

param(
    [string]$EnvFile = ".env",
    [string]$OutputFile = "web/config.js"
)

Write-Host "🔧 Injecting environment variables into web config..." -ForegroundColor Cyan

# Check if .env exists
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ Error: $EnvFile not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with SUPABASE_URL and SUPABASE_ANON_KEY" -ForegroundColor Yellow
    exit 1
}

# Read .env file
$envContent = Get-Content $EnvFile -Raw
$lines = Get-Content $EnvFile

# Extract values
$supabaseUrl = ""
$supabaseAnonKey = ""

foreach ($line in $lines) {
    $line = $line.Trim()
    if ($line -match '^SUPABASE_URL=(.+)$') {
        $supabaseUrl = $matches[1].Trim('"').Trim("'")
    }
    if ($line -match '^SUPABASE_ANON_KEY=(.+)$') {
        $supabaseAnonKey = $matches[1].Trim('"').Trim("'")
    }
}

# Validate
if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
    Write-Host "❌ Error: SUPABASE_URL not found in .env file!" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
    Write-Host "❌ Error: SUPABASE_ANON_KEY not found in .env file!" -ForegroundColor Red
    exit 1
}

# Create config.js content
$configJs = @"
// Environment configuration for ISMS Web App
// This file is auto-generated from .env during build
// DO NOT commit this file with real credentials

window.ISMS_CONFIG = {
  SUPABASE_URL: '$supabaseUrl',
  SUPABASE_ANON_KEY: '$supabaseAnonKey'
};
"@

# Write to file
$configJs | Out-File -FilePath $OutputFile -Encoding utf8 -NoNewline

Write-Host "Config injected successfully!" -ForegroundColor Green
$urlPreview = if ($supabaseUrl.Length -gt 30) { $supabaseUrl.Substring(0, 30) + "..." } else { $supabaseUrl }
Write-Host "   SUPABASE_URL: $urlPreview" -ForegroundColor Gray
Write-Host "   Output: $OutputFile" -ForegroundColor Gray

