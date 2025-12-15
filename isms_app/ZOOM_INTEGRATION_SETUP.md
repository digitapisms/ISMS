# Zoom API Integration Setup Guide

This guide explains how to set up and deploy the Zoom API integration for ISMS online classes.

## ✅ What's Been Implemented

1. **Zoom Service** (`lib/src/features/online_classes/services/zoom_service.dart`)
   - Client-side service for creating Zoom meetings
   - Calls Supabase Edge Function securely

2. **Supabase Edge Function** (`supabase/functions/create-zoom-meeting/index.ts`)
   - Server-side function that handles Zoom API calls
   - Uses OAuth 2.0 Server-to-Server authentication
   - Creates meetings with configurable settings

3. **Online Class Integration**
   - Online class repository automatically creates Zoom meetings when platform is Zoom
   - Online class engine generates Zoom meeting URLs

## 🚀 Setup Steps

### Step 1: Deploy Edge Function

Deploy the Zoom meeting creation Edge Function to Supabase:

```bash
cd isms_app
supabase functions deploy create-zoom-meeting
```

### Step 2: Configure Environment Variables

In **Supabase Dashboard → Edge Functions → create-zoom-meeting → Settings**, add these environment variables:

**Required:**
- `ZOOM_ACCOUNT_ID` = `C-e6_RSXR6er0hBagYLEzg`
- `ZOOM_CLIENT_ID` = `WyTkFC63QzWttaLqsiYdPA`
- `ZOOM_CLIENT_SECRET` = `siKHSGfgZGIEkVE2FUoBVOoJ0nIiMN47`

**Auto-configured (already set):**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

### Step 3: Verify Deployment

Test the Edge Function:

```bash
# Using Supabase CLI
supabase functions invoke create-zoom-meeting \
  --body '{
    "title": "Test Meeting",
    "startTime": "2024-12-31T10:00:00Z",
    "duration": 60
  }'
```

Or test via Supabase Dashboard → Edge Functions → create-zoom-meeting → Invoke

## 📋 How It Works

### Creating a Zoom Online Class

1. User creates an online class in the ISMS app and selects Zoom as the platform
2. The app calls `OnlineClassRepository.createOnlineClass()`
3. Repository detects Zoom platform and calls `ZoomService.createMeeting()`
4. ZoomService invokes the Supabase Edge Function `create-zoom-meeting`
5. Edge Function:
   - Authenticates with Zoom using OAuth 2.0 Server-to-Server
   - Creates a Zoom meeting via Zoom API
   - Returns meeting details (join URL, password, etc.)
6. Repository saves the meeting URL and password to the database
7. Users can join the meeting using the join URL

### Meeting Settings

The integration supports these Zoom meeting settings:
- **Waiting Room**: Enable/disable waiting room
- **Recording**: Automatic cloud recording (if enabled)
- **Audio**: Both telephony and VoIP
- **Video**: Host and participant video enabled
- **Password**: Auto-generated secure password
- **Join Before Host**: Disabled by default
- **Multiple Devices**: Allowed

## 🔧 Troubleshooting

### Edge Function Not Found
- Ensure the function is deployed: `supabase functions deploy create-zoom-meeting`
- Check function name matches exactly: `create-zoom-meeting`

### Authentication Errors
- Verify Zoom credentials are correct in Edge Function settings
- Check Zoom app status in Zoom Marketplace
- Ensure OAuth app has "Server-to-Server OAuth" type

### Meeting Creation Fails
- Check Edge Function logs in Supabase Dashboard
- Verify Zoom account has meeting creation permissions
- Ensure start time is in the future
- Check duration is valid (minimum 1 minute)

### Missing Meeting URL
- Check if Zoom API call succeeded in Edge Function logs
- Verify online class platform is set to `zoom`
- Check network connectivity

## 📚 API Reference

### ZoomService.createMeeting()

```dart
Future<ZoomMeeting> createMeeting({
  required String title,
  required DateTime startTime,
  required int duration,
  String? description,
  String? password,
  ZoomMeetingSettings? settings,
})
```

**Returns:** `ZoomMeeting` object with:
- `joinUrl`: URL for participants to join
- `startUrl`: URL for host to start meeting
- `password`: Meeting password
- `id`: Zoom meeting ID
- `uuid`: Zoom meeting UUID

## 🔒 Security Notes

- Zoom credentials are stored securely in Supabase Edge Function environment variables
- Credentials are never exposed to the client
- All Zoom API calls are made server-side
- Meeting passwords are auto-generated and secure

## 📝 Next Steps

1. ✅ Deploy Edge Function
2. ✅ Configure environment variables
3. ✅ Test meeting creation
4. Optional: Add meeting update/delete functionality
5. Optional: Add meeting recording retrieval
6. Optional: Add participant management

