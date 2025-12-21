# Online Classes Architecture - ISMS

This document explains how Zoom/Google Meet integration works in the ISMS application for conducting online classes between schools/teachers and students/parents.

## 📋 Overview

The ISMS application supports online classes using two main platforms:
- **Zoom** (Fully implemented with API integration)
- **Google Meet** (Service layer ready, Edge Function needs deployment)
- **Custom Platform** (Manual URL entry)

The system allows teachers/schools to create scheduled online classes, and students/parents can join these classes using meeting links.

---

## 🏗️ Architecture

### Components

1. **Frontend (Flutter/Dart)**
   - `OnlineClassRepository` - Data layer for CRUD operations
   - `ZoomService` - Client-side service for Zoom API calls
   - `GoogleMeetService` - Client-side service for Google Meet API calls
   - `OnlineClassEngine` - Business logic for class configuration
   - UI Components - Screens and tabs for viewing/managing classes

2. **Backend (Supabase)**
   - PostgreSQL Database Tables:
     - `online_classes` - Stores online class definitions
     - `online_class_sessions` - Stores individual session instances
   - Edge Functions:
     - `create-zoom-meeting` - Creates Zoom meetings via API
     - `create-google-meet` - (Needs deployment) Creates Google Meet links

3. **External APIs**
   - Zoom API (via Server-to-Server OAuth)
   - Google Calendar/Meet API (planned)

---

## 🔄 How It Works

### 1. Creating an Online Class (Teacher/School Admin)

**Flow:**
```
Teacher creates class → Repository processes → Platform API called → Meeting URL saved → Class available
```

**Step-by-Step:**

1. **Teacher/School Admin creates an online class:**
   - Navigates to Online Classes section
   - Fills in class details:
     - Title and description
     - Platform (Zoom/Google Meet/Custom)
     - Scheduled start/end times
     - Duration
     - Expected participants
     - Features (recording, waiting room, breakout rooms, chat, etc.)

2. **Repository receives the request:**
   ```dart
   OnlineClassRepository.createOnlineClass(onlineClass)
   ```

3. **Platform-specific meeting creation:**
   
   **For Zoom:**
   - If platform is `OnlineClassPlatform.zoom`:
     - Repository calls `ZoomService.createMeeting()`
     - `ZoomService` invokes Supabase Edge Function `create-zoom-meeting`
     - Edge Function:
       - Authenticates with Zoom using OAuth 2.0 Server-to-Server
       - Creates meeting via Zoom API (`POST /v2/users/me/meetings`)
       - Returns meeting details (join URL, password, start URL)
     - Repository saves meeting URL and password to database
   
   **For Google Meet:**
   - If platform is `OnlineClassPlatform.googleMeet`:
     - Repository calls `GoogleMeetService.createMeeting()`
     - `GoogleMeetService` invokes Supabase Edge Function `create-google-meet`
     - Edge Function creates Google Calendar event with Meet link
     - Repository saves meeting URL to database
   
   **For Custom Platform:**
   - Teacher manually enters meeting URL
   - Repository saves the custom URL directly

4. **Class saved to database:**
   - `online_classes` table stores:
     - Class metadata (title, description, platform)
     - Meeting URL and password
     - Scheduled times
     - Feature flags (recording, waiting room, etc.)
     - School ID and creator ID

5. **Class becomes available:**
   - Students/parents can see the class in their "Upcoming Sessions"
   - Teachers can manage the class

---

### 2. Joining an Online Class (Students/Parents)

**Current Implementation Status:**
⚠️ **Join functionality is partially implemented** - The UI shows "Join" buttons, but the actual URL opening is marked as `TODO` in the code.

**Flow:**
```
Student sees session → Clicks Join → Meeting URL opened → Student joins on Zoom/Meet app/browser
```

**Step-by-Step:**

