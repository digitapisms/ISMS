# Clean and Run Flutter App Script
# Handles locked directories and starts the app

param(
    [string]$Device = "chrome"
)

Write-Host "Cleaning and preparing Flutter app..." -ForegroundColor Cyan
Write-Host ""

# Stop any running Flutter/Chrome/Dart processes
Write-Host "Stopping processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -match "chrome|dart|flutter"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Clean build directory
Write-Host "Cleaning build directory..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "Build directory cleaned" -ForegroundColor Green

# Clean Flutter cache
Write-Host "Running flutter clean..." -ForegroundColor Yellow
flutter clean 2>&1 | Out-Null

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null

Write-Host ""
Write-Host "Starting Flutter app on $Device..." -ForegroundColor Cyan
Write-Host ""

# Run the app
flutter run -d $Device

