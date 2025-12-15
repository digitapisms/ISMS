# ISMS Quick Deployment Script
# Automated deployment for all components

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("web", "android", "ios", "supabase", "all")]
    [string]$Target = "all",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("vercel", "netlify", "firebase")]
    [string]$WebProvider = "vercel"
)

Write-Host "🚀 ISMS Quick Deployment Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Function to check command exists
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$prereqs = @{
    "Flutter" = Test-Command "flutter"
    "Node.js" = Test-Command "node"
    "npm" = Test-Command "npm"
}

foreach ($prereq in $prereqs.GetEnumerator()) {
    if ($prereq.Value) {
        Write-Host "  ✅ $($prereq.Key)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($prereq.Key) - Please install first" -ForegroundColor Red
        exit 1
    }
}

# Deploy Supabase Edge Functions
if ($Target -eq "supabase" -or $Target -eq "all") {
    Write-Host ""
    Write-Host "📦 Deploying Supabase Edge Functions..." -ForegroundColor Cyan
    if (Test-Command "supabase") {
        & "$PSScriptRoot\deploy-supabase-edge-functions.ps1"
    } else {
        Write-Host "  ⚠️  Supabase CLI not found. Skipping..." -ForegroundColor Yellow
    }
}

# Deploy Web App
if ($Target -eq "web" -or $Target -eq "all") {
    Write-Host ""
    Write-Host "🌐 Building Web App..." -ForegroundColor Cyan
    flutter clean
    flutter pub get
    flutter build web --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Web build successful!" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🚀 Deploying to $WebProvider..." -ForegroundColor Cyan
        switch ($WebProvider) {
            "vercel" {
                if (-not (Test-Command "vercel")) {
                    Write-Host "  Installing Vercel CLI..." -ForegroundColor Yellow
                    npm install -g vercel
                }
                Set-Location build/web
                vercel --prod
                Set-Location ../..
            }
            "netlify" {
                if (-not (Test-Command "netlify")) {
                    Write-Host "  Installing Netlify CLI..." -ForegroundColor Yellow
                    npm install -g netlify-cli
                }
                netlify deploy --prod --dir=build/web
            }
            "firebase" {
                if (-not (Test-Command "firebase")) {
                    Write-Host "  Installing Firebase CLI..." -ForegroundColor Yellow
                    npm install -g firebase-tools
                }
                firebase deploy --only hosting
            }
        }
    } else {
        Write-Host "  ❌ Web build failed!" -ForegroundColor Red
    }
}

# Deploy Android
if ($Target -eq "android" -or $Target -eq "all") {
    Write-Host ""
    Write-Host "📱 Building Android App..." -ForegroundColor Cyan
    flutter build appbundle --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Android build successful!" -ForegroundColor Green
        Write-Host "  📦 AAB file: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Yellow
        Write-Host "  📤 Upload to Google Play Console manually" -ForegroundColor Yellow
    }
}

# Deploy iOS
if ($Target -eq "ios" -or $Target -eq "all") {
    Write-Host ""
    Write-Host "🍎 Building iOS App..." -ForegroundColor Cyan
    Write-Host "  ⚠️  iOS deployment requires Xcode on macOS" -ForegroundColor Yellow
    Write-Host "  Run: flutter build ipa --release" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Deployment process complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Verify deployment at your hosting URL" -ForegroundColor White
Write-Host "  2. Test all features" -ForegroundColor White
Write-Host "  3. Monitor for errors" -ForegroundColor White

