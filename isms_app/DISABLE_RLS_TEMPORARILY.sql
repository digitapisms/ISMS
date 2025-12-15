-- =========================================================
-- TEMPORARY RLS DISABLE FOR REGISTRATION
-- Use this ONLY if RPC functions are not working
-- This disables RLS temporarily to allow registration
-- =========================================================

-- DISABLE RLS on schools table (TEMPORARY - for registration only)
alter table schools disable row level security;

-- DISABLE RLS on users table (TEMPORARY - for registration only)
alter table users disable row level security;

-- DISABLE RLS on user_profiles table (TEMPORARY - for registration only)
alter table user_profiles disable row level security;

-- =========================================================
-- NOTE: After registration works, you can re-enable RLS
-- and use the RPC functions instead:
-- 
-- alter table schools enable row level security;
-- alter table users enable row level security;
-- alter table user_profiles enable row level security;
-- =========================================================

