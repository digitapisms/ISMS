# SQL Schema Review Summary

## Date: Review Completed

## Issues Fixed

### 1. Missing `DROP TRIGGER IF EXISTS` Statements
**Fixed in:**
- ✅ `CREATE_PAYMENT_INTEGRATION_SCHEMA.sql`
  - Added `drop trigger if exists` for `update_payment_providers_updated_at`
  - Added `drop trigger if exists` for `update_school_payment_accounts_updated_at`

- ✅ `CREATE_NOTIFICATIONS_SCHEMA.sql`
  - Added `drop trigger if exists` for `update_notification_templates_updated_at`
  - Added `drop trigger if exists` for `update_notification_preferences_updated_at`

- ✅ `CREATE_CLASSES_SECTIONS_SCHEMA.sql`
  - Added `drop trigger if exists` for `update_classes_updated_at`
  - Added `drop trigger if exists` for `update_sections_updated_at`

- ✅ `CREATE_MULTI_TENANT_CORE.sql`
  - Added `drop trigger if exists` for `update_ai_prompts_updated_at`

### 2. Missing `DROP FUNCTION IF EXISTS` Statements
**Fixed in:**
- ✅ `CREATE_REPORTS_ANALYTICS_SCHEMA.sql`
  - Added `drop function if exists` for `get_school_report_overview(uuid)`
  - Added `drop function if exists` for `get_school_report_timeseries(uuid, integer)`

### 3. Function Dependency Issues
**Fixed in:**
- ✅ `CREATE_AUTH_ROLES_SCHEMA.sql`
  - Policies now dropped before functions to avoid dependency errors
  - Functions use `CASCADE` when dropping to handle dependencies

### 4. Prerequisite Column Issues
**Fixed in:**
- ✅ Created `PREREQUISITE_FOR_ENRICHMENT.sql` - separate script to ensure `school_id` columns exist
- ✅ Updated `CREATE_ENRICHMENT_MODULE.sql` to verify prerequisites before running

### 5. Missing Drop Statements in Subscription Plans
**Fixed in:**
- ✅ `CREATE_SUBSCRIPTION_PLANS_SCHEMA.sql`
  - Added `drop trigger if exists` for `update_plan_features_updated_at`
  - Added `drop function if exists` for `is_feature_enabled(text, text)`
  - Added `drop function if exists` for `get_feature_limit(text, text)`
  - Added `drop function if exists` for `get_plan_features(text)`
  - Added `drop policy if exists` for all 4 policies

### 6. Missing Drop Statement for Notification Function
**Fixed in:**
- ✅ `CREATE_NOTIFICATIONS_SCHEMA.sql`
  - Added `drop function if exists` for `render_notification_template(text, jsonb)`

## Redundant/Obsolete Files Identified

The following SQL files appear to be temporary fixes and may be obsolete:
- `FIX_SCHOOL_REGISTRATION_RLS.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_COMPLETE.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_COMPLETE_FINAL.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_FINAL.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_SIMPLE.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_ALTERNATIVE.sql`
- `FIX_SCHOOL_REGISTRATION_FINAL.sql`
- `COMPLETE_REGISTRATION_FIX_ALL_IN_ONE.sql`
- `COMPLETE_SCHOOL_REGISTRATION_RPC.sql`
- `COMPLETE_SCHOOL_REGISTRATION_SETUP.sql`
- `SCHOOL_REGISTRATION_FIX_COMPLETE.sql`
- `SCHOOL_REGISTRATION_DB_UPDATE.sql`
- `FORCE_ENABLE_REGISTRATION.sql`
- `FORCE_REMOVE_RLS_SCHOOLS.sql`
- `REMOVE_RLS_FOR_SCHOOLS.sql`
- `DISABLE_RLS_TEMPORARILY.sql`
- `CREATE_SCHOOL_FUNCTION_BYPASS_RLS.sql`
- `AUTO_CONFIRM_USER_FUNCTION.sql`
- `SAAS_DATABASE_SETUP.sql`

**Recommendation:** Archive or delete these files if they're no longer needed. Keep only the main `CREATE_*.sql` schema files.

## Recommended Execution Order

1. `CREATE_AUTH_ROLES_SCHEMA.sql` - Defines helper functions and user roles
2. `CREATE_MULTI_TENANT_CORE.sql` - Creates schools table and tenant infrastructure
3. `CREATE_CLASSES_SECTIONS_SCHEMA.sql` - Creates classes and sections tables
4. `PREREQUISITE_FOR_ENRICHMENT.sql` - Ensures school_id columns exist (if needed)
5. `CREATE_STAFF_MANAGEMENT_SCHEMA.sql` - Staff management tables
6. `CREATE_NOTIFICATIONS_SCHEMA.sql` - Notification system
7. `CREATE_PAYMENT_INTEGRATION_SCHEMA.sql` - Payment integration
8. `CREATE_REPORTS_ANALYTICS_SCHEMA.sql` - Reports and analytics functions
9. `CREATE_SUBSCRIPTION_PLANS_SCHEMA.sql` - Subscription plans and features
10. `CREATE_ENRICHMENT_MODULE.sql` - Enrichment and play module (requires prerequisites)

## Best Practices Applied

1. ✅ All triggers now have `drop trigger if exists` before creation
2. ✅ All functions that may be redefined have `drop function if exists`
3. ✅ All policies use `drop policy if exists` before creation
4. ✅ Prerequisite checks added where needed
5. ✅ Error messages improved for better debugging

## Notes

- ✅ All triggers now have `drop trigger if exists` before creation
- ✅ All functions that may be redefined have `drop function if exists`
- ✅ All policies use `drop policy if exists` before creation
- ✅ Prerequisite checks added where needed
- ✅ Error messages improved for better debugging
- ✅ The `update_updated_at_column()` function is defined in multiple files (CREATE_CLASSES_SECTIONS_SCHEMA.sql and CREATE_ENRICHMENT_MODULE.sql) - this is fine since it uses `create or replace` and each script should be idempotent

## Files That Can Be Safely Deleted/Archived

The following files appear to be temporary fixes or duplicates and can likely be removed:

### Registration Fix Files (likely obsolete):
- `FIX_SCHOOL_REGISTRATION_RLS.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_COMPLETE.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_COMPLETE_FINAL.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_FINAL.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_SIMPLE.sql`
- `FIX_SCHOOL_REGISTRATION_RLS_ALTERNATIVE.sql`
- `FIX_SCHOOL_REGISTRATION_FINAL.sql`
- `COMPLETE_REGISTRATION_FIX_ALL_IN_ONE.sql`
- `COMPLETE_SCHOOL_REGISTRATION_RPC.sql`
- `COMPLETE_SCHOOL_REGISTRATION_SETUP.sql`
- `SCHOOL_REGISTRATION_FIX_COMPLETE.sql`
- `SCHOOL_REGISTRATION_DB_UPDATE.sql`

### RLS Bypass Files (likely obsolete):
- `FORCE_ENABLE_REGISTRATION.sql`
- `FORCE_REMOVE_RLS_SCHOOLS.sql`
- `REMOVE_RLS_FOR_SCHOOLS.sql`
- `DISABLE_RLS_TEMPORARILY.sql`
- `CREATE_SCHOOL_FUNCTION_BYPASS_RLS.sql`
- `AUTO_CONFIRM_USER_FUNCTION.sql`

### Other Potentially Obsolete:
- `SAAS_DATABASE_SETUP.sql` (may be superseded by individual CREATE_*.sql files)

**Recommendation:** Review these files to confirm they're no longer needed, then archive or delete them to reduce clutter.

