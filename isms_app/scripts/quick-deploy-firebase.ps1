# Quick Firebase Deploy Script
# Deploys to Firebase Hosting quickly

param(
    [switch]$BuildOnly = $false
)

Write-Host "Quick Firebase Deployment" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI not found! Installing..." -ForegroundColor Yellow
    npm install -g firebase-tools
}

# Check if logged in
Write-Host "Checking Firebase login status..." -ForegroundColor Yellow
$loginStatus = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in to Firebase! Logging in..." -ForegroundColor Yellow
    firebase login
}

# Build Flutter web app
Write-Host ""
Write-Host "Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

if (-not $BuildOnly) {
    Write-Host ""
    Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Yellow
    
    firebase deploy --only hosting
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your app is live at: https://astudio-1979.web.app" -ForegroundColor Cyan
        Write-Host ""
        
        # Ask if user wants to open the URL
        $response = Read-Host "Open in browser? (Y/n)"
        if ($response -ne "n" -and $response -ne "N") {
            Start-Process "https://astudio-1979.web.app"
        }
    } else {
        Write-Host ""
        Write-Host "Deployment failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Build complete! (Deployment skipped)" -ForegroundColor Green
    Write-Host "To deploy, run: firebase deploy --only hosting" -ForegroundColor Yellow
}

Write-Host ""
