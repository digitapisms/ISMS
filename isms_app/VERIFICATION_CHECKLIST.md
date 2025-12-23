# Verification Checklist - Core Flow Testing

## Pre-Testing Setup

### Database State
- [x] Database cleaned (all data except super admin removed)
- [x] Super admin account exists and is accessible
- [x] All required migrations applied
  - [x] `staff_attendance` and `leave_requests` tables created
  - [x] RPC functions for HR module created

### Environment
- [ ] Supabase project is accessible
- [ ] Flutter app compiles without errors
- [ ] `.env` file configured with correct Supabase credentials

---

## Core Flow 1: Super Admin → Create School

### Steps
1. [ ] Login as super admin
   - Email: `muddasirh@gmail.com` (or your super admin email)
   - Should successfully authenticate

2. [ ] Navigate to School Registration
   - Should see "Register New School" option

3. [ ] Fill in school registration form:
   - School name
   - Email and phone
   - Principal name
   - Principal email (use a test email)
   - Principal password
   - Address, city, state (optional)
   - Logo (optional)

4. [ ] Submit registration
   - Should show loading indicator
   - Should complete without errors
   - Should display success message

### Expected Results
- ✅ School record created in `schools` table
- ✅ Principal user created in `users` table with `role = 'principal'`
- ✅ Principal user profile created in `user_profiles` table
- ✅ School status is `pending` (or `active` if auto-activated)
- ✅ No error messages shown

### Error Indicators (What to Look For)
- ❌ "Failed to create principal account" → Check Supabase auth settings
- ❌ "RPC function returned null" → Check `complete_school_registration` function exists
- ❌ "School record was created but could not be fetched" → Check RLS policies on `schools` table
- ❌ Generic "Registration failed" → Check error logs for correlation ID

---

## Core Flow 2: Admin/Principal → Invite Staff/Teacher

### Prerequisites
- [ ] Completed Core Flow 1 (school created)
- [ ] Logged in as principal/admin

### Steps
1. [ ] Navigate to Staff Management
   - Should see "Invite Staff" or similar option

2. [ ] Click "Invite Staff/Teacher"

3. [ ] Fill in invite form:
   - Email address (use a test email)
   - Full name
   - Role (Teacher or Staff)
   - Optional notes

4. [ ] Submit invite
   - Should generate invite code
   - Should show success message
   - Invite code should be displayed (copy it)

### Expected Results
- ✅ Record created in `staff_invites` table
- ✅ Status is `pending`
- ✅ Invite code is unique
- ✅ `invited_by` set to current user
- ✅ No error messages

### Error Indicators
- ❌ "Failed to create invite" → Check error message details
- ❌ Generic exception → Check `staff_invites` table exists and has proper RLS

---

## Core Flow 3: Staff/Teacher Signup with Invite Code

### Prerequisites
- [ ] Completed Core Flow 2 (invite created)
- [ ] Have invite code and email from Flow 2

### Steps
1. [ ] Navigate to Signup page
   - Should see signup form

2. [ ] Select role "Teacher" or "Staff"
   - Form should show invite code field
   - School code field should be hidden

3. [ ] Enter email (same as used in invite)
   - Should trigger auto-validation (or show "Validate" button)

4. [ ] Enter invite code
   - Should validate automatically
   - Should show success message
   - School code should be auto-filled/hidden

5. [ ] Enter password and confirm password

6. [ ] Submit signup
   - Should complete successfully
   - Should redirect to login or dashboard

### Expected Results
- ✅ User record created in `users` table
- ✅ Role matches invite (not the selected role)
- ✅ `school_id` set correctly from invite
- ✅ `staff_invites` record marked as `accepted`
- ✅ `accepted_at` timestamp set
- ✅ Can login with new credentials

### Error Indicators
- ❌ "school code not found or school is not active" → Check `validate_staff_invite` RPC checks school status
- ❌ "Invalid invite code" → Check code matches exactly
- ❌ "Invite already used" → Check `consume_staff_invite` logic
- ❌ User created but wrong role → Check signup uses `_inviteDetails['role']` not `widget.role`

---

## Core Flow 4: Staff/Teacher Appears in List

### Prerequisites
- [ ] Completed Core Flow 3 (teacher/staff signed up)

### Steps
1. [ ] As principal/admin, navigate to Staff/Teachers list
   - Should see list of staff/teachers

2. [ ] Verify newly signed up user appears
   - Check by email or name

### Expected Results
- ✅ New user appears in list
- ✅ Role is correct (teacher or staff as per invite)
- ✅ School association is correct
- ✅ Status shows as active

### Error Indicators
- ❌ User doesn't appear → Check `StaffRepository.getStaff()` filters by role correctly
- ❌ Wrong role shown → Check signup used invite role, not widget role
- ❌ Wrong school → Check `school_id` was set correctly during signup