1. **Student/Parent views upcoming sessions:**
   - Opens "Online Classes" section
   - Sees list of scheduled sessions in "Upcoming Sessions" tab
   - Each session shows:
     - Class title and description
     - Scheduled start/end time
     - Time until session starts
     - Platform (Zoom/Google Meet)
     - "Join Session" button

2. **Student clicks "Join Session":**
   - Currently shows a SnackBar: `"Joining [Class Title]..."`
   - **TODO:** Should open meeting URL using:
     ```dart
     // Example implementation needed:
     url_launcher.launchUrl(Uri.parse(session.onlineClass.meetingUrl));
     ```

3. **Meeting URL opens:**
   - **Zoom:** Opens `https://zoom.us/j/[MEETING_ID]?pwd=[PASSWORD]`
     - Browser opens Zoom web client
     - Or Zoom desktop/mobile app opens if installed
     - Student enters meeting password if required
     - Waiting room (if enabled) - teacher approves entry
   
   - **Google Meet:** Opens `https://meet.google.com/[MEETING_CODE]`
     - Browser opens Google Meet
     - No password required typically
     - Student joins directly

4. **Student participates:**
   - Video/audio enabled (based on settings)
   - Can use chat, raise hand, screen share (based on permissions)
   - Session can be recorded if enabled

---

### 3. Session Management

**Online Class vs. Session:**
- **Online Class:** The template/definition (e.g., "Math Class - Grade 5")
- **Session:** A specific instance/occurrence (e.g., "Math Class - Dec 20, 2024 at 2 PM")

**Session Lifecycle:**

1. **Scheduled:** Session is created and waiting to start
2. **In Progress:** Teacher starts session (actual_start recorded)
3. **Completed:** Session ends (actual_end recorded)
4. **Cancelled:** Session cancelled before start
5. **Ended:** Session manually ended

**Session Tracking:**
- `online_class_sessions` table tracks:
  - Scheduled vs. actual start/end times
  - Expected vs. actual participant count
  - Join URL (same as parent class or session-specific)
  - Recording URL (if recorded)
  - Session status
  - Moderator notes

---

## 🗄️ Database Schema

### `online_classes` Table

```sql
- id (UUID, Primary Key)
- school_id (UUID, Foreign Key → schools.id)
- institution_type_id (UUID, Foreign Key)
- title (Text)
- description (Text)
- platform (Enum: 'zoom', 'google_meet', 'custom')
- duration_minutes (Integer)
- scheduled_start (Timestamp)
- scheduled_end (Timestamp)
- meeting_url (Text) -- Join URL for participants
- meeting_password (Text) -- For Zoom meetings
- custom_meeting_url (Text, Nullable) -- For custom platform
- expected_participants (Integer)
- record_session (Boolean)
- breakout_rooms_enabled (Boolean)
- waiting_room_enabled (Boolean)
- chat_enabled (Boolean)
- screen_sharing_enabled (Boolean)
- hand_raise_enabled (Boolean)
- polling_enabled (Boolean)
- qa_enabled (Boolean)
- created_by (UUID, Foreign Key → users.id)
- created_at (Timestamp)
- updated_at (Timestamp)
- is_active (Boolean)
```

### `online_class_sessions` Table

```sql
- id (UUID, Primary Key)
- online_class_id (UUID, Foreign Key → online_classes.id)
- school_id (UUID, Foreign Key → schools.id)
- scheduled_start (Timestamp)
- scheduled_end (Timestamp)
- actual_start (Timestamp, Nullable)
- actual_end (Timestamp, Nullable)
- expected_participants (Integer)
- actual_participants (Integer)
- join_url (Text)
- recording_url (Text, Nullable)
- chat_transcript_url (Text, Nullable)
- moderator_notes (Text, Nullable)
- status (Enum: 'scheduled', 'in_progress', 'completed', 'cancelled', 'ended')
- created_by (UUID, Foreign Key → users.id)
- created_at (Timestamp)
- updated_at (Timestamp)
```

---

## 🔐 Security & Authentication

