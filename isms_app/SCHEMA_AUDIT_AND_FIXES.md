# Schema Audit and Fixes - Release Hardening

## Audit Date: 2025-01-22

## 1. Table Usage Audit

### Tables Referenced in Code (from lib/)
Extracted unique table names from `.from()` calls:

**Core Tables (Exist):**
- `users`, `user_profiles`, `schools`, `students`, `classes`, `sections`
- `attendance_records`, `applications`, `assignments`, `assignment_submissions`
- `staff_profiles`, `staff_invites`, `online_classes`, `online_class_sessions`
- `notifications`, `notification_templates`, `notification_preferences`
- `exams`, `exam_results`, `fee_structures`, `payment_transactions`
- `timetable`, `timetable_entries`, `periods`, `rooms`
- `books`, `book_copies`, `certificate_templates`, `certificates`
- `discipline_incidents`, `discipline_actions`
- `circulars`, `chat_conversations`, `chat_messages`, `school_announcements`
- `visitors`, `visits`, `visitor_logs`, `security_entries`, `visitor_badges`
- `plan_features`, `plan_feature_mapping`, `subscription_plans`
- `system_settings`, `tenant_settings`

**Potentially Missing Tables (Need Verification):**
- `staff_attendance` - Used in `hr/data/staff_repository.dart` ❌
- `leave_requests` - Used in `hr/data/staff_repository.dart` ❌
- `school_subscriptions` - Used in `subscription/data/subscription_repository.dart` ⚠️
- `school_invoices` - Used in `subscription/data/subscription_repository.dart` ⚠️
- `student_documents` - Used in `student_management/data/student_repository.dart` ⚠️
- `family_members` - Used in `student_management/data/student_repository.dart` ⚠️
- `emergency_contacts` - Used in `student_management/data/student_repository.dart` ⚠️
- `student_details` - Used in `student_management/data/student_repository.dart` ⚠️
- `application_fees` - Used in `student_management/data/student_repository.dart` ⚠️
- `assignment_grades` - Used in `assignments/data/assignment_repository.dart` ⚠️
- `assignment_attachments` - Used in `assignments/data/assignment_repository.dart` ⚠️
- `certificate_fields` - Used in `certificates/data/certificates_repository.dart` ⚠️
- `academic_year_configs` - Used in `institution/data/academic_structure_repository.dart` ⚠️
- `academic_periods` - Used in `institution/data/academic_structure_repository.dart` ⚠️
- `ptm_meetings`, `ptm_notes` - Used in `ptm/data/ptm_repository.dart` ⚠️
- `inventory_items` - Used in `inventory/data/inventory_repository.dart` ⚠️
- `chat_message_templates` - Used in `messaging/data/messaging_repository.dart` ⚠️
- `message_attachments`, `read_receipts`, `conversation_participants` - Used in messaging ⚠️
- `announcement_reads`, `circular_reads` - Used in messaging ⚠️
- `bank_transfer_receipts` - Used in `payments/presentation/dialogs/bank_transfer_payment_dialog.dart` ⚠️
- `payment_webhook_logs`, `payment_webhook_errors` - Used in payment services ⚠️
- `ai_prompts`, `ai_tasks` - Used in `ai/data/ai_repository.dart` ⚠️
- `visitor_blacklist` - Used in visitor management ⚠️

**Storage Buckets Referenced:**
- `school-logos` ✅
- `student-documents` ⚠️
- `bank-receipts` ⚠️

## 2. RPC Function Usage Audit

### RPC Functions Referenced in Code

**Exists (from schema):**
- `bulk_mark_attendance` ✅
- `complete_school_registration` ✅
- `confirm_user_email` ✅
- `consume_staff_invite` ✅
- `create_user_record` ✅
- `get_school_by_code_public` ✅
- `get_school_metrics` ✅
- `get_global_analytics` ✅
- `validate_staff_invite` ✅
- `get_class_attendance_summary` ✅
- `get_student_attendance_stats` ✅
- `upsert_school_payment_account` ✅
- `update_updated_at_column` ✅

**Potentially Missing (Need Verification):**
- `render_notification_template` - Used in notifications ⚠️
- `get_quiz_leaderboard` - Used in enrichment ⚠️
- `detect_schedule_conflicts` - Used in timetable ⚠️
- `upsert_tenant_settings` - Used in tenants ⚠️
- `generate_certificate_number` - Used in certificates ⚠️
- `get_staff_attendance_summary` - Used in HR (depends on `staff_attendance` table) ❌
- `get_staff_statistics` - Used in HR ⚠️
- `generate_fee_invoice_number` - Used in fee management ⚠️
- `get_student_fee_summary` - Used in fee management ⚠️
- `create_school` - Used as fallback in school registration ⚠️
- `create_principal_user` - Used as fallback in school registration ⚠️
- `get_subscription_usage` - Used in subscription ⚠️
- `generate_circular_number` - Used in messaging ⚠️
- `increment_template_usage` - Used in messaging ⚠️
- `generate_badge_number` - Used in visitor management ⚠️

## 3. Critical Path Analysis

### Core Flow 1: Super Admin → Create School
**Files:** `school_registration/data/school_repository.dart`
**Tables:** `schools`, `users`, `user_profiles`
**RPCs:** `complete_school_registration`, `create_school`, `create_principal_user`, `confirm_user_email`
**Status:** ✅ Core RPCs exist, but fallbacks may fail

### Core Flow 2: Admin → Invite Staff/Teacher
**Files:** `staff_management/data/staff_repository.dart`
**Tables:** `staff_invites`, `users`
**RPCs:** `validate_staff_invite`, `consume_staff_invite`
**Status:** ✅ All exist

### Core Flow 3: Staff/Teacher Signup
**Files:** `authentication/data/supabase_auth_repository.dart`, `authentication/presentation/signup_screen.dart`
**Tables:** `users`, `user_profiles`, `staff_invites`
**RPCs:** `create_user_record`, `validate_staff_invite`, `consume_staff_invite`
**Status:** ✅ All exist

### Core Flow 4: Staff List
**Files:** `staff_management/data/staff_repository.dart`, `hr/data/staff_repository.dart`
**Tables:** `users`, `staff_profiles`
**RPCs:** None critical
**Status:** ✅ Tables exist

### Core Flow 5: Create Class/Section/Student/Attendance
**Files:** Various
**Tables:** `classes`, `sections`, `students`, `attendance_records`
**RPCs:** `bulk_mark_attendance`
**Status:** ✅ All exist

### Core Flow 6: Online Class Join
**Files:** `online_classes/presentation/tabs/online_classes_tab.dart`
**Tables:** `online_classes`, `online_class_sessions`
**RPCs:** None
**Status:** ⚠️ Join functionality is TODO

## 4. Priority Fixes

### Priority 1: Critical Missing Tables (Will Cause Runtime Crashes)
1. `staff_attendance` - Required for HR module
2. `leave_requests` - Required for HR module

### Priority 2: Error Handling Improvements
- Replace `throw Exception(...)` with `AppError` in critical paths
- Replace `print()` with proper logging

### Priority 3: Feature Completeness
- Implement OnlineClasses Join functionality

### Priority 4: Schema Completeness
- Verify all other tables exist or create migrations
- Verify all other RPC functions exist or create them
