-- Examination & Assessment System Schema
-- Supports Pakistani school requirements with comprehensive exam management

-- ============================================================
-- SUBJECTS TABLE (if not exists)
-- ============================================================
CREATE TABLE IF NOT EXISTS subjects (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, code)
);

-- ============================================================
-- EXAMS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  exam_type VARCHAR(50) NOT NULL, -- mid_term, final, quiz, assignment, project, test
  academic_year VARCHAR(20), -- e.g., "2024-2025"
  term VARCHAR(50), -- first_term, second_term, third_term, annual
  start_date DATE,
  end_date DATE,
  total_marks DECIMAL(10,2) DEFAULT 100.00,
  passing_marks DECIMAL(10,2),
  description TEXT,
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EXAM SCHEDULES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  exam_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  duration_minutes INTEGER,
  venue VARCHAR(255), -- Room/hall name
  instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EXAM GRADES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  exam_schedule_id UUID REFERENCES exam_schedules(id) ON DELETE SET NULL,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  marks_obtained DECIMAL(10,2) NOT NULL,
  total_marks DECIMAL(10,2) NOT NULL,
  percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN total_marks > 0 THEN (marks_obtained / total_marks * 100)
      ELSE 0
    END
  ) STORED,
  grade VARCHAR(10), -- A+, A, B+, B, C+, C, D, F
  grade_point DECIMAL(3,2), -- 4.0, 3.5, etc.
  remarks TEXT,
  is_absent BOOLEAN DEFAULT false,
  is_exempted BOOLEAN DEFAULT false,
  entered_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(exam_id, student_id, subject_id)
);

-- ============================================================
-- GRADE BOOKS TABLE (Consolidated grades per term/academic year)
-- ============================================================
CREATE TABLE IF NOT EXISTS grade_books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50), -- first_term, second_term, third_term, annual
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  total_marks DECIMAL(10,2),
  marks_obtained DECIMAL(10,2),
  percentage DECIMAL(5,2),
  grade VARCHAR(10),
  grade_point DECIMAL(3,2),
  position INTEGER, -- Class position
  total_students INTEGER, -- Total students in class for position calculation
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, academic_year, term, subject_id)
);

-- ============================================================
-- REPORT CARDS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS report_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50) NOT NULL,
  total_subjects INTEGER DEFAULT 0,
  total_marks DECIMAL(10,2),
  marks_obtained DECIMAL(10,2),
  overall_percentage DECIMAL(5,2),
  overall_grade VARCHAR(10),
  overall_grade_point DECIMAL(3,2),
  class_position INTEGER,
  total_students INTEGER,
  division VARCHAR(20), -- First Division, Second Division, Third Division
  attendance_percentage DECIMAL(5,2),
  teacher_remarks TEXT,
  principal_remarks TEXT,
  parent_signature_required BOOLEAN DEFAULT true,
  parent_signed_at TIMESTAMPTZ,
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, archived
  generated_by UUID REFERENCES users(id),
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, academic_year, term)
);

-- ============================================================
-- REPORT CARD SUBJECTS TABLE (Subject-wise grades in report card)
-- ============================================================
CREATE TABLE IF NOT EXISTS report_card_subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  report_card_id UUID NOT NULL REFERENCES report_cards(id) ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  subject_name VARCHAR(255),
  marks_obtained DECIMAL(10,2),
  total_marks DECIMAL(10,2),
  percentage DECIMAL(5,2),
  grade VARCHAR(10),
  grade_point DECIMAL(3,2),
  position INTEGER,
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- GRADE TEMPLATES TABLE (Report card templates)
-- ============================================================
CREATE TABLE IF NOT EXISTS grade_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  template_type VARCHAR(50) DEFAULT 'report_card', -- report_card, transcript
  layout_config JSONB, -- Template layout configuration
  header_html TEXT,
  footer_html TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_exams_school_id ON exams(school_id);
CREATE INDEX IF NOT EXISTS idx_exams_academic_year ON exams(academic_year);
CREATE INDEX IF NOT EXISTS idx_exams_status ON exams(status);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_exam_id ON exam_schedules(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_class_id ON exam_schedules(class_id);
CREATE INDEX IF NOT EXISTS idx_exam_schedules_exam_date ON exam_schedules(exam_date);
CREATE INDEX IF NOT EXISTS idx_exam_grades_exam_id ON exam_grades(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_grades_student_id ON exam_grades(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_grades_subject_id ON exam_grades(subject_id);
CREATE INDEX IF NOT EXISTS idx_grade_books_student_id ON grade_books(student_id);
CREATE INDEX IF NOT EXISTS idx_grade_books_academic_year ON grade_books(academic_year);
CREATE INDEX IF NOT EXISTS idx_report_cards_student_id ON report_cards(student_id);
CREATE INDEX IF NOT EXISTS idx_report_cards_academic_year ON report_cards(academic_year);
CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects(school_id);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_schedules_updated_at BEFORE UPDATE ON exam_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_grades_updated_at BEFORE UPDATE ON exam_grades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grade_books_updated_at BEFORE UPDATE ON grade_books
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_cards_updated_at BEFORE UPDATE ON report_cards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grade_templates_updated_at BEFORE UPDATE ON grade_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- RLS POLICIES
-- ============================================================
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_templates ENABLE ROW LEVEL SECURITY;

-- Subjects policies
CREATE POLICY subjects_select_school ON subjects
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = subjects.school_id
    )
  );

CREATE POLICY subjects_insert_school ON subjects
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = subjects.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY subjects_update_school ON subjects
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = subjects.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Exams policies
CREATE POLICY exams_select_school ON exams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exams.school_id
    )
  );

