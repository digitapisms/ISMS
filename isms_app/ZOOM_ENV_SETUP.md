# How to Add Zoom Environment Variables

This guide shows you exactly how to add the Zoom API credentials to your Supabase Edge Function.

## Method 1: Using Supabase Dashboard (Recommended - Easiest)

### Step-by-Step Instructions:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/aduazpxwhvosrhgusrhn
   - Or navigate to: https://supabase.com/dashboard → Select your project

2. **Navigate to Edge Functions**
   - In the left sidebar, click on **"Edge Functions"**
   - You should see `create-zoom-meeting` in the list

3. **Open the Function**
   - Click on **`create-zoom-meeting`** to open its details page

4. **Go to Settings Tab**
   - Click on the **"Settings"** tab at the top

5. **Add Environment Variables**
   - Scroll down to the **"Environment Variables"** section
   - Click **"Add new secret"** or **"Add variable"** button
   
   Add these three variables one by one:

   **Variable 1:**
   - **Name:** `ZOOM_ACCOUNT_ID`
   - **Value:** `C-e6_RSXR6er0hBagYLEzg`
   - Click **"Save"** or **"Add"**

   **Variable 2:**
   - **Name:** `ZOOM_CLIENT_ID`
   - **Value:** `WyTkFC63QzWttaLqsiYdPA`
   - Click **"Save"** or **"Add"**

   **Variable 3:**
   - **Name:** `ZOOM_CLIENT_SECRET`
   - **Value:** `siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47`
   - Click **"Save"** or **"Add"**

6. **Verify**
   - You should now see all three variables listed in the Environment Variables section
   - The values will be masked for security (showing as `••••••`)

## Method 2: Using Supabase CLI (Alternative)

If you prefer using the command line:

### Prerequisites:
- Supabase CLI installed
- Logged in: `supabase login`
- Project linked: `supabase link --project-ref aduazpxwhvosrhgusrhn`

### Commands:

```bash
cd isms_app

# Set each environment variable
supabase secrets set ZOOM_ACCOUNT_ID=C-e6_RSXR6er0hBagYLEzg --project-ref aduazpxwhvosrhgusrhn

supabase secrets set ZOOM_CLIENT_ID=WyTkFC63QzWttaLqsiYdPA --project-ref aduazpxwhvosrhgusrhn

supabase secrets set ZOOM_CLIENT_SECRET=siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47 --project-ref aduazpxwhvosrhgusrhn
```

**Note:** The CLI method may vary depending on your Supabase CLI version. If these commands don't work, use Method 1 (Dashboard).

## Verification

After adding the variables, you can verify they're set correctly:

1. **In Dashboard:**
   - Go back to Edge Functions → create-zoom-meeting → Settings
   - You should see all three variables listed

2. **Test the Function:**
   - Go to Edge Functions → create-zoom-meeting
   - Click "Invoke" tab
   - Use this test payload:
   ```json
   {
     "title": "Test Meeting",
     "startTime": "2024-12-31T10:00:00Z",
     "duration": 60
   }
   ```
   - Click "Invoke"
   - If successful, you'll get a meeting response with `joinUrl` and `password`

## ⚠️ IMPORTANT: Configure OAuth Scopes in Zoom Marketplace

**Before testing the connection, you MUST configure the required scopes in your Zoom OAuth app.**

### Step-by-Step Scope Configuration:

1. **Go to Zoom Marketplace**
   - Visit: https://marketplace.zoom.us/
   - Sign in with your Zoom account

2. **Navigate to Your OAuth App**
   - Click on **"Manage"** → **"Your Apps"**
   - Find your Server-to-Server OAuth app
   - Click on the app to open its settings

3. **Go to Scopes Section**
   - In the app settings, click on the **"Scopes"** tab or section
   - This is usually in the left sidebar or under "App Credentials"

4. **Add Required Scopes**
   - Click **"Add Scopes"** or **"Edit Scopes"**
   - Search for and add these **required scopes**:
     - ✅ `meeting:write:meeting` - Allows creating meetings on behalf of users
     - ✅ `meeting:write:meeting:admin` - Allows creating meetings for any user in the account
   - **Note:** The `account_credentials` scope is automatically included for Server-to-Server OAuth

5. **Save Changes**
   - Click **"Save"** or **"Update"**
   - Wait 2-5 minutes for changes to propagate

6. **Verify Scopes**
   - Confirm both scopes are listed in your app's scopes
   - If you don't see these scopes, ensure your Zoom account has administrative privileges

### Why This Is Required

Zoom Server-to-Server OAuth automatically grants all scopes configured in your OAuth app. If the required scopes aren't configured, the access token won't have the necessary permissions, and you'll get errors like:
- `Invalid access token, does not contain scopes: [meeting:write:meeting, meeting:write:meeting:admin]`
- Error code `4711`

## Troubleshooting

### Variables Not Showing Up
- Make sure you're in the correct project
- Refresh the page
- Check that you saved each variable

### Function Still Fails with Scope Errors
- **Most Common Issue:** Missing scopes in Zoom Marketplace
  - Go to Zoom Marketplace → Your App → Scopes
  - Add `meeting:write:meeting` and `meeting:write:meeting:admin`
  - Save and wait 2-5 minutes
  - Re-test the connection

### Function Still Fails (Other Errors)
- Verify all three variables are set (not just one or two)
- Check for typos in variable names (case-sensitive)
- Check Edge Function logs for detailed error messages
- Verify OAuth app is **activated** (not just created) in Zoom Marketplace
- Ensure Account ID starts with "C-" and is correct

### Can't Find Settings Tab
- Make sure you're viewing the function details (click on the function name)
- The Settings tab should be next to "Overview" and "Logs"

### Can't Find Scopes in Zoom Marketplace
- Ensure you're logged in with an account that has admin privileges
- Some scopes may only be visible to account administrators
- Try creating a new OAuth app if scopes are not available

## Quick Reference

**Your Zoom Credentials:**
- Account ID: `C-e6_RSXR6er0hBagYLEzg`
- Client ID: `WyTkFC63QzWttaLqsiYdPA`
- Client Secret: `siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47`

**Direct Dashboard Link:**
https://supabase.com/dashboard/project/aduazpxwhvosrhgusrhn/functions/create-zoom-meeting/settings

