# ISMS Complete Deployment Guide

## 🚀 Deployment Overview

This guide covers deployment for all components of ISMS:
1. **Web Application** (Flutter Web)
2. **Mobile Apps** (Android/iOS)
3. **Backend** (Supabase - Database, Storage, Edge Functions)

---

## Prerequisites

### Required Tools
- ✅ Flutter SDK (3.9.2+)
- ✅ Node.js & npm
- ✅ Git
- ✅ Supabase CLI (for backend)
- ✅ Hosting provider account

### Required Credentials
- Supabase project URL and keys
- Hosting provider credentials
- Domain name (optional)

---

## Part 1: Backend Deployment (Supabase)

### Step 1: Deploy Database Schema

```bash
# Using Supabase MCP (already configured)
# All SQL migrations have been run via MCP

# Or manually via Supabase CLI:
supabase db push
```

### Step 2: Deploy Edge Functions

**Option A: Using PowerShell Script**
```powershell
.\scripts\deploy-supabase-edge-functions.ps1
```

**Option B: Manual Deployment**
```bash
# Login to Supabase
supabase login

# Link project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy functions
supabase functions deploy process-ai-task
```

### Step 3: Configure Environment Variables

In Supabase Dashboard → Edge Functions → Settings:
- `OPENAI_API_KEY` - Your OpenAI API key
- `AI_PROVIDER` - 'openai' or 'anthropic'
- `OPENAI_MODEL` - Model name (default: 'gpt-4o-mini')

### Step 4: Set Up Webhooks

1. Go to Supabase Dashboard → Database → Webhooks
2. Create webhook:
   - Table: `ai_tasks`
   - Event: `INSERT`
   - URL: `https://YOUR-PROJECT.supabase.co/functions/v1/process-ai-task`
   - Method: `POST`
   - Headers: `Authorization: Bearer YOUR_SERVICE_ROLE_KEY`
   - Body: `{"taskId": "{{NEW.id}}"}`

---

## Part 2: Web Application Deployment

### Option A: Vercel (Recommended)

#### Setup
1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Login:
   ```bash
   vercel login
   ```

3. Deploy:
   ```bash
   # Build first
   flutter build web --release
   
   # Deploy
   cd build/web
   vercel --prod
   ```

#### Automated (GitHub Actions)
- Push to `main` branch
- GitHub Actions will automatically build and deploy
- Configure secrets in GitHub:
  - `VERCEL_TOKEN`
  - `VERCEL_ORG_ID`
  - `VERCEL_PROJECT_ID`

### Option B: Netlify

#### Setup
1. Install Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```

2. Login:
   ```bash
   netlify login
   ```

3. Deploy:
   ```bash
   # Build
   flutter build web --release
   
   # Deploy
   netlify deploy --prod --dir=build/web
   ```

#### Automated
- Connect GitHub repository to Netlify
- Netlify will auto-deploy on push to `main`

### Option C: Firebase Hosting

#### Setup
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login:
   ```bash
   firebase login
   ```

3. Initialize:
   ```bash
   firebase init hosting
   ```

4. Deploy:
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

### Option D: Custom Server

1. Build web app:
   ```bash
   flutter build web --release
   ```

2. Upload `build/web` folder to your server

3. Configure web server (Nginx/Apache):
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;
       root /path/to/build/web;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

---

## Part 3: Mobile App Deployment

### Android (Google Play Store)

#### Step 1: Prepare Release Build

1. Update `android/app/build.gradle.kts`:
   ```kotlin
   signingConfigs {
       release {
           keyAlias = 'your-key-alias'
           keyPassword = 'your-key-password'
           storeFile = file('path/to/keystore.jks')
           storePassword = 'your-store-password'
       }
   }
   ```

2. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

3. Output: `build/app/outputs/bundle/release/app-release.aab`

#### Step 2: Upload to Play Store

1. Go to Google Play Console
2. Create new app or select existing
3. Upload AAB file
4. Complete store listing
5. Submit for review

### iOS (Apple App Store)

#### Step 1: Prepare Release Build

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Configure signing in Xcode
3. Build IPA:
   ```bash
   flutter build ipa --release
   ```

#### Step 2: Upload to App Store

1. Use Xcode → Product → Archive
2. Upload to App Store Connect
3. Complete App Store listing
4. Submit for review

---

## Part 4: Environment Configuration

### Create `.env` File

Create `isms_app/.env` file:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# AI Configuration (Optional)
OPENAI_API_KEY=your-openai-key
OPENAI_API_URL=https://api.openai.com/v1

# Email Configuration (Optional)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-email
SMTP_PASSWORD=your-password

# SMS Configuration (Optional)
SMS_PROVIDER_API_KEY=your-sms-key
```

