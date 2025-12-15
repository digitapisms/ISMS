-- =============================================================
-- INSTITUTION PERSONALIZATION MIGRATION
-- Adds support for multiple institution types with personalized configurations
-- =============================================================

-- 1. INSTITUTION_TYPE TABLE (Master table for institution types)
CREATE TABLE IF NOT EXISTS institution_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_key VARCHAR(50) NOT NULL UNIQUE, -- school, madarsa, coaching_center, tuition_center, online_institute
  display_name VARCHAR(100) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  features JSONB NOT NULL DEFAULT '{}'::jsonb, -- Available features for this institution type
  constraints JSONB NOT NULL DEFAULT '{}'::jsonb, -- Constraints and limits
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. INSTITUTION_CONFIG TABLE (Per-school configuration)
CREATE TABLE IF NOT EXISTS institution_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  institution_type_id UUID NOT NULL REFERENCES institution_types(id) ON DELETE RESTRICT,
  
  -- Academic Structure Configuration
  academic_structure JSONB NOT NULL DEFAULT '{}'::jsonb, -- Grade levels, classes, sections, etc.
  grading_system JSONB NOT NULL DEFAULT '{}'::jsonb, -- Grading scales, pass marks, etc.
  academic_calendar JSONB NOT NULL DEFAULT '{}'::jsonb, -- Terms, holidays, events
  
  -- Timetable Configuration
  timetable_config JSONB NOT NULL DEFAULT '{}'::jsonb, -- Period structure, breaks, etc.
  attendance_modes JSONB NOT NULL DEFAULT '[]'::jsonb, -- Available attendance modes
  
  -- Fee Structure Configuration
  fee_config JSONB NOT NULL DEFAULT '{}'::jsonb, -- Fee categories, payment schedules
  
  -- Online Learning Configuration
  online_learning_config JSONB NOT NULL DEFAULT '{}'::jsonb, -- Video conferencing, LMS integration
  
  -- Custom Fields and Extensions
  custom_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  extensions JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- Status and Metadata
  is_active BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(school_id)
);

-- 3. Add institution_type_id to schools table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'schools' AND column_name = 'institution_type_id'
  ) THEN
    ALTER TABLE schools ADD COLUMN institution_type_id UUID REFERENCES institution_types(id);
  END IF;
END $$;

-- 4. Insert default institution types
INSERT INTO institution_types (type_key, display_name, description, features, constraints) VALUES
  ('school', 'School', 'Traditional educational institution with formal curriculum', 
   '{"academic_terms": true, "exam_system": true, "grade_levels": true, "sports": true, "extracurricular": true}',
   '{"max_students": 5000, "max_teachers": 200}'),
   
  ('madarsa', 'Madarsa', 'Islamic educational institution focusing on religious studies',
   '{"quran_studies": true, "islamic_subjects": true, "prayer_times": true, "religious_events": true}',
   '{"max_students": 1000, "max_teachers": 50}'),
   
  ('coaching_center', 'Coaching Center', 'Specialized coaching for competitive exams and subjects',
   '{"batch_system": true, "test_series": true, "doubt_sessions": true, "performance_tracking": true}',
   '{"max_students": 500, "max_batches": 20}'),
   
  ('tuition_center', 'Tuition Center', 'Supplementary education and tutoring services',
   '{"individual_tutoring": true, "small_groups": true, "flexible_timing": true, "progress_reports": true}',
   '{"max_students": 200, "max_groups": 10}'),
   
  ('online_institute', 'Online-Only Institute', 'Fully digital education platform',
   '{"virtual_classes": true, "digital_assessments": true, "online_submissions": true, "async_learning": true}',
   '{"max_students": 10000, "concurrent_sessions": 100}')
ON CONFLICT (type_key) DO NOTHING;

-- 5. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_institution_configs_school ON institution_configs(school_id);
CREATE INDEX IF NOT EXISTS idx_institution_configs_type ON institution_configs(institution_type_id);
CREATE INDEX IF NOT EXISTS idx_schools_institution_type ON schools(institution_type_id);

-- 6. RLS Policies
ALTER TABLE institution_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE institution_configs ENABLE ROW LEVEL SECURITY;

-- Institution types are readable by all authenticated users
CREATE POLICY institution_types_select_all ON institution_types
  FOR SELECT TO authenticated USING (true);

-- Institution configs are school-specific
CREATE POLICY institution_configs_select_school ON institution_configs
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE auth_id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY institution_configs_manage_school ON institution_configs
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() AND role IN ('admin', 'principal')
    )
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE auth_id = auth.uid() AND role = 'super_admin'
    )
  );

-- 7. Update triggers
DROP TRIGGER IF EXISTS update_institution_types_updated_at ON institution_types;
CREATE TRIGGER update_institution_types_updated_at
  BEFORE UPDATE ON institution_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_institution_configs_updated_at ON institution_configs;
CREATE TRIGGER update_institution_configs_updated_at
  BEFORE UPDATE ON institution_configs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Helper function to get institution configuration
CREATE OR REPLACE FUNCTION get_institution_config(p_school_id UUID)
RETURNS JSONB
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ic.config
  FROM institution_configs ic
  WHERE ic.school_id = p_school_id
  LIMIT 1;
$$;

-- 9. Grant permissions
GRANT SELECT ON institution_types TO authenticated;
GRANT ALL ON institution_configs TO authenticated;

-- =============================================================
-- MIGRATION COMPLETE
-- =============================================================