### Zoom Integration

1. **OAuth 2.0 Server-to-Server:**
   - Zoom credentials stored in Supabase Edge Function environment variables
   - Never exposed to client
   - Edge Function authenticates with Zoom API using:
     - Account ID (starts with `C-`)
     - Client ID
     - Client Secret
   
2. **Meeting Security:**
   - Auto-generated secure passwords (6 characters)
   - Waiting room (optional) - teacher approves participants
   - Password-protected meetings
   - Can enforce login (optional)

### Google Meet Integration

- Google Meet links typically don't require passwords
- Access controlled via Google Calendar permissions
- (Implementation pending)

---

## ⚙️ Configuration

### Institution-Specific Settings

The `OnlineClassEngine` provides different configurations based on institution type:

**Madrasa:**
- Max 50 participants
- 60-minute default duration
- Recording disabled (by default)
- Moderator approval required

**Coaching Center:**
- Max 25 participants
- 90-minute default duration
- Recording enabled
- Breakout rooms enabled
- Polling enabled

**Tuition Center:**
- Max 15 participants
- 120-minute default duration
- Recording enabled
- Q&A enabled

**School:**
- Max 100 participants
- 45-minute default duration
- All features enabled
- Moderator approval required

### Platform Defaults

**Zoom:**
- Waiting room: Configurable
- Recording: Cloud recording if enabled
- Audio: Both telephony and VoIP
- Video: Host and participant enabled
- Join before host: Disabled
- Multiple devices: Allowed

**Google Meet:**
- No password required
- Direct join
- (More settings pending implementation)

---

## 📱 User Interface

### For Teachers/School Admins

1. **Online Classes Tab:**
   - List of all created classes
   - Shows platform icon (Zoom/Meet)
   - Active/Inactive status
   - View details, Join class buttons

2. **Create Class Form:**
   - Title, description
   - Platform selection
   - Schedule (start/end time, duration)
   - Features toggles
   - Participant limit

3. **Upcoming Sessions Tab:**
   - List of scheduled sessions
   - Time until start
   - Join session button

4. **Session History Tab:**
   - Completed sessions
   - Recording links (if available)
   - Participant statistics

### For Students/Parents

1. **Upcoming Sessions Tab:**
   - List of sessions they can join
   - Time until start
   - Join Session button
   - Class details

2. **Session History Tab:**
   - Past sessions
   - Access to recordings (if enabled)
   - Attendance information

---

## 🚧 Current Implementation Status

### ✅ Fully Implemented

1. **Zoom Integration:**
   - ✅ Zoom service layer
   - ✅ Supabase Edge Function for Zoom API
   - ✅ Meeting creation with settings
   - ✅ Password generation
   - ✅ OAuth 2.0 Server-to-Server authentication
   - ✅ Meeting URL storage

2. **Data Layer:**
   - ✅ Repository for CRUD operations
   - ✅ Database schema (online_classes, online_class_sessions)
   - ✅ Session management
   - ✅ Status tracking

3. **Business Logic:**
   - ✅ OnlineClassEngine with institution-specific configs
   - ✅ Validation
   - ✅ Platform-specific URL generation (Zoom)

4. **UI Components:**
   - ✅ Online Classes list view
   - ✅ Upcoming Sessions tab
   - ✅ Session History tab
   - ✅ Class details dialog

### ⚠️ Partially Implemented

1. **Join Functionality:**
   - ⚠️ UI buttons exist
   - ⚠️ URL opening not implemented (marked as TODO)
   - Need to use `url_launcher` package to open meeting URLs

2. **Google Meet Integration:**
   - ⚠️ Service layer exists
   - ⚠️ Edge Function `create-google-meet` not deployed
   - ⚠️ Google Calendar API integration pending

### ❌ Not Implemented

1. **Meeting Management:**
   - ❌ Update/delete Zoom meetings
   - ❌ Retrieve meeting recordings
   - ❌ Participant management

