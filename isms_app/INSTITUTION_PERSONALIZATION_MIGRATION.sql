-- =============================================================
-- COMPREHENSIVE INSTITUTION PERSONALIZATION MIGRATION
-- Adds support for multiple institution types with personalized configurations
-- Includes default configurations for each institution type
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

-- 4. Insert default institution types with comprehensive features
INSERT INTO institution_types (type_key, display_name, description, features, constraints) VALUES
  ('school', 'School', 'Traditional educational institution with formal curriculum and structured academic programs', 
   '{"academic_terms": true, "exam_system": true, "grade_levels": true, "sports": true, "extracurricular": true, "library": true, "laboratories": true, "transport": true, "hostel": true}',
   '{"max_students": 5000, "max_teachers": 200, "max_classes": 100, "max_sections": 500}'),
   
  ('madarsa', 'Madarsa', 'Islamic educational institution focusing on religious studies, Quran memorization, and Islamic teachings',
   '{"quran_studies": true, "islamic_subjects": true, "prayer_times": true, "religious_events": true, "hifz_program": true, "islamic_etiquette": true, "arabic_language": true}',
   '{"max_students": 1000, "max_teachers": 50, "max_hifz_students": 200, "prayer_capacity": 500}'),
   
  ('coaching_center', 'Coaching Center', 'Specialized coaching for competitive exams, entrance tests, and subject-specific preparation',
   '{"batch_system": true, "test_series": true, "doubt_sessions": true, "performance_tracking": true, "rank_analysis": true, "study_materials": true, "mock_tests": true}',
   '{"max_students": 500, "max_batches": 20, "max_mock_tests": 100, "concurrent_sessions": 10}'),
   
  ('tuition_center', 'Tuition Center', 'Supplementary education and tutoring services for academic support and skill development',
   '{"individual_tutoring": true, "small_groups": true, "flexible_timing": true, "progress_reports": true, "homework_help": true, "remedial_classes": true, "skill_development": true}',
   '{"max_students": 200, "max_groups": 10, "max_individual_sessions": 50, "session_duration_limit": 120}'),
   
  ('online_institute', 'Online-Only Institute', 'Fully digital education platform with virtual classrooms and online learning resources',
   '{"virtual_classes": true, "digital_assessments": true, "online_submissions": true, "async_learning": true, "video_library": true, "discussion_forums": true, "live_chat": true, "progress_analytics": true}',
   '{"max_students": 10000, "concurrent_sessions": 100, "storage_limit_gb": 100, "bandwidth_limit_mbps": 1000}')
ON CONFLICT (type_key) DO NOTHING;

-- 5. Create default configurations for existing schools
DO $$
DECLARE
  school_record RECORD;
  institution_type_id UUID;
BEGIN
  -- Get the default institution type ID (school)
  SELECT id INTO institution_type_id FROM institution_types WHERE type_key = 'school' LIMIT 1;
  
  -- Update all existing schools to use the default institution type
  UPDATE schools 
  SET institution_type_id = institution_type_id 
  WHERE institution_type_id IS NULL;
  
  -- Create default institution configs for all schools
  FOR school_record IN SELECT id FROM schools
  LOOP
    INSERT INTO institution_configs (
      school_id, 
      institution_type_id,
      academic_structure,
      grading_system,
      academic_calendar,
      timetable_config,
      attendance_modes,
      fee_config,
      online_learning_config
    ) VALUES (
      school_record.id,
      institution_type_id,
      '{"grade_levels": ["Primary", "Middle", "High", "Senior"], "class_structure": "standard", "promotion_rules": "annual"}',
      '{"scale": "percentage", "pass_percentage": 33, "grade_bands": [{"min": 80, "max": 100, "grade": "A"}, {"min": 60, "max": 79, "grade": "B"}, {"min": 33, "max": 59, "grade": "C"}]}',
      '{"terms": ["First Term", "Second Term", "Final Term"], "holidays": [], "exam_schedule": {}}',
      '{"period_duration": 45, "break_duration": 15, "lunch_duration": 45, "max_periods_per_day": 8}',
      '["present", "absent", "late", "half_day"]',
      '{"fee_categories": ["Tuition", "Admission", "Exam", "Transport", "Hostel"], "payment_schedule": "monthly"}',
      '{"video_conferencing": false, "lms_integration": false, "online_assessments": false}'
    ) ON CONFLICT (school_id) DO NOTHING;
  END LOOP;
