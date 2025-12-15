# Complete build and deploy script for Firebase
# Injects environment variables and deploys

Write-Host "🔥 ISMS Firebase Build & Deploy" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Inject environment variables
Write-Host "Step 1: Injecting environment variables..." -ForegroundColor Yellow
& .\scripts\inject-env-to-web.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to inject environment variables!" -ForegroundColor Red
    exit 1
}

# Step 2: Clean build
Write-Host ""
Write-Host "Step 2: Cleaning previous build..." -ForegroundColor Yellow
flutter clean | Out-Null

# Step 3: Get dependencies
Write-Host ""
Write-Host "Step 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies!" -ForegroundColor Red
    exit 1
}

# Step 4: Build web
Write-Host ""
Write-Host "Step 4: Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Step 5: Verify config.js is in build
Write-Host ""
Write-Host "Step 5: Verifying config.js in build..." -ForegroundColor Yellow
if (Test-Path "build/web/config.js") {
    Write-Host "✅ config.js found in build" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: config.js not found in build/web" -ForegroundColor Yellow
    Write-Host "   Copying config.js to build..." -ForegroundColor Yellow
    Copy-Item "web/config.js" -Destination "build/web/config.js" -Force
    Write-Host "✅ config.js copied" -ForegroundColor Green
}

# Step 6: Deploy to Firebase
Write-Host ""
Write-Host "Step 6: Deploying to Firebase..." -ForegroundColor Yellow
firebase deploy --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your app is now live with Supabase configuration!" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

