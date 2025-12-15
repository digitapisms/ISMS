-- =============================================================
-- PREREQUISITE SETUP FOR ENRICHMENT MODULE
-- =============================================================
-- RUN THIS SCRIPT FIRST, BEFORE CREATE_ENRICHMENT_MODULE.sql
-- This ensures all required columns exist before PostgreSQL
-- parses the enrichment module script.

-- 1. Verify schools table exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'schools' AND table_schema = 'public'
  ) THEN
    RAISE EXCEPTION 'schools table does not exist. Please run CREATE_MULTI_TENANT_CORE.sql first.';
  END IF;
END $$;

-- 2. Add school_id to students table if missing
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'students' AND table_schema = 'public'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'students' AND column_name = 'school_id' AND table_schema = 'public'
    ) THEN
      ALTER TABLE students ADD COLUMN school_id uuid;
      
      IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'schools' AND table_schema = 'public'
      ) THEN
        ALTER TABLE students 
          ADD CONSTRAINT students_school_id_fkey 
          FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
      END IF;
      
      -- Try to populate from classes
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'students' AND column_name = 'class_id' AND table_schema = 'public'
      ) AND EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'classes' AND column_name = 'school_id' AND table_schema = 'public'
      ) THEN
        UPDATE students s
        SET school_id = c.school_id
        FROM classes c
        WHERE s.class_id = c.id AND s.school_id IS NULL;
      END IF;
      
      -- Try to populate from users
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'students' AND column_name = 'user_id' AND table_schema = 'public'
      ) AND EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'school_id' AND table_schema = 'public'
      ) THEN
        UPDATE students s
        SET school_id = u.school_id
        FROM users u
        WHERE s.user_id = u.id AND s.school_id IS NULL;
      END IF;
    END IF;
  END IF;
END $$;

-- 3. Add school_id to classes table if missing
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'classes' AND table_schema = 'public'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'classes' AND column_name = 'school_id' AND table_schema = 'public'
    ) THEN
      ALTER TABLE classes ADD COLUMN school_id uuid;
      
      IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'schools' AND table_schema = 'public'
      ) THEN
        ALTER TABLE classes 
          ADD CONSTRAINT classes_school_id_fkey 
          FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
      END IF;
    END IF;
  END IF;
END $$;

-- 4. Final verification
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'students' AND table_schema = 'public'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'students' AND column_name = 'school_id' AND table_schema = 'public'
    ) THEN
      RAISE EXCEPTION 'CRITICAL: students.school_id column is still missing. Please check for errors above and ensure schools table exists.';
    END IF;
  END IF;
  
  RAISE NOTICE 'SUCCESS: All prerequisite columns verified. You can now run CREATE_ENRICHMENT_MODULE.sql';
END $$;

