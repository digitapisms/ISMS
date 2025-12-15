-- Homework/Assignment Management System Schema
-- Supports comprehensive assignment creation, submission, and grading

-- ============================================================
-- ASSIGNMENTS TABLE (Main assignment records)
-- ============================================================
CREATE TABLE IF NOT EXISTS assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  assignment_type VARCHAR(50) DEFAULT 'homework', -- homework, project, worksheet, quiz, essay
  subject_id INTEGER REFERENCES subjects(id) ON DELETE SET NULL,
  class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE SET NULL,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(50), -- first_term, second_term, third_term, annual
  due_date TIMESTAMPTZ NOT NULL,
  max_points DECIMAL(10,2) DEFAULT 100.0,
  weightage DECIMAL(5,2), -- Percentage weight in overall grade
  instructions TEXT,
  rubric JSONB, -- Grading rubric structure
  allow_late_submission BOOLEAN DEFAULT true,
  late_penalty_per_day DECIMAL(5,2) DEFAULT 0, -- Percentage penalty per day
  allow_resubmission BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ASSIGNMENT ATTACHMENTS TABLE (Files/documents)
-- ============================================================
CREATE TABLE IF NOT EXISTS assignment_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  file_type VARCHAR(100),
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ASSIGNMENT SUBMISSIONS TABLE (Student submissions)
-- ============================================================
CREATE TABLE IF NOT EXISTS assignment_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  submission_text TEXT,
  submission_status VARCHAR(50) DEFAULT 'not_started', -- not_started, in_progress, submitted, late, graded
  submitted_at TIMESTAMPTZ,
  is_late BOOLEAN DEFAULT false,
  days_late INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(assignment_id, student_id)
);

-- ============================================================
-- SUBMISSION ATTACHMENTS TABLE (Student submission files)
-- ============================================================
CREATE TABLE IF NOT EXISTS submission_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  submission_id UUID NOT NULL REFERENCES assignment_submissions(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  file_type VARCHAR(100),
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ASSIGNMENT GRADES TABLE (Grading records)
-- ============================================================
CREATE TABLE IF NOT EXISTS assignment_grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  submission_id UUID NOT NULL REFERENCES assignment_submissions(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points_obtained DECIMAL(10,2),
  max_points DECIMAL(10,2),
  percentage DECIMAL(5,2),
  grade VARCHAR(10), -- A+, A, B+, B, C+, C, D, F
  grade_point DECIMAL(3,2),
  teacher_feedback TEXT,
  rubric_scores JSONB, -- Scores for each rubric criterion
  graded_by UUID REFERENCES users(id),
  graded_at TIMESTAMPTZ,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(submission_id)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_assignments_school_id ON assignments(school_id);
CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_id ON assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments(due_date);
CREATE INDEX IF NOT EXISTS idx_assignments_subject_id ON assignments(subject_id);
CREATE INDEX IF NOT EXISTS idx_assignment_attachments_assignment_id ON assignment_attachments(assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_student_id ON assignment_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submission_attachments_submission_id ON submission_attachments(submission_id);
CREATE INDEX IF NOT EXISTS idx_assignment_grades_submission_id ON assignment_grades(submission_id);
CREATE INDEX IF NOT EXISTS idx_assignment_grades_student_id ON assignment_grades(student_id);
CREATE INDEX IF NOT EXISTS idx_assignment_grades_assignment_id ON assignment_grades(assignment_id);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_assignments_updated_at BEFORE UPDATE ON assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignment_submissions_updated_at BEFORE UPDATE ON assignment_submissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignment_grades_updated_at BEFORE UPDATE ON assignment_grades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- RLS POLICIES
-- ============================================================
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE submission_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_grades ENABLE ROW LEVEL SECURITY;

-- Assignments policies
CREATE POLICY assignments_select_school ON assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignments.school_id
    )
  );

CREATE POLICY assignments_insert_school ON assignments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignments.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY assignments_update_school ON assignments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignments.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Assignment attachments policies
CREATE POLICY assignment_attachments_select_school ON assignment_attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_attachments.school_id
    )
  );

CREATE POLICY assignment_attachments_insert_school ON assignment_attachments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_attachments.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

-- Assignment submissions policies
CREATE POLICY assignment_submissions_select_school ON assignment_submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_submissions.school_id
    )
  );

CREATE POLICY assignment_submissions_insert_school ON assignment_submissions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_submissions.school_id
      AND (users.role = 'student' OR users.role IN ('admin', 'principal', 'teacher'))
    )
  );

CREATE POLICY assignment_submissions_update_school ON assignment_submissions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_submissions.school_id
      AND (users.role = 'student' OR users.role IN ('admin', 'principal', 'teacher'))
    )
  );

-- Submission attachments policies
CREATE POLICY submission_attachments_select_school ON submission_attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = submission_attachments.school_id
    )
  );

CREATE POLICY submission_attachments_insert_school ON submission_attachments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = submission_attachments.school_id
      AND (users.role = 'student' OR users.role IN ('admin', 'principal', 'teacher'))
    )
  );

-- Assignment grades policies
CREATE POLICY assignment_grades_select_school ON assignment_grades
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_grades.school_id
    )
  );

CREATE POLICY assignment_grades_insert_school ON assignment_grades
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_grades.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

CREATE POLICY assignment_grades_update_school ON assignment_grades
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.auth_id = auth.uid()
      AND users.school_id = assignment_grades.school_id
      AND users.role IN ('admin', 'principal', 'teacher')
    )
  );