END $$;

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_institution_configs_school ON institution_configs(school_id);
CREATE INDEX IF NOT EXISTS idx_institution_configs_type ON institution_configs(institution_type_id);
CREATE INDEX IF NOT EXISTS idx_schools_institution_type ON schools(institution_type_id);

-- 7. RLS Policies
ALTER TABLE institution_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE institution_configs ENABLE ROW LEVEL SECURITY;

-- Institution types are readable by all authenticated users
DROP POLICY IF EXISTS institution_types_select_all ON institution_types;
CREATE POLICY institution_types_select_all ON institution_types
  FOR SELECT TO authenticated USING (true);

-- Institution configs are school-specific
DROP POLICY IF EXISTS institution_configs_select_school ON institution_configs;
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

DROP POLICY IF EXISTS institution_configs_manage_school ON institution_configs;
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

-- 8. Update triggers
DROP TRIGGER IF EXISTS update_institution_types_updated_at ON institution_types;
CREATE TRIGGER update_institution_types_updated_at
  BEFORE UPDATE ON institution_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_institution_configs_updated_at ON institution_configs;
CREATE TRIGGER update_institution_configs_updated_at
  BEFORE UPDATE ON institution_configs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Helper functions for institution management
CREATE OR REPLACE FUNCTION get_institution_config(p_school_id UUID)
RETURNS JSONB
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT row_to_json(ic)::jsonb
  FROM institution_configs ic
  WHERE ic.school_id = p_school_id
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION update_institution_config(
  p_school_id UUID,
  p_config JSONB
)
RETURNS VOID
LANGUAGE PLPGSQL
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE institution_configs
  SET 
    academic_structure = COALESCE(p_config->'academic_structure', academic_structure),
    grading_system = COALESCE(p_config->'grading_system', grading_system),
    academic_calendar = COALESCE(p_config->'academic_calendar', academic_calendar),
    timetable_config = COALESCE(p_config->'timetable_config', timetable_config),
    attendance_modes = COALESCE(p_config->'attendance_modes', attendance_modes),
    fee_config = COALESCE(p_config->'fee_config', fee_config),
    online_learning_config = COALESCE(p_config->'online_learning_config', online_learning_config),
    custom_fields = COALESCE(p_config->'custom_fields', custom_fields),
    extensions = COALESCE(p_config->'extensions', extensions),
    updated_at = NOW()
  WHERE school_id = p_school_id;
  
  IF NOT FOUND THEN
    INSERT INTO institution_configs (school_id, institution_type_id, academic_structure, grading_system, academic_calendar, timetable_config, attendance_modes, fee_config, online_learning_config, custom_fields, extensions)
    VALUES (
      p_school_id,
      (SELECT institution_type_id FROM schools WHERE id = p_school_id),
      p_config->'academic_structure',
      p_config->'grading_system',
      p_config->'academic_calendar',
      p_config->'timetable_config',
      p_config->'attendance_modes',
      p_config->'fee_config',
      p_config->'online_learning_config',
      p_config->'custom_fields',
      p_config->'extensions'
    );
  END IF;
END;
$$;

-- 10. Grant permissions
GRANT SELECT ON institution_types TO authenticated;
GRANT ALL ON institution_configs TO authenticated;
GRANT EXECUTE ON FUNCTION get_institution_config TO authenticated;
GRANT EXECUTE ON FUNCTION update_institution_config TO authenticated;

-- =============================================================
-- MIGRATION COMPLETE
-- Run this script to enable institution personalization
-- =============================================================