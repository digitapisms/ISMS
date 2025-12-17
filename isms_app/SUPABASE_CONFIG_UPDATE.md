# Supabase Configuration Update

## ✅ Configuration Updated

Your Supabase project credentials have been updated across all configuration files.

### New Project Details
- **Project URL:** `https://aduazpxwhvosrhgusrhn.supabase.co`
- **Project Reference:** `aduazpxwhvosrhgusrhn`
- **Login Email:** `digitapisms@gmail.com`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdWF6cHh3aHZvc3JoZ3VzcmhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5NjkzMTIsImV4cCI6MjA4MTU0NTMxMn0.KLzHMrFZDE9MilTYa9nB9hkV2Fo1XNPKvLJmQQMZPW0`

## Files Updated

### 1. Core Configuration
- ✅ `lib/src/core/network/supabase_client.dart`
  - Updated hardcoded web Supabase URL
  - Updated hardcoded web anon key

### 2. Web Configuration
- ✅ `web/config.js`
  - Updated SUPABASE_URL
  - Updated SUPABASE_ANON_KEY

### 3. Environment File
- ✅ `.env`
  - Updated SUPABASE_URL
  - Updated SUPABASE_ANON_KEY

### 4. Scripts
- ✅ `scripts/set-zoom-secrets.ps1`
  - Updated project reference from `kgyzawrrcksjbwfwadfi` to `aduazpxwhvosrhgusrhn`

### 5. Documentation
- ✅ `ZOOM_ENV_SETUP.md`
  - Updated all project references to new project ID

## Next Steps

### 1. Verify Connection
Test the connection by running the app:
```bash
cd isms_app
flutter run
```

### 2. Update Supabase CLI Link (if using CLI)
If you're using Supabase CLI, relink to the new project:
```bash
supabase link --project-ref aduazpxwhvosrhgusrhn
```

### 3. Update Edge Function Secrets
If you have Edge Functions deployed, update their environment variables in:
- Supabase Dashboard → Edge Functions → [Function Name] → Settings
- Or use the updated script: `scripts/set-zoom-secrets.ps1`

### 4. Verify Database Access
Ensure you can access the database:
- Check Supabase Dashboard: https://supabase.com/dashboard/project/aduazpxwhvosrhgusrhn
- Verify tables exist
- Test authentication

## Important Notes

- **Web Builds:** The hardcoded values in `supabase_client.dart` are used for web deployments. These have been updated.
- **Mobile/Desktop:** These platforms use the `.env` file, which has been updated.
- **Edge Functions:** Update environment variables in Supabase Dashboard for each Edge Function.

## Verification Checklist

- [ ] App connects to new Supabase project
- [ ] Authentication works
- [ ] Database queries succeed
- [ ] Edge Functions can access new project
- [ ] Storage operations work
- [ ] Real-time subscriptions work

## Troubleshooting

If you encounter connection issues:

1. **Check .env file exists and is readable**
   ```bash
   cat isms_app/.env
   ```

2. **Verify credentials in Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/aduazpxwhvosrhgusrhn/settings/api
   - Verify URL and anon key match

3. **Clear Flutter build cache**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **Check network connectivity**
   - Ensure you can access https://aduazpxwhvosrhgusrhn.supabase.co

---

**Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
