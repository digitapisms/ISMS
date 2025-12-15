# Fixing Flutter Build Permission Issues on Windows

## Problem

Flutter is unable to delete build directories because files are locked by running processes (Chrome, Dart, etc.).

**Error Message:**
```
Flutter failed to delete a directory at
"build\flutter_assets". The flutter tool cannot access 
the file or directory.
```

## Quick Fix

### Option 1: Use the Fix Script (Recommended)

Run the automated fix script:

```powershell
.\scripts\fix-build-permissions.ps1
```

This script will:
1. Close Chrome and Dart processes
2. Clean Flutter build
3. Remove locked directories
4. Get dependencies

### Option 2: Manual Fix

#### Step 1: Close All Chrome/Dart Processes

**PowerShell:**
```powershell
# Close Chrome
Get-Process chrome | Stop-Process -Force

# Close Dart processes
Get-Process dart* | Stop-Process -Force
```

**Or use Task Manager:**
1. Press `Ctrl + Shift + Esc`
2. End all Chrome processes
3. End all Dart processes

#### Step 2: Clean Flutter

```powershell
flutter clean
```

#### Step 3: Manually Remove Build Directories

If `flutter clean` still fails, manually delete:

```powershell
# Remove build directory
Remove-Item -Path "build" -Recurse -Force

# Remove .dart_tool (if needed)
Remove-Item -Path ".dart_tool" -Recurse -Force

# Remove platform-specific ephemeral directories
Remove-Item -Path "windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "ios\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\.flutter-plugins" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Step 4: Get Dependencies

```powershell
flutter pub get
```

#### Step 5: Try Running Again

```powershell
flutter run -d chrome
```

## Option 3: Run as Administrator

If files are still locked:

1. Close VS Code/Cursor
2. Right-click PowerShell
3. Select "Run as Administrator"
4. Navigate to project: `cd C:\Users\Muddasir\Projects\ISMS\isms_app`
5. Run: `flutter clean && flutter pub get`

## Option 4: Check Antivirus

Sometimes antivirus software locks files:

1. Add project folder to antivirus exclusions
2. Temporarily disable real-time protection
3. Try building again

## Prevention Tips

1. **Always stop the app before rebuilding:**
   - Press `q` in the terminal to quit
   - Or close Chrome manually

2. **Use `flutter clean` before major changes:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Close VS Code/Cursor before cleaning:**
   - Some extensions may lock files

4. **Use separate terminals:**
   - One for running the app
   - One for commands

## If Nothing Works

1. **Restart your computer** (clears all file locks)

2. **Check file permissions:**
   ```powershell
   # Check if you have write access
   Test-Path "build" -PathType Container
   ```

3. **Move project to a different location:**
   - Sometimes Windows user folder permissions cause issues
   - Try: `C:\Projects\ISMS\isms_app` instead

4. **Check disk space:**
   ```powershell
   Get-PSDrive C
   ```

## Still Having Issues?

Run this diagnostic script:

```powershell
# Check what's locking files
Get-Process | Where-Object {
    $_.Path -like "*ISMS*" -or 
    $_.Path -like "*isms_app*"
} | Select-Object ProcessName, Id, Path

# Check file permissions
Get-Acl "build" | Format-List

# Check disk space
Get-PSDrive C | Select-Object Used, Free
```

---

**After fixing, you should be able to run:**
```powershell
flutter run -d chrome
```

✅ **The build directory was successfully removed!** Now try running the app again.

