# Quick Fix and Run Script
# Closes locking processes, cleans build, and runs the app

Write-Host "🔧 ISMS Quick Fix & Run" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Close locking processes
Write-Host "Step 1: Closing Chrome and Dart processes..." -ForegroundColor Yellow
$processes = Get-Process | Where-Object {
    $_.ProcessName -like "*chrome*" -or 
    $_.ProcessName -like "*dart*" -or 
    $_.ProcessName -like "*flutter*"
}

if ($processes) {
    $processes | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Closed: $($_.ProcessName)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Could not close: $($_.ProcessName)" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "  ✅ No locking processes found" -ForegroundColor Green
}

# Step 2: Remove locked directories
Write-Host ""
Write-Host "Step 2: Removing build directories..." -ForegroundColor Yellow
$dirs = @(
    "build",
    ".dart_tool\build",
    "windows\flutter\ephemeral",
    "ios\Flutter\ephemeral",
    "linux\flutter\ephemeral",
    "macos\Flutter\ephemeral"
)

foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ Removed: $dir" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Could not remove: $dir" -ForegroundColor Yellow
        }
    }
}

# Step 3: Flutter clean
Write-Host ""
Write-Host "Step 3: Running flutter clean..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "  ✅ Flutter clean complete" -ForegroundColor Green

# Step 4: Get dependencies
Write-Host ""
Write-Host "Step 4: Getting dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "  ✅ Dependencies fetched" -ForegroundColor Green

# Step 5: Run the app
Write-Host ""
Write-Host "Step 5: Launching app..." -ForegroundColor Yellow
Write-Host ""
flutter run -d chrome