CREATE POLICY exams_insert_school ON exams
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exams.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY exams_update_school ON exams
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exams.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Exam schedules policies
CREATE POLICY exam_schedules_select_school ON exam_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_schedules.school_id
    )
  );

CREATE POLICY exam_schedules_insert_school ON exam_schedules
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_schedules.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY exam_schedules_update_school ON exam_schedules
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_schedules.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Exam grades policies
CREATE POLICY exam_grades_select_school ON exam_grades
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_grades.school_id
    )
  );

CREATE POLICY exam_grades_insert_school ON exam_grades
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_grades.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY exam_grades_update_school ON exam_grades
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = exam_grades.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Grade books policies
CREATE POLICY grade_books_select_school ON grade_books
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_books.school_id
    )
  );

CREATE POLICY grade_books_insert_school ON grade_books
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_books.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY grade_books_update_school ON grade_books
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_books.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Report cards policies
CREATE POLICY report_cards_select_school ON report_cards
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = report_cards.school_id
    )
  );

CREATE POLICY report_cards_insert_school ON report_cards
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = report_cards.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY report_cards_update_school ON report_cards
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = report_cards.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Report card subjects policies
CREATE POLICY report_card_subjects_select_school ON report_card_subjects
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = report_card_subjects.school_id
    )
  );

CREATE POLICY report_card_subjects_insert_school ON report_card_subjects
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = report_card_subjects.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Grade templates policies
CREATE POLICY grade_templates_select_school ON grade_templates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_templates.school_id
    )
  );

CREATE POLICY grade_templates_insert_school ON grade_templates
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_templates.school_id
      AND users.role IN ('admin', 'principal')
    )
  );

CREATE POLICY grade_templates_update_school ON grade_templates
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = grade_templates.school_id
      AND users.role IN ('admin', 'principal')
    )
  );

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Function to calculate grade from percentage (Pakistani system)
CREATE OR REPLACE FUNCTION calculate_grade(percentage DECIMAL)
RETURNS VARCHAR(10) AS $$
BEGIN
  RETURN CASE
    WHEN percentage >= 90 THEN 'A+'
    WHEN percentage >= 80 THEN 'A'
    WHEN percentage >= 70 THEN 'B+'
    WHEN percentage >= 60 THEN 'B'
    WHEN percentage >= 50 THEN 'C+'
    WHEN percentage >= 40 THEN 'C'
    WHEN percentage >= 33 THEN 'D'
    ELSE 'F'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate grade point
CREATE OR REPLACE FUNCTION calculate_grade_point(percentage DECIMAL)
RETURNS DECIMAL(3,2) AS $$
BEGIN
  RETURN CASE
    WHEN percentage >= 90 THEN 4.0
    WHEN percentage >= 80 THEN 3.5
    WHEN percentage >= 70 THEN 3.0
    WHEN percentage >= 60 THEN 2.5
    WHEN percentage >= 50 THEN 2.0
    WHEN percentage >= 40 THEN 1.5
    WHEN percentage >= 33 THEN 1.0
    ELSE 0.0
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate division
CREATE OR REPLACE FUNCTION calculate_division(percentage DECIMAL)
RETURNS VARCHAR(20) AS $$
BEGIN
  RETURN CASE
    WHEN percentage >= 60 THEN 'First Division'
    WHEN percentage >= 45 THEN 'Second Division'
    WHEN percentage >= 33 THEN 'Third Division'
    ELSE 'Fail'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update exam grade calculations
CREATE OR REPLACE FUNCTION update_exam_grade_calculations()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.total_marks > 0 AND NOT NEW.is_absent AND NOT NEW.is_exempted THEN
    NEW.percentage := (NEW.marks_obtained / NEW.total_marks * 100);
    NEW.grade := calculate_grade(NEW.percentage);
    NEW.grade_point := calculate_grade_point(NEW.percentage);
  ELSIF NEW.is_absent THEN
    NEW.percentage := 0;
    NEW.grade := 'Absent';
    NEW.grade_point := 0;
  ELSIF NEW.is_exempted THEN
    NEW.percentage := NULL;
    NEW.grade := 'Exempted';
    NEW.grade_point := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_exam_grade_calculations_trigger
  BEFORE INSERT OR UPDATE ON exam_grades
  FOR EACH ROW
  EXECUTE FUNCTION update_exam_grade_calculations();