---

## Core Flow 5: Create Class/Section/Student/Attendance

### Prerequisites
- [ ] Completed Core Flow 1 (school exists)
- [ ] Logged in as principal/admin

### Steps for Class/Section
1. [ ] Create a class
   - Navigate to Classes/Sections
   - Create new class (e.g., "Grade 1")
   - Should save successfully

2. [ ] Create a section
   - Add section to class (e.g., "Section A")
   - Should save successfully

### Steps for Student
3. [ ] Add a student
   - Navigate to Students
   - Click "Add Student"
   - Fill in required fields:
     - Name
     - Class and Section (from step 1-2)
     - Parent email
     - Other required fields
   - Submit

### Steps for Attendance
4. [ ] Mark attendance
   - Navigate to Attendance
   - Select class/section
   - Mark student as present/absent
   - Save

### Expected Results
- ✅ Class created in `classes` table
- ✅ Section created in `sections` table
- ✅ Student created in `students` table
- ✅ Attendance record created in `attendance_records` table
- ✅ All records linked to correct `school_id`

### Error Indicators
- ❌ "School context is required" → Check school context provider
- ❌ Foreign key violations → Check class/section IDs are correct
- ❌ RLS policy violations → Check policies allow authenticated users to insert

---

## Core Flow 6: Online Class Join Functionality

### Prerequisites
- [ ] Completed Core Flow 1 (school exists)
- [ ] At least one online class created

### Steps
1. [ ] Navigate to Online Classes
   - Should see list of online classes

2. [ ] Click on an online class card
   - Should show class details

3. [ ] Click "Join Class" button
   - Should attempt to open meeting URL

### Expected Results
- ✅ If meeting URL exists: Opens in external browser/app (Zoom/Google Meet)
- ✅ If URL is missing: Shows error message "Meeting URL is not available"
- ✅ If URL is invalid: Shows error message with details
- ✅ No app crashes

### Error Indicators
- ❌ App crashes on join → Check URL parsing logic
- ❌ Nothing happens → Check `url_launcher` package is configured
- ❌ "Could not launch URL" → Check URL format and device capabilities

---

## General Error Checking

### What to Monitor
- [ ] No uncaught exceptions in console/logs
- [ ] Error messages are user-friendly (not technical stack traces)
- [ ] Correlation IDs shown in error messages (for debugging)
- [ ] Loading indicators appear during async operations
- [ ] Success messages appear after operations complete

### Common Error Patterns
- **Database errors**: Check table/RPC exists, RLS policies, foreign key constraints
- **Auth errors**: Check email confirmation settings, user exists in auth.users
- **Network errors**: Check Supabase connection, API keys
- **Validation errors**: Check required fields, format validation

---

## Post-Testing Verification

### Database Verification Queries

```sql
-- Check schools
SELECT id, name, email, status FROM schools ORDER BY created_at DESC LIMIT 5;

-- Check users
SELECT id, email, role, school_id, status FROM users ORDER BY created_at DESC LIMIT 10;

-- Check staff invites
SELECT id, email, role, status, invite_code, accepted_at FROM staff_invites ORDER BY created_at DESC LIMIT 10;

-- Check students
SELECT id, name, class_id, school_id FROM students ORDER BY created_at DESC LIMIT 5;

-- Check attendance
SELECT id, student_id, attendance_date, status FROM attendance_records ORDER BY created_at DESC LIMIT 5;

-- Check online classes
SELECT id, title, platform, meeting_url FROM online_classes ORDER BY created_at DESC LIMIT 5;
```

### Expected Database State After Full Test
- 1 school (status: active or pending)
- 2-3 users (super admin + principal + invited staff/teacher)
- 1-2 staff invites (at least 1 accepted)
- 1+ students
- 1+ attendance records
- 0+ online classes (if tested)

---

## Troubleshooting Guide

### Issue: "School context is required"
**Solution**: Ensure school context provider is set up correctly and user has `school_id`

### Issue: Invite code validation fails
**Solution**: 
- Check `validate_staff_invite` RPC exists
- Check school is active
- Check invite code matches exactly (case-sensitive)
- Check invite is not expired

### Issue: Staff doesn't appear in list
**Solution**:
- Verify user `role` matches query filter
- Check `school_id` is set correctly
- Verify RLS policies allow reading

### Issue: Join class doesn't open URL
**Solution**:
- Check `meetingUrl` is set in database
- Check `url_launcher` package is in `pubspec.yaml`
- Check URL format is valid
- Check device has browser/meeting app installed

---

## Success Criteria

✅ **All 6 core flows complete without errors**
✅ **User-friendly error messages appear when issues occur**
✅ **Database records created correctly**
✅ **No uncaught exceptions**
✅ **App remains stable and responsive**

If all flows pass, the app is **test-ready** for broader testing.
