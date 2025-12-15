-- Add richer metadata for student records
ALTER TABLE public.student_details
  ADD COLUMN IF NOT EXISTS full_name text,
  ADD COLUMN IF NOT EXISTS avatar_url text;

-- Ensure the students_view exposes the new metadata
DROP VIEW IF EXISTS public.students_view;

CREATE VIEW public.students_view AS
SELECT
  s.id,
  s.admission_no,
  COALESCE(up.full_name, sd.full_name, s.admission_no, ''::text) AS full_name,
  c.name AS class_name,
  sec.name AS section_name,
  s.class_id,
  s.section_id,
  s.status,
  sd.dob,
  sd.gender,
  sd.blood_group,
  sd.medical_info,
  COALESCE(up.avatar_url, sd.avatar_url) AS avatar_url,
  s.created_at
FROM students s
  LEFT JOIN users u ON u.id = s.user_id
  LEFT JOIN user_profiles up ON up.user_id = u.id
  LEFT JOIN classes c ON c.id = s.class_id
  LEFT JOIN sections sec ON sec.id = s.section_id
  LEFT JOIN student_details sd ON sd.student_id = s.id;