2. **Notifications:**
   - ❌ Email/SMS reminders for upcoming sessions
   - ❌ Push notifications

3. **Attendance Tracking:**
   - ❌ Automatic attendance from meeting participation
   - ❌ Participant list from Zoom/Meet API

4. **Advanced Features:**
   - ❌ Breakout rooms management
   - ❌ Polling integration
   - ❌ Q&A moderation
   - ❌ Screen sharing controls

---

## 🔧 Setup Requirements

### Zoom Setup

1. **Create Zoom OAuth App:**
   - Go to Zoom Marketplace: https://marketplace.zoom.us/
   - Create a Server-to-Server OAuth app
   - Enable scopes: `meeting:write:meeting`, `meeting:write:meeting:admin`
   - Note down: Account ID, Client ID, Client Secret

2. **Deploy Edge Function:**
   ```bash
   cd isms_app
   supabase functions deploy create-zoom-meeting
   ```

3. **Configure Environment Variables (Supabase Dashboard):**
   - `ZOOM_ACCOUNT_ID` = `C-...`
   - `ZOOM_CLIENT_ID` = `...`
   - `ZOOM_CLIENT_SECRET` = `...`

### Google Meet Setup

1. **Create Google Cloud Project:**
   - Enable Google Calendar API
   - Enable Google Meet API
   - Create OAuth 2.0 credentials

2. **Deploy Edge Function:**
   ```bash
   cd isms_app
   supabase functions deploy create-google-meet
   ```

3. **Configure Environment Variables:**
   - `GOOGLE_CLIENT_ID` = `...`
   - `GOOGLE_CLIENT_SECRET` = `...`
   - `GOOGLE_CALENDAR_ID` = `...`

---

## 📝 Code Locations

### Key Files

**Frontend:**
- `lib/src/features/online_classes/data/online_class_repository.dart` - Data layer
- `lib/src/features/online_classes/services/zoom_service.dart` - Zoom integration
- `lib/src/features/online_classes/services/google_meet_service.dart` - Google Meet integration
- `lib/src/features/online_classes/application/online_class_engine.dart` - Business logic
- `lib/src/features/online_classes/presentation/online_classes_screen.dart` - Main screen
- `lib/src/features/online_classes/presentation/tabs/online_classes_tab.dart` - Classes list
- `lib/src/features/online_classes/presentation/tabs/upcoming_sessions_tab.dart` - Upcoming sessions
- `lib/src/features/online_classes/domain/online_class.dart` - Domain model
- `lib/src/features/online_classes/domain/online_class_session.dart` - Session model

**Backend:**
- `supabase/functions/create-zoom-meeting/index.ts` - Zoom Edge Function
- `supabase/functions/create-google-meet/index.ts` - (Needs to be created) Google Meet Edge Function

**Documentation:**
- `ZOOM_INTEGRATION_SETUP.md` - Zoom setup guide

---

## 🎯 Summary

The ISMS online classes feature provides a complete foundation for conducting virtual classes using Zoom or Google Meet. The architecture separates concerns well:

- **Frontend** handles UI and calls services
- **Services** abstract platform-specific APIs
- **Edge Functions** securely handle API credentials
- **Database** stores class and session data

**Current State:**
- Zoom integration is production-ready
- Google Meet service layer is ready, but Edge Function needs deployment
- Join functionality needs URL launcher implementation
- Many advanced features are planned but not yet implemented

**To Complete Join Functionality:**
1. Add `url_launcher` package to `pubspec.yaml`
2. Implement URL opening in `_joinClass()` and `_joinSession()` methods
3. Handle platform-specific URL formats (Zoom password in URL, etc.)

**Next Steps for Full Feature:**
1. Deploy Google Meet Edge Function
2. Implement URL launcher for join buttons
3. Add meeting update/delete capabilities
4. Integrate recording retrieval
5. Add attendance tracking from meeting participants
6. Implement notifications for upcoming sessions
