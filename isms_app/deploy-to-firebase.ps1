# Firebase Deployment Script for ISMS App
# Project: isms-4cb47
# Account: digitapisms@gmail.com

Write-Host "`n=== ISMS Firebase Deployment ===" -ForegroundColor Cyan
Write-Host "Project: isms-4cb47" -ForegroundColor Yellow
Write-Host "Account: digitapisms@gmail.com`n" -ForegroundColor Yellow

# Check if logged in
Write-Host "Checking Firebase authentication..." -ForegroundColor Cyan
$loginCheck = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Not logged in to Firebase!" -ForegroundColor Red
    Write-Host "Please run: firebase login" -ForegroundColor Yellow
    Write-Host "Then select: digitapisms@gmail.com`n" -ForegroundColor Yellow
    exit 1
}

# Switch to correct project
Write-Host "Setting Firebase project to isms-4cb47..." -ForegroundColor Cyan
firebase use isms-4cb47
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to switch to project isms-4cb47" -ForegroundColor Red
    Write-Host "Please ensure you have access to this project.`n" -ForegroundColor Yellow
    exit 1
}

# Verify build exists
if (-not (Test-Path "build\web\index.html")) {
    Write-Host "❌ Build not found! Building now..." -ForegroundColor Yellow
    flutter build web --release --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Deploy to Firebase Hosting
Write-Host "`n🚀 Deploying to Firebase Hosting..." -ForegroundColor Green
firebase deploy --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
    Write-Host "Your app should be live shortly.`n" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

