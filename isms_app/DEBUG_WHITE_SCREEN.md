# Debugging White Screen Issue

## Quick Fixes

### 1. Check Browser Console

**Open Developer Tools:**
- Press `F12` or `Ctrl+Shift+I`
- Go to **Console** tab
- Look for red error messages

**Common Errors:**
- `Failed to load .env file` → Missing or incorrect .env file
- `Supabase initialization failed` → Wrong credentials
- `CORS error` → Supabase CORS configuration issue
- `404 Not Found` → Missing assets or build files

### 2. Verify .env File

Check that `.env` file exists and has correct values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Location:** `isms_app/.env`

### 3. Check Supabase Connection

Test if Supabase is accessible:

1. Open browser console (F12)
2. Run:
   ```javascript
   fetch('YOUR_SUPABASE_URL/rest/v1/', {
     headers: {
       'apikey': 'YOUR_ANON_KEY'
     }
   }).then(r => console.log('Supabase:', r.ok ? 'Connected' : 'Failed'))
   ```

### 4. Clear Browser Cache

**Chrome:**
1. Press `Ctrl+Shift+Delete`
2. Select "Cached images and files"
3. Clear data
4. Reload page

### 5. Rebuild the App

```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter build web
flutter run -d chrome
```

### 6. Check Network Tab

1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Reload page
4. Look for failed requests (red)
5. Check if assets are loading

### 7. Enable Verbose Logging

Run with verbose output:

```powershell
flutter run -d chrome --verbose
```

Look for initialization errors in the console.

## Common Causes

### Missing .env File
**Symptom:** White screen, console shows "Failed to load .env"
**Fix:** Create `.env` file with Supabase credentials

### Wrong Supabase Credentials
**Symptom:** White screen, console shows "Supabase initialization failed"
**Fix:** Verify SUPABASE_URL and SUPABASE_ANON_KEY in .env

### CORS Issues
**Symptom:** White screen, console shows CORS errors
**Fix:** 
1. Go to Supabase Dashboard → Settings → API
2. Add your localhost URL to allowed origins
3. For development: `http://localhost:port`

### Missing Assets
**Symptom:** White screen, network tab shows 404 errors
**Fix:** Run `flutter pub get` and rebuild

### JavaScript Errors
**Symptom:** White screen, console shows JS errors
**Fix:** Check for syntax errors or missing dependencies

## Debugging Steps

### Step 1: Check Console
```powershell
# Run app and watch console
flutter run -d chrome
```

### Step 2: Add Debug Prints
The app now has debug prints in `main.dart`:
- ✅ Environment variables loaded
- ✅ Hive initialized
- ✅ Supabase initialized
- ✅ Offline Manager initialized
- ✅ Scheduled Backup Service initialized

### Step 3: Test Supabase Connection
```dart
// In browser console after app loads
// Check if Supabase is initialized
console.log('Supabase:', window.supabase ? 'Initialized' : 'Not initialized');
```

### Step 4: Check Error Screen
If initialization fails, you should now see an error screen instead of white screen.

## Still Having Issues?

1. **Check Flutter Version:**
   ```powershell
   flutter --version
   ```
   Should be 3.9.2+

2. **Check Dependencies:**
   ```powershell
   flutter pub get
   flutter doctor
   ```

3. **Try Different Browser:**
   - Chrome
   - Firefox
   - Edge

4. **Check Supabase Dashboard:**
   - Verify project is active
   - Check API keys are correct
   - Verify CORS settings

5. **Run in Release Mode:**
   ```powershell
   flutter run -d chrome --release
   ```

## Error Screen

The app now shows an error screen if initialization fails, instead of a white screen. This will help identify the issue.

---

**If you see the error screen, check the message and browser console for details!**

