-- Ensure the system_settings table has an is_encrypted flag for sensitive values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'system_settings'
      AND column_name = 'is_encrypted'
  ) THEN
    ALTER TABLE public.system_settings
      ADD COLUMN is_encrypted boolean NOT NULL DEFAULT false;
  END IF;
END
$$;

-- Normalize any existing rows (in case the column is created without default)
UPDATE public.system_settings
SET is_encrypted = COALESCE(is_encrypted, false);

