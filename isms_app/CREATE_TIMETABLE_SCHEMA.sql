-- Timetable/Schedule Management System Schema
-- Supports comprehensive class and teacher scheduling

-- ============================================================
-- PERIODS TABLE (Time slots)
-- ============================================================
CREATE TABLE IF NOT EXISTS periods (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL, -- e.g., "Period 1", "Recess", "Lunch"
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (end_time - start_time)) / 60
  ) STORED,
  period_type VARCHAR(50) DEFAULT 'regular', -- regular, break, lunch, assembly
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, name)
);

-- ============================================================
-- ROOMS TABLE (Venues/Classrooms)
-- ============================================================
CREATE TABLE IF NOT EXISTS rooms (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL, -- e.g., "Room 101", "Physics Lab", "Library"
  code VARCHAR(50),
  room_type VARCHAR(50) DEFAULT 'classroom', -- classroom, lab, library, hall, sports, computer_lab
  capacity INTEGER,
  floor_number INTEGER,
  building_name VARCHAR(255),
  facilities TEXT[], -- e.g., ['projector', 'whiteboard', 'computers']
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, code)
);

-- ============================================================
-- TIMETABLES TABLE (Main timetable records)
-- ============================================================
CREATE TABLE IF NOT EXISTS timetables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL, -- e.g., "Class 10-A Timetable 2024-2025"
  class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50), -- first_term, second_term, third_term, annual
  effective_from DATE,
  effective_to DATE,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(class_id, section_id, academic_year, term)
);

-- ============================================================
-- TIMETABLE ENTRIES TABLE (Individual period assignments)
-- ============================================================
CREATE TABLE IF NOT EXISTS timetable_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  timetable_id UUID NOT NULL REFERENCES timetables(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL, -- 1=Monday, 2=Tuesday, ..., 7=Sunday
  period_id INTEGER NOT NULL REFERENCES periods(id) ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  room_id INTEGER REFERENCES rooms(id) ON DELETE SET NULL,
  notes TEXT,
  is_substitute BOOLEAN DEFAULT false,
  substitute_teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(timetable_id, day_of_week, period_id)
);

-- ============================================================
-- TEACHER ASSIGNMENTS TABLE (Teacher-subject-class assignments)
-- ============================================================
CREATE TABLE IF NOT EXISTS teacher_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50),
  is_primary BOOLEAN DEFAULT true, -- Primary teacher vs substitute
  workload_hours DECIMAL(5,2), -- Weekly hours
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(teacher_id, subject_id, class_id, section_id, academic_year, term)
);

-- ============================================================
-- SCHEDULE CONFLICTS TABLE (Conflict tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS schedule_conflicts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  conflict_type VARCHAR(50) NOT NULL, -- teacher_conflict, room_conflict, class_conflict
  timetable_entry_id UUID REFERENCES timetable_entries(id) ON DELETE CASCADE,
  conflicting_entry_id UUID REFERENCES timetable_entries(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES users(id),
  room_id INTEGER REFERENCES rooms(id),
  class_id INTEGER REFERENCES classes(id),
  conflict_details JSONB, -- Detailed conflict information
  severity VARCHAR(20) DEFAULT 'warning', -- warning, error, critical
  is_resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES users(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_periods_school_id ON periods(school_id);
CREATE INDEX IF NOT EXISTS idx_rooms_school_id ON rooms(school_id);
CREATE INDEX IF NOT EXISTS idx_timetables_class_id ON timetables(class_id);
CREATE INDEX IF NOT EXISTS idx_timetables_academic_year ON timetables(academic_year);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_timetable_id ON timetable_entries(timetable_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_day_period ON timetable_entries(day_of_week, period_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_teacher_id ON timetable_entries(teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_room_id ON timetable_entries(room_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_teacher_id ON teacher_assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_class_id ON teacher_assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_schedule_conflicts_school_id ON schedule_conflicts(school_id);
CREATE INDEX IF NOT EXISTS idx_schedule_conflicts_resolved ON schedule_conflicts(is_resolved);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_periods_updated_at BEFORE UPDATE ON periods
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timetables_updated_at BEFORE UPDATE ON timetables
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timetable_entries_updated_at BEFORE UPDATE ON timetable_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teacher_assignments_updated_at BEFORE UPDATE ON teacher_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- RLS POLICIES
-- ============================================================
ALTER TABLE periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_conflicts ENABLE ROW LEVEL SECURITY;

-- Periods policies
CREATE POLICY periods_select_school ON periods
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = periods.school_id
    )
  );

CREATE POLICY periods_insert_school ON periods
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = periods.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY periods_update_school ON periods
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = periods.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Rooms policies
CREATE POLICY rooms_select_school ON rooms
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = rooms.school_id
    )
  );

CREATE POLICY rooms_insert_school ON rooms
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = rooms.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY rooms_update_school ON rooms
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = rooms.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Timetables policies
CREATE POLICY timetables_select_school ON timetables
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetables.school_id
    )
  );

CREATE POLICY timetables_insert_school ON timetables
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetables.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY timetables_update_school ON timetables
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetables.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Timetable entries policies
CREATE POLICY timetable_entries_select_school ON timetable_entries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetable_entries.school_id
    )
  );

