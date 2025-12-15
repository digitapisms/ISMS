-- Fix remaining RLS policies that re-evaluate auth.uid() for each row
-- Replace auth.uid() with (select auth.uid()) for caching

-- Fix users_select_self policy on users table
DROP POLICY IF EXISTS users_select_self ON public.users;
CREATE POLICY users_select_self ON public.users
    FOR SELECT TO public
    USING ((( SELECT auth.uid() AS uid) = auth_id));

-- Fix profiles_select_self policy on user_profiles table
DROP POLICY IF EXISTS profiles_select_self ON public.user_profiles;
CREATE POLICY profiles_select_self ON public.user_profiles
    FOR SELECT TO public
    USING ((( SELECT auth.uid() AS uid) = ( SELECT u.auth_id
            FROM users u
            WHERE (u.id = user_profiles.user_id))));

-- Fix profiles_update_self policy on user_profiles table
DROP POLICY IF EXISTS profiles_update_self ON public.user_profiles;
CREATE POLICY profiles_update_self ON public.user_profiles
    FOR UPDATE TO public
    USING ((( SELECT auth.uid() AS uid) = ( SELECT u.auth_id
            FROM users u
            WHERE (u.id = user_profiles.user_id))))
    WITH CHECK ((( SELECT auth.uid() AS uid) = ( SELECT u.auth_id
            FROM users u
            WHERE (u.id = user_profiles.user_id))));

-- Fix users_insert_own_profile policy on user_profiles table
DROP POLICY IF EXISTS users_insert_own_profile ON public.user_profiles;
CREATE POLICY users_insert_own_profile ON public.user_profiles
    FOR INSERT TO authenticated
    WITH CHECK ((( SELECT auth.uid() AS uid) = ( SELECT u.auth_id
            FROM users u
            WHERE (u.id = user_profiles.user_id))));

-- Note: We are NOT removing unused indexes at this time because:
-- 1. They are marked as INFO level (not critical)
-- 2. They may become useful as the app grows and query patterns change
-- 3. Removing them prematurely could hurt future performance
-- If storage becomes an issue, we can revisit this later.

