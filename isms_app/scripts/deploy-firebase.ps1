# ISMS Firebase Deployment Script
# Deploys Flutter web app to Firebase Hosting

param(
    [string]$ProjectId = "",
    [switch]$BuildOnly = $false,
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "🚀 ISMS Firebase Deployment Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\deploy-firebase.ps1                    # Interactive deployment"
    Write-Host "  .\scripts\deploy-firebase.ps1 -ProjectId 'xxx'  # Deploy to specific project"
    Write-Host "  .\scripts\deploy-firebase.ps1 -BuildOnly        # Build only, no deploy"
    Write-Host ""
    exit 0
}

Write-Host "🔥 ISMS Firebase Deployment" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Firebase CLI
Write-Host "Step 1: Checking Firebase CLI..." -ForegroundColor Yellow
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠️  Firebase CLI not found. Installing..." -ForegroundColor Yellow
    try {
        npm install -g firebase-tools
        Write-Host "  ✅ Firebase CLI installed" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to install Firebase CLI" -ForegroundColor Red
        Write-Host "  Please install manually: npm install -g firebase-tools" -ForegroundColor Yellow
        exit 1
    }
} else {
    $firebaseVersion = firebase --version
    Write-Host "  ✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
}

# Step 2: Check if logged in
Write-Host ""
Write-Host "Step 2: Checking Firebase login status..." -ForegroundColor Yellow
try {
    $loginStatus = firebase login:list 2>&1
    if ($LASTEXITCODE -ne 0 -or $loginStatus -match "No authorized accounts") {
        Write-Host "  ⚠️  Not logged in. Please login..." -ForegroundColor Yellow
        firebase login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ❌ Login failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ✅ Already logged in" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Could not check login status. Attempting login..." -ForegroundColor Yellow
    firebase login
}

# Step 3: Check/Initialize Firebase project
Write-Host ""
Write-Host "Step 3: Checking Firebase project configuration..." -ForegroundColor Yellow
if (-not (Test-Path ".firebaserc")) {
    Write-Host "  ⚠️  .firebaserc not found. Initializing Firebase..." -ForegroundColor Yellow
    
    if ($ProjectId -eq "") {
        Write-Host ""
        Write-Host "You need to initialize Firebase. Choose an option:" -ForegroundColor Cyan
        Write-Host "  1) Create a new Firebase project" -ForegroundColor White
        Write-Host "  2) Use an existing Firebase project" -ForegroundColor White
        $initChoice = Read-Host "Enter choice (1-2)"
        
        if ($initChoice -eq "1") {
            Write-Host ""
            Write-Host "Creating new Firebase project..." -ForegroundColor Cyan
            firebase init hosting
        } else {
            Write-Host ""
            $ProjectId = Read-Host "Enter your Firebase project ID"
            firebase use --add $ProjectId
        }
    } else {
        firebase use --add $ProjectId
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Firebase initialization failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Firebase project configured" -ForegroundColor Green
} else {
    Write-Host "  ✅ Firebase project configuration found" -ForegroundColor Green
    $currentProject = firebase use 2>&1 | Select-String "Using (.+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    if ($currentProject) {
        Write-Host "  📌 Current project: $currentProject" -ForegroundColor Cyan
    }
}

# Step 4: Check Flutter
Write-Host ""
Write-Host "Step 4: Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "  ✅ Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Flutter is not installed" -ForegroundColor Red
    exit 1
}

# Step 5: Build Flutter web app
Write-Host ""
Write-Host "Step 5: Building Flutter web app..." -ForegroundColor Yellow
Write-Host "  Running: flutter clean" -ForegroundColor Gray
flutter clean | Out-Null

Write-Host "  Running: flutter pub get" -ForegroundColor Gray
flutter pub get | Out-Null

Write-Host "  Running: flutter build web --release" -ForegroundColor Gray
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Build successful! Output: build/web/" -ForegroundColor Green

# Step 6: Deploy to Firebase
if (-not $BuildOnly) {
    Write-Host ""
    Write-Host "Step 6: Deploying to Firebase Hosting..." -ForegroundColor Yellow
    
    # Verify build/web exists
    if (-not (Test-Path "build/web/index.html")) {
        Write-Host "  ❌ build/web/index.html not found!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Running: firebase deploy --only hosting" -ForegroundColor Gray
    firebase deploy --only hosting
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your app is now live on Firebase Hosting!" -ForegroundColor Cyan
        Write-Host "Check the Firebase Console for your hosting URL." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
        Write-Host "Check the error messages above for details." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "✅ Build complete! (Deployment skipped)" -ForegroundColor Green
    Write-Host "Files are ready in build/web/" -ForegroundColor Cyan
    Write-Host "Run 'firebase deploy --only hosting' when ready to deploy." -ForegroundColor Yellow
}

Write-Host ""

