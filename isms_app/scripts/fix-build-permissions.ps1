# Fix Flutter Build Permission Issues on Windows
# This script resolves common build directory permission problems

Write-Host "🔧 Fixing Flutter Build Permissions" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Close Chrome/Flutter processes
Write-Host "Step 1: Closing Chrome and Flutter processes..." -ForegroundColor Yellow
$processes = Get-Process | Where-Object {
    $_.ProcessName -like "*chrome*" -or 
    $_.ProcessName -like "*dart*" -or 
    $_.ProcessName -like "*flutter*"
}

if ($processes) {
    Write-Host "Found processes that might lock files:" -ForegroundColor Yellow
    $processes | ForEach-Object {
        Write-Host "  - $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
    }
    
    $close = Read-Host "Close these processes? (y/n)"
    if ($close -eq "y") {
        $processes | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                Write-Host "  ✅ Closed $($_.ProcessName)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️  Could not close $($_.ProcessName)" -ForegroundColor Yellow
            }
        }
        Start-Sleep -Seconds 2
    }
} else {
    Write-Host "  ✅ No locking processes found" -ForegroundColor Green
}

# Step 2: Clean Flutter build
Write-Host ""
Write-Host "Step 2: Running flutter clean..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Flutter clean successful!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Flutter clean had issues" -ForegroundColor Yellow
}

# Step 3: Manually remove build directory if it exists
Write-Host ""
Write-Host "Step 3: Removing build directory..." -ForegroundColor Yellow
if (Test-Path "build") {
    try {
        Remove-Item -Path "build" -Recurse -Force -ErrorAction Stop
        Write-Host "  ✅ Build directory removed!" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Could not remove build directory: $_" -ForegroundColor Red
        Write-Host "  💡 Try running PowerShell as Administrator" -ForegroundColor Yellow
        Write-Host "  💡 Or manually delete the 'build' folder" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✅ Build directory doesn't exist" -ForegroundColor Green
}

# Step 4: Remove .dart_tool if needed
Write-Host ""
Write-Host "Step 4: Cleaning .dart_tool..." -ForegroundColor Yellow
if (Test-Path ".dart_tool") {
    try {
        Remove-Item -Path ".dart_tool\build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Cleaned .dart_tool" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Could not clean .dart_tool (non-critical)" -ForegroundColor Yellow
    }
}

# Step 5: Get dependencies
Write-Host ""
Write-Host "Step 5: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Dependencies fetched!" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to get dependencies" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Build permission fix complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Try running: flutter run -d chrome" -ForegroundColor White
Write-Host "  2. If still having issues, run PowerShell as Administrator" -ForegroundColor White
Write-Host "  3. Check antivirus isn't blocking Flutter" -ForegroundColor White

