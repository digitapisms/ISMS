# Quick Firebase Deployment Guide

## 🚀 Quick Deploy Command

After making code changes, deploy to Firebase with one command:

```powershell
.\scripts\quick-deploy-firebase.ps1
```

This script will:
1. ✅ Build your Flutter web app
2. ✅ Deploy to Firebase Hosting
3. ✅ Open the app in your browser automatically

---

## 📋 Workflow Options

### Option 1: Quick Deploy (Recommended)
```powershell
.\scripts\quick-deploy-firebase.ps1
```

### Option 2: Build Only (Test First)
```powershell
.\scripts\quick-deploy-firebase.ps1 -BuildOnly
# Then deploy manually:
firebase deploy --only hosting
```

### Option 3: Full Deployment Script (More Options)
```powershell
.\scripts\deploy-firebase.ps1
```

---

## 🔗 Your Firebase URLs

- **Main URL:** https://astudio-1979.web.app
- **Project:** astudio-1979

---

## ⚡ Quick Commands Reference

| Command | What It Does |
|---------|-------------|
| `.\scripts\quick-deploy-firebase.ps1` | Build + Deploy + Open |
| `.\scripts\quick-deploy-firebase.ps1 -BuildOnly` | Build only (no deploy) |
| `firebase deploy --only hosting` | Deploy without building |

---

## 💡 Tips

1. **After making code changes:** Run `.\scripts\quick-deploy-firebase.ps1`
2. **To just open the deployed app:** Visit https://astudio-1979.web.app
3. **Deployment takes 1-2 minutes** - be patient!
4. **Changes appear instantly** after deployment completes

---

## 🔄 Development Workflow

1. Make code changes locally
2. Test locally (optional): `flutter run -d chrome`
3. Deploy to Firebase: `.\scripts\quick-deploy-firebase.ps1`
4. Test on Firebase URL: https://astudio-1979.web.app

