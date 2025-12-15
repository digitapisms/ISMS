-- =========================================================
-- DATABASE UPDATE FOR ENHANCED SCHOOL REGISTRATION
-- =========================================================

-- Add new columns to schools table
alter table schools add column if not exists slogan text;
alter table schools add column if not exists school_type text; -- individual, group
alter table schools add column if not exists group_name text;
alter table schools add column if not exists boards_organizations text;
alter table schools add column if not exists charity_foundation_type text; -- charity_based, foundation, part_of_foundation

-- Create storage bucket for school logos if it doesn't exist
-- Note: Run this in Supabase Dashboard > Storage > Create Bucket
-- Bucket name: school-logos
-- Public: true
-- File size limit: 2MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- Update RLS policies if needed (schools table policies should already allow inserts)
-- No additional RLS changes needed as registration is open to all authenticated users

