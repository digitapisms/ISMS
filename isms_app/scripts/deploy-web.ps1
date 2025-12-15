# ISMS Web Deployment Script for Windows (PowerShell)
# Supports: Vercel, Netlify, Firebase Hosting

Write-Host "🚀 ISMS Web Deployment Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Get deployment target
Write-Host ""
Write-Host "Select deployment target:" -ForegroundColor Yellow
Write-Host "1) Vercel"
Write-Host "2) Netlify"
Write-Host "3) Firebase Hosting"
Write-Host "4) Build only (no deploy)"
$choice = Read-Host "Enter choice (1-4)"

# Build Flutter web app
Write-Host ""
Write-Host "📦 Building Flutter web app..." -ForegroundColor Cyan
flutter clean
flutter pub get
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Deploy based on choice
switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🚀 Deploying to Vercel..." -ForegroundColor Cyan
        if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Vercel CLI..." -ForegroundColor Yellow
            npm install -g vercel
        }
        Set-Location build/web
        vercel --prod
        Set-Location ../..
    }
    "2" {
        Write-Host ""
        Write-Host "🚀 Deploying to Netlify..." -ForegroundColor Cyan
        if (-not (Get-Command netlify -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Netlify CLI..." -ForegroundColor Yellow
            npm install -g netlify-cli
        }
        netlify deploy --prod --dir=build/web
    }
    "3" {
        Write-Host ""
        Write-Host "🚀 Deploying to Firebase Hosting..." -ForegroundColor Cyan
        if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Firebase CLI..." -ForegroundColor Yellow
            npm install -g firebase-tools
        }
        firebase deploy --only hosting
    }
    "4" {
        Write-Host ""
        Write-Host "✅ Build complete! Files are in build/web/" -ForegroundColor Green
        Write-Host "You can manually deploy the build/web folder to your hosting provider." -ForegroundColor Yellow
    }
    default {
        Write-Host "❌ Invalid choice!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green

