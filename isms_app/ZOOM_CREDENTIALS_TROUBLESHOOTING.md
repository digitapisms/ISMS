# Zoom Integration Troubleshooting Guide

## Error: `invalid_client`

This error means Zoom cannot authenticate your OAuth app. Follow these steps:

### Step 1: Verify Credentials in Zoom Marketplace

1. **Go to Zoom Marketplace**: https://marketplace.zoom.us/
2. **Sign in** with your Zoom account
3. **Navigate to "Develop" → "Build App"** (or "Manage" → "Created Apps")
4. **Select your Server-to-Server OAuth app**
5. **Go to "App Credentials" tab**

### Step 2: Verify Each Credential

#### Account ID
- **Location**: App Credentials tab → "Account ID"
- **Format**: Must start with `C-` (e.g., `C-e6_RSXR6er0hBagYLEzg`)
- **Important**: This is NOT your Zoom Account Number from your profile
- **Copy exactly** - no spaces before or after

#### Client ID
- **Location**: App Credentials tab → "Client ID"
- **Format**: Usually 22 characters (e.g., `WyTkFC63QzWttaLqsiYdPA`)
- **Copy exactly** - no spaces before or after

#### Client Secret
- **Location**: App Credentials tab → "Client Secret"
- **Format**: Usually 32 characters
- **Important**: If you don't see it, click "Show" or "Reveal"
- **Copy exactly** - no spaces before or after

### Step 3: Verify OAuth App Status

1. **Go to "Activation" tab** in your Zoom app
2. **Check Status**: Should be "Activated" (green)
3. **If not activated**:
   - Click "Activate" button
   - Follow the activation steps
   - Wait a few minutes for activation to complete

### Step 4: Verify Required Scopes

1. **Go to "Scopes" tab** in your Zoom app
2. **Required scopes**:
   - `meeting:write` ✅
   - `meeting:read` ✅
   - `user:read` ✅
3. **If missing**: Add them and save

### Step 5: Re-enter Credentials in ISMS

1. **Go to Super Admin Dashboard**
2. **Click Account Icon** → **Zoom Integration**
3. **Clear all three fields completely**
4. **Re-enter each credential** (copy-paste directly from Zoom Marketplace)
5. **Verify no extra spaces**:
   - Account ID should start with `C-` immediately (no space before)
   - Client ID should have no leading/trailing spaces
   - Client Secret should have no leading/trailing spaces
6. **Click "Save Credentials"**
7. **Wait 2-3 seconds**
8. **Click "Test Connection"**

### Step 6: Common Mistakes to Avoid

❌ **Don't** copy credentials with extra spaces
❌ **Don't** use your Zoom Account Number (from profile) instead of Account ID
❌ **Don't** use credentials from a different OAuth app
❌ **Don't** use credentials if the app is not activated
❌ **Don't** mix credentials from different Zoom accounts

✅ **Do** copy credentials exactly as shown in Zoom Marketplace
✅ **Do** ensure the app is activated
✅ **Do** verify all three credentials are from the same OAuth app
✅ **Do** wait a few seconds after saving before testing

### Step 7: Still Not Working?

If you've verified everything above and it's still not working:

1. **Check Zoom App Type**:
   - Must be "Server-to-Server OAuth" (not "OAuth" or "JWT")
   - If you have a different app type, create a new Server-to-Server OAuth app

2. **Verify Account Access**:
   - The Account ID must match the account that created the OAuth app
   - If you're using a different Zoom account, you need credentials from that account's app

3. **Check for Special Characters**:
   - Some credentials might have special characters that get corrupted when copying
   - Try typing them manually (if short enough) or use a plain text editor

4. **Contact Support**:
   - If all else fails, the credentials might be invalid in Zoom's system
   - You may need to regenerate the Client Secret in Zoom Marketplace

## Quick Verification Checklist

- [ ] Account ID starts with `C-` and matches Zoom Marketplace
- [ ] Client ID matches exactly (22 characters, no spaces)
- [ ] Client Secret matches exactly (32 characters, no spaces)
- [ ] OAuth app is "Activated" (green status)
- [ ] Required scopes are added (`meeting:write`, `meeting:read`, `user:read`)
- [ ] All credentials are from the same OAuth app
- [ ] Credentials are saved in ISMS Super Admin panel
- [ ] Tested connection after saving

## Need Help?

If you continue to experience issues:
1. Check Supabase Edge Function logs for detailed error messages
2. Verify credentials are being read correctly from the database
3. Ensure the Edge Function has the latest version deployed

