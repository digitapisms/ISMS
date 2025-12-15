# 🔥 Firebase Deployment Guide for ISMS

Complete guide to deploy your ISMS Flutter web app to Firebase Hosting.

---

## 📋 Prerequisites

### Required Tools
- ✅ **Flutter SDK** (3.9.2+) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- ✅ **Node.js & npm** - [Install Node.js](https://nodejs.org/)
- ✅ **Firebase CLI** - Will be installed automatically by the script
- ✅ **Firebase Account** - [Create Account](https://firebase.google.com/)

### Required Credentials
- Firebase project ID
- Google account with Firebase access

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```powershell
# Navigate to project directory
cd C:\Users\Muddasir\Projects\ISMS\isms_app

# Run deployment script
.\scripts\deploy-firebase.ps1
```

The script will:
1. ✅ Check/install Firebase CLI
2. ✅ Verify login status
3. ✅ Initialize Firebase project (if needed)
4. ✅ Build Flutter web app
5. ✅ Deploy to Firebase Hosting

### Option 2: Manual Deployment

Follow the step-by-step guide below.

---

## 📝 Step-by-Step Deployment

### Step 1: Install Firebase CLI

```powershell
npm install -g firebase-tools
```

Verify installation:
```powershell
firebase --version
```

### Step 2: Login to Firebase

```powershell
firebase login
```

This will open your browser to authenticate with Google.

### Step 3: Create Firebase Project (if needed)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `isms-app` (or your preferred name)
4. Enable/disable Google Analytics (optional)
5. Click **"Create project"**
6. Wait for project creation
7. Note your **Project ID** (e.g., `isms-app-12345`)

### Step 4: Initialize Firebase in Your Project

```powershell
# Navigate to project root
cd C:\Users\Muddasir\Projects\ISMS\isms_app

# Initialize Firebase (select Hosting)
firebase init hosting
```

**During initialization, select:**
- ✅ Use an existing project (or create new)
- ✅ Public directory: `build/web`
- ✅ Single-page app: **Yes**
- ✅ Set up automatic builds: **No** (or Yes if using GitHub)
- ✅ Overwrite index.html: **No**

This creates:
- `.firebaserc` - Project configuration
- `firebase.json` - Hosting configuration (already exists)

### Step 5: Build Flutter Web App

```powershell
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (release mode)
flutter build web --release
```

**Expected output:**
```
✅ Build successful! Output: build/web/
```

### Step 6: Deploy to Firebase

```powershell
firebase deploy --only hosting
```

**Expected output:**
```
✅ Deploy complete!

Hosting URL: https://your-project-id.web.app
```

---

## 🔧 Configuration Files

### `.firebaserc`
```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

### `firebase.json` (Already configured)
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css|jpg|jpeg|gif|png|svg|webp|woff|woff2|ttf|eot)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

---

## 🌐 Environment Variables

### For Web Deployment

Your `.env` file should be configured with:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**Important:** For production, you may want to:
1. Use Firebase Hosting environment variables
2. Or embed variables during build (not recommended for secrets)
3. Or use Firebase Functions to serve environment config

### Option: Using Firebase Functions for Config

Create a function to serve environment config:

```javascript
// functions/config.js
exports.config = functions.https.onRequest((req, res) => {
  res.json({
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY
  });
});
```

Then in your Flutter app, fetch config on startup.

---

## 🔄 Continuous Deployment

### Option 1: GitHub Actions

Create `.github/workflows/firebase-deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

### Option 2: Firebase Hosting GitHub Integration

1. Go to Firebase Console → Hosting
2. Click **"Get started"** with GitHub
3. Connect your repository
4. Configure build settings:
   - Build command: `flutter build web --release`
   - Output directory: `build/web`
5. Enable automatic deployments

---

## 🎯 Deployment Scripts

### Quick Deploy
```powershell
.\scripts\deploy-firebase.ps1
```

### Deploy to Specific Project
```powershell
.\scripts\deploy-firebase.ps1 -ProjectId "your-project-id"
```

### Build Only (No Deploy)
```powershell
.\scripts\deploy-firebase.ps1 -BuildOnly
```

### Help
```powershell
.\scripts\deploy-firebase.ps1 -Help
```

---

## 🐛 Troubleshooting

### Issue: "Firebase CLI not found"
**Solution:**
```powershell
npm install -g firebase-tools
```

### Issue: "Not logged in"
**Solution:**
```powershell
firebase login
```

### Issue: "Project not found"
**Solution:**
1. Check `.firebaserc` has correct project ID
2. Or run: `firebase use --add your-project-id`

### Issue: "Build failed"
**Solution:**
1. Check Flutter version: `flutter --version`
2. Clean build: `flutter clean && flutter pub get`
3. Check for errors: `flutter build web --release --verbose`

### Issue: "Deployment failed"
**Solution:**
1. Check Firebase project permissions
2. Verify `build/web/index.html` exists
3. Check Firebase Console for errors
4. Review deployment logs: `firebase deploy --only hosting --debug`

### Issue: "White screen after deployment"
**Solution:**
1. Check browser console (F12) for errors
2. Verify environment variables are set
3. Check Supabase connection
4. Review `DEBUG_WHITE_SCREEN.md` for troubleshooting

### Issue: "CORS errors"
**Solution:**
1. Configure CORS in Supabase Dashboard
2. Add your Firebase domain to allowed origins
3. Check Supabase RLS policies

---

## 📊 Post-Deployment Checklist

After successful deployment:

- [ ] ✅ App loads without errors
- [ ] ✅ Login/authentication works
- [ ] ✅ Supabase connection established
- [ ] ✅ All modules accessible
- [ ] ✅ Images/assets load correctly
- [ ] ✅ No console errors (F12)
- [ ] ✅ Mobile responsive design works
- [ ] ✅ Performance is acceptable
- [ ] ✅ SSL certificate active (HTTPS)
- [ ] ✅ Custom domain configured (optional)

---

## 🔐 Security Best Practices

1. **Environment Variables:**
   - Never commit `.env` file
   - Use Firebase Functions for sensitive config
   - Or use Firebase Hosting environment variables

2. **Supabase Keys:**
   - Use `anon` key for client-side (already configured)
   - Never expose `service_role` key
   - Configure RLS policies properly

3. **Firebase Security Rules:**
   - Review Firebase Hosting rules
   - Configure custom domain security headers

---

## 🌍 Custom Domain Setup

1. Go to Firebase Console → Hosting
2. Click **"Add custom domain"**
3. Enter your domain name
4. Follow DNS configuration instructions
5. Wait for SSL certificate provisioning
6. Update DNS records as instructed

---

## 📈 Monitoring & Analytics

### Firebase Analytics
- Automatically enabled if configured during project setup
- View in Firebase Console → Analytics

### Performance Monitoring
- Enable in Firebase Console → Performance
- Add Firebase Performance SDK to Flutter app

### Error Tracking
- Use Firebase Crashlytics
- Or integrate Sentry for Flutter

---

## 🔄 Updating Deployment

To update your deployed app:

```powershell
# Make your changes
# Then rebuild and redeploy
flutter build web --release
firebase deploy --only hosting
```

Or use the script:
```powershell
.\scripts\deploy-firebase.ps1
```

---

## 📞 Need Help?

If you encounter issues:

1. ✅ Check this guide's troubleshooting section
2. ✅ Review Firebase Console logs
3. ✅ Check browser console (F12)
4. ✅ Review `DEBUG_WHITE_SCREEN.md`
5. ✅ Check Firebase documentation: [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)

---

## ✅ Success!

Once deployed, your app will be available at:
- **Default URL:** `https://your-project-id.web.app`
- **Custom Domain:** `https://your-domain.com` (if configured)

**Congratulations! Your ISMS app is now live on Firebase! 🎉**

