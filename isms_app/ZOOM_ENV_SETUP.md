# How to Add Zoom Environment Variables

This guide shows you exactly how to add the Zoom API credentials to your Supabase Edge Function.

## Method 1: Using Supabase Dashboard (Recommended - Easiest)

### Step-by-Step Instructions:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/kgyzawrrcksjbwfwadfi
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
- Project linked: `supabase link --project-ref kgyzawrrcksjbwfwadfi`

### Commands:

```bash
cd isms_app

# Set each environment variable
supabase secrets set ZOOM_ACCOUNT_ID=C-e6_RSXR6er0hBagYLEzg --project-ref kgyzawrrcksjbwfwadfi

supabase secrets set ZOOM_CLIENT_ID=WyTkFC63QzWttaLqsiYdPA --project-ref kgyzawrrcksjbwfwadfi

supabase secrets set ZOOM_CLIENT_SECRET=siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47 --project-ref kgyzawrrcksjbwfwadfi
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

## Troubleshooting

### Variables Not Showing Up
- Make sure you're in the correct project
- Refresh the page
- Check that you saved each variable

### Function Still Fails
- Verify all three variables are set (not just one or two)
- Check for typos in variable names (case-sensitive)
- Check Edge Function logs for detailed error messages

### Can't Find Settings Tab
- Make sure you're viewing the function details (click on the function name)
- The Settings tab should be next to "Overview" and "Logs"

## Quick Reference

**Your Zoom Credentials:**
- Account ID: `C-e6_RSXR6er0hBagYLEzg`
- Client ID: `WyTkFC63QzWttaLqsiYdPA`
- Client Secret: `siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47`

**Direct Dashboard Link:**
https://supabase.com/dashboard/project/kgyzawrrcksjbwfwadfi/functions/create-zoom-meeting/settings