### For Production

**Vercel:**
- Add environment variables in Vercel Dashboard → Settings → Environment Variables

**Netlify:**
- Add in Netlify Dashboard → Site Settings → Environment Variables

**Firebase:**
- Use Firebase Functions config or `.env` file

---

## Part 5: Post-Deployment Checklist

### ✅ Verify Deployment

1. **Web App**
   - [ ] Visit deployed URL
   - [ ] Test login
   - [ ] Verify all modules load
   - [ ] Check mobile responsiveness

2. **Database**
   - [ ] Verify all tables exist
   - [ ] Test RLS policies
   - [ ] Check data isolation

3. **Edge Functions**
   - [ ] Test AI functions
   - [ ] Verify webhooks
   - [ ] Check logs

4. **Storage**
   - [ ] Test file uploads
   - [ ] Verify bucket permissions
   - [ ] Check file access

### ✅ Security Checks

1. **Enable RLS on all tables** (Critical!)
   ```sql
   -- Run this for each table missing RLS
   ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
   ```

2. **Review RLS Policies**
   - Test with different user roles
   - Verify data isolation

3. **Environment Variables**
   - Ensure `.env` is in `.gitignore`
   - Use secure storage for production secrets

4. **HTTPS**
   - Ensure SSL certificate is active
   - Force HTTPS redirects

### ✅ Performance Optimization

1. **Enable Caching**
   - Configure CDN caching
   - Set cache headers

2. **Optimize Assets**
   - Compress images
   - Minify JavaScript/CSS
   - Enable gzip compression

3. **Database Indexing**
   - Review query performance
   - Add indexes where needed

---

## Part 6: Automated Deployment (CI/CD)

### GitHub Actions Workflow

The project includes `.github/workflows/deploy-web.yml` for automated deployment.

**Setup:**
1. Push code to GitHub
2. Configure secrets in GitHub Settings → Secrets
3. Push to `main` branch triggers deployment

**Required Secrets:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `VERCEL_TOKEN` (if using Vercel)
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

---

## Part 7: Monitoring & Maintenance

### Monitoring

1. **Application Monitoring**
   - Set up error tracking (Sentry, etc.)
   - Monitor performance metrics
   - Track user analytics

2. **Database Monitoring**
   - Monitor query performance
   - Check connection pools
   - Review slow queries

3. **Uptime Monitoring**
   - Use services like UptimeRobot
   - Set up alerts

### Maintenance

1. **Regular Backups**
   - Enable scheduled backups
   - Test restore procedures
   - Store backups securely

2. **Updates**
   - Keep Flutter SDK updated
   - Update dependencies regularly
   - Apply security patches

3. **Database Maintenance**
   - Regular vacuum operations
   - Index maintenance
   - Query optimization

---

## Troubleshooting

### Common Issues

**Build Fails:**
- Check Flutter version compatibility
- Clear build cache: `flutter clean`
- Verify all dependencies

**Deployment Fails:**
- Check hosting provider logs
- Verify environment variables
- Check file size limits

**Database Connection Issues:**
- Verify Supabase URL and keys
- Check network connectivity
- Review RLS policies

---

## Quick Deploy Commands

### One-Command Web Deploy

**Windows (PowerShell):**
```powershell
.\scripts\deploy-web.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/deploy-web.sh
./scripts/deploy-web.sh
```

### Manual Steps

1. **Build:**
   ```bash
   flutter build web --release
   ```

2. **Deploy:**
   - Vercel: `cd build/web && vercel --prod`
   - Netlify: `netlify deploy --prod --dir=build/web`
   - Firebase: `firebase deploy --only hosting`

---

## Support

If you encounter issues during deployment:

1. Check deployment logs
2. Review error messages
3. Verify all prerequisites
4. Contact support with error details

---

**Ready to deploy? Choose your hosting provider and follow the steps above! 🚀**

