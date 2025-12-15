-- =========================================================
-- AUTO-CONFIRM USER FUNCTION
-- This function auto-confirms users during registration
-- =========================================================

-- Create function to auto-confirm user email
create or replace function confirm_user_email(user_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  -- Update auth.users to confirm email
  update auth.users
  set 
    email_confirmed_at = now(),
    confirmed_at = now()
  where id = user_id;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function confirm_user_email(uuid) to authenticated;
grant execute on function confirm_user_email(uuid) to anon;

-- =========================================================
-- ALTERNATIVE: Disable email confirmation in Supabase
-- =========================================================
-- Go to Supabase Dashboard > Authentication > Settings
-- Under "Email Auth", disable "Enable email confirmations"
-- This is the easiest solution for development

