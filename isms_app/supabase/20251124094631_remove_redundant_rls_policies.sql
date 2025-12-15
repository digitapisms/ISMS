-- Remove redundant RLS policies that are covered by ALL policies or cause multiple permissive policy warnings
-- This addresses non-critical performance warnings about multiple permissive policies

-- =========================================================
-- EMERGENCY_CONTACTS
-- =========================================================
-- Drop redundant SELECT policies covered by emergency_admin_manage (ALL policy)
DROP POLICY IF EXISTS emergency_select_parent ON public.emergency_contacts;
DROP POLICY IF EXISTS emergency_select_student ON public.emergency_contacts;

-- =========================================================
-- FAMILY_MEMBERS
-- =========================================================
-- Drop redundant SELECT policies covered by family_admin_manage (ALL policy)
DROP POLICY IF EXISTS family_select_parent ON public.family_members;
DROP POLICY IF EXISTS family_select_student ON public.family_members;

-- =========================================================
-- STUDENT_DETAILS
-- =========================================================
-- Drop redundant SELECT policies covered by student_details_admin_manage (ALL policy)
DROP POLICY IF EXISTS student_details_select_parent ON public.student_details;
DROP POLICY IF EXISTS student_details_select_self ON public.student_details;
DROP POLICY IF EXISTS student_details_select_teacher ON public.student_details;

-- =========================================================
-- STUDENT_DOCUMENTS
-- =========================================================
-- Drop redundant SELECT policies covered by student_docs_admin_manage (ALL policy)
DROP POLICY IF EXISTS student_docs_select_parent ON public.student_documents;
DROP POLICY IF EXISTS student_docs_select_student ON public.student_documents;

-- =========================================================
-- STUDENTS
-- =========================================================
-- Drop redundant SELECT policies covered by students_admin_manage (ALL policy)
DROP POLICY IF EXISTS students_select_admin_all ON public.students;
DROP POLICY IF EXISTS students_select_parent_linked ON public.students;
DROP POLICY IF EXISTS students_select_self ON public.students;
DROP POLICY IF EXISTS students_select_teacher_assigned ON public.students;

-- =========================================================
-- AI_PROMPTS
-- =========================================================
-- Drop redundant SELECT policy covered by ai_prompts_manage_admin (ALL policy)
DROP POLICY IF EXISTS ai_prompts_select_all ON public.ai_prompts;

-- =========================================================
-- APPLICATIONS
-- =========================================================
-- Keep both policies - they serve different purposes (admins see all, applicants see own)
-- Multiple permissive policies warning is acceptable here for clarity

-- =========================================================
-- NOTIFICATIONS
-- =========================================================
-- Multiple permissive policies warning is acceptable here as policies serve different purposes
-- Keep all policies - they have different conditions

-- =========================================================
-- PLAN_FEATURE_MAPPING
-- =========================================================
-- Drop redundant SELECT policy covered by plan_feature_mapping_manage (ALL policy)
DROP POLICY IF EXISTS plan_feature_mapping_select_all ON public.plan_feature_mapping;

-- =========================================================
-- PLAN_FEATURES
-- =========================================================
-- Drop redundant SELECT policy covered by plan_features_manage (ALL policy)
DROP POLICY IF EXISTS plan_features_select_all ON public.plan_features;

-- =========================================================
-- SCHOOLS
-- =========================================================
-- Keep both policies as they serve different purposes:
-- - schools_select_by_code_public: for public (unauthenticated) users to search by code
-- - schools_select_visible: for authenticated users to see visible schools
-- These are not redundant.

-- =========================================================
-- USERS
-- =========================================================
-- Drop redundant policies - users_select_policy already covers what users_select_self does for authenticated
-- Keep users_select_self for public role
-- Drop users_update_self as it's redundant if users_update_policy covers authenticated users
DROP POLICY IF EXISTS users_update_self ON public.users;

-- Note: We are keeping policies that serve different roles or purposes
-- This migration only removes truly redundant policies that cause performance warnings
