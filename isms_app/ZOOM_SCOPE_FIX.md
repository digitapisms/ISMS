# Zoom OAuth Scope Error Fix

## ❌ Error Encountered

```
Connection test failed: FunctionException(status: 400, details: {
  error: Failed to create Zoom meeting, 
  details: {
    "code": 4711,
    "message": "Invalid access token, does not contain scopes: [meeting:write:meeting, meeting:write:meeting:admin]."
  }
}, reasonPhrase: )
```

## 🔍 Root Cause

The Zoom OAuth app in Zoom Marketplace doesn't have the required scopes configured. For Server-to-Server OAuth, Zoom automatically grants all scopes that are configured in your OAuth app settings. If the scopes aren't configured, the access token won't have the necessary permissions.

## ✅ Solution

### Step 1: Access Zoom Marketplace

1. Go to: https://marketplace.zoom.us/
2. Sign in with your Zoom account (must have admin privileges)

### Step 2: Navigate to Your OAuth App

1. Click on **"Manage"** in the top navigation
2. Select **"Your Apps"** from the dropdown
3. Find your **Server-to-Server OAuth** app
4. Click on the app name to open its settings

### Step 3: Configure Required Scopes

1. In the app settings page, look for the **"Scopes"** section
   - This may be in the left sidebar
   - Or under "App Credentials" or "OAuth" section
   - Or as a separate tab

2. Click **"Add Scopes"**, **"Edit Scopes"**, or **"Manage Scopes"**

3. Search for and add these **required scopes**:
   - ✅ **`meeting:write:meeting`**
     - Description: "Create meetings on behalf of users"
     - This allows the app to create meetings
   
   - ✅ **`meeting:write:meeting:admin`**
     - Description: "Create meetings for any user in the account"
     - This allows the app to create meetings with admin privileges

4. **Note:** The `account_credentials` scope is automatically included for Server-to-Server OAuth apps, so you don't need to add it manually.

### Step 4: Save and Wait

1. Click **"Save"**, **"Update"**, or **"Submit"**
2. **Wait 2-5 minutes** for the changes to propagate through Zoom's systems
3. The scopes need to be activated on Zoom's servers before they take effect

### Step 5: Verify Scopes

1. Go back to your app's Scopes section
2. Verify both scopes are listed:
   - `meeting:write:meeting`
   - `meeting:write:meeting:admin`
3. Ensure they show as **"Active"** or **"Enabled"**

### Step 6: Re-test Connection

1. Go back to your ISMS app
2. Navigate to Super Admin → Zoom Integration
3. Click **"Test Connection"**
4. The connection should now succeed

## 🔧 Alternative: Create New OAuth App

If you can't find or add the required scopes to your existing app:

1. **Create a New Server-to-Server OAuth App:**
   - Go to Zoom Marketplace → Manage → Your Apps
   - Click **"Create"** → **"Server-to-Server OAuth App"**
   - Fill in app details (name, description, etc.)

2. **Configure Scopes During Creation:**
   - When creating the app, you'll be prompted to select scopes
   - Make sure to select:
     - `meeting:write:meeting`
     - `meeting:write:meeting:admin`

3. **Get New Credentials:**
   - After creating, go to **"App Credentials"**
   - Copy the new:
     - Account ID (starts with "C-")
     - Client ID
     - Client Secret

4. **Update ISMS Configuration:**
   - Go to Super Admin → Zoom Integration
   - Update the credentials with the new values
   - Save and test

## ⚠️ Common Issues

### Issue: Can't See Scopes Section

**Solution:**
- Ensure you're logged in with a Zoom account that has **administrative privileges**
- Some scopes are only visible to account admins
- Try using the account owner's credentials

### Issue: Scopes Not Available/Visible

**Solution:**
- The scopes might be named slightly differently in your Zoom account
- Look for variations like:
  - `meeting:write` (older version)
  - `meeting:admin:write`
- If still not visible, you may need to contact Zoom support or upgrade your account

### Issue: Scopes Added But Still Getting Error

**Solution:**
- Wait longer (up to 10 minutes) for changes to propagate
- Try revoking and re-requesting the OAuth token
- Clear any cached tokens
- Verify the OAuth app is **activated** (not just created)

### Issue: Account Doesn't Have Admin Privileges

**Solution:**
- Contact your Zoom account administrator
- Request admin access or have them configure the OAuth app
- Or use the account owner's credentials to configure the app

## 📋 Verification Checklist

- [ ] Logged into Zoom Marketplace with admin account
- [ ] Found the Server-to-Server OAuth app
- [ ] Added `meeting:write:meeting` scope
- [ ] Added `meeting:write:meeting:admin` scope
- [ ] Saved the changes
- [ ] Waited 2-5 minutes for propagation
- [ ] Verified scopes are listed and active
- [ ] Re-tested connection in ISMS app
- [ ] Connection test succeeds

## 🎯 Expected Result

After configuring the scopes correctly, when you test the Zoom connection:

✅ **Success Response:**
```json
{
  "success": true,
  "message": "Zoom connection successful"
}
```

❌ **If Still Failing:**
- Check Edge Function logs for detailed error messages
- Verify all credentials are correct
- Ensure OAuth app is activated (not just created)
- Contact Zoom support if scopes are still not available

---

**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Status:** ✅ Ready to fix scope configuration issue