CREATE POLICY timetable_entries_insert_school ON timetable_entries
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetable_entries.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY timetable_entries_update_school ON timetable_entries
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = timetable_entries.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Teacher assignments policies
CREATE POLICY teacher_assignments_select_school ON teacher_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = teacher_assignments.school_id
    )
  );

CREATE POLICY teacher_assignments_insert_school ON teacher_assignments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = teacher_assignments.school_id
      AND users.role IN ('admin', 'principal')
    )
  );

CREATE POLICY teacher_assignments_update_school ON teacher_assignments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = teacher_assignments.school_id
      AND users.role IN ('admin', 'principal')
    )
  );

-- Schedule conflicts policies
CREATE POLICY schedule_conflicts_select_school ON schedule_conflicts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = schedule_conflicts.school_id
    )
  );

CREATE POLICY schedule_conflicts_insert_school ON schedule_conflicts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = schedule_conflicts.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY schedule_conflicts_update_school ON schedule_conflicts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = schedule_conflicts.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Function to detect schedule conflicts
CREATE OR REPLACE FUNCTION detect_schedule_conflicts(
  p_school_id UUID,
  p_timetable_id UUID DEFAULT NULL
)
RETURNS TABLE (
  conflict_type VARCHAR,
  entry_id UUID,
  conflicting_entry_id UUID,
  details JSONB
) AS $$
BEGIN
  -- Teacher conflicts (same teacher, same time, different classes)
  RETURN QUERY
  SELECT 
    'teacher_conflict'::VARCHAR,
    te1.id,
    te2.id,
    jsonb_build_object(
      'teacher_id', te1.teacher_id,
      'day_of_week', te1.day_of_week,
      'period_id', te1.period_id,
      'class1', t1.class_id,
      'class2', t2.class_id
    )
  FROM timetable_entries te1
  JOIN timetables t1 ON te1.timetable_id = t1.id
  JOIN timetable_entries te2 ON te2.teacher_id = te1.teacher_id
    AND te2.day_of_week = te1.day_of_week
    AND te2.period_id = te1.period_id
    AND te2.id != te1.id
  JOIN timetables t2 ON te2.timetable_id = t2.id
  WHERE te1.school_id = p_school_id
    AND te1.teacher_id IS NOT NULL
    AND (p_timetable_id IS NULL OR te1.timetable_id = p_timetable_id)
    AND t1.is_active = true
    AND t2.is_active = true;

  -- Room conflicts (same room, same time, different classes)
  RETURN QUERY
  SELECT 
    'room_conflict'::VARCHAR,
    te1.id,
    te2.id,
    jsonb_build_object(
      'room_id', te1.room_id,
      'day_of_week', te1.day_of_week,
      'period_id', te1.period_id,
      'class1', t1.class_id,
      'class2', t2.class_id
    )
  FROM timetable_entries te1
  JOIN timetables t1 ON te1.timetable_id = t1.id
  JOIN timetable_entries te2 ON te2.room_id = te1.room_id
    AND te2.day_of_week = te1.day_of_week
    AND te2.period_id = te1.period_id
    AND te2.id != te1.id
  JOIN timetables t2 ON te2.timetable_id = t2.id
  WHERE te1.school_id = p_school_id
    AND te1.room_id IS NOT NULL
    AND (p_timetable_id IS NULL OR te1.timetable_id = p_timetable_id)
    AND t1.is_active = true
    AND t2.is_active = true;
END;
$$ LANGUAGE plpgsql;

