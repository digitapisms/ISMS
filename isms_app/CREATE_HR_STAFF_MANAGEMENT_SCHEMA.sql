-- =============================================================
-- HR & STAFF MANAGEMENT SCHEMA FOR ISMS/ILMA CLOUD PORTAL
-- Supports multiple educational institution types: School, Madarsa, Coaching Center, Tuition Center
-- Multi-branch support under one super-admin
-- =============================================================

-- =============================================================
-- 1. STAFF PROFILES (Extended user information for staff members)
-- =============================================================
CREATE TABLE IF NOT EXISTS staff_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Personal Information
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  gender VARCHAR(20), -- male, female, other
  cnic_number VARCHAR(15) UNIQUE, -- Pakistan CNIC format
  marital_status VARCHAR(20), -- single, married, divorced, widowed
  
  -- Contact Information
  personal_email VARCHAR(255),
  personal_phone VARCHAR(20),
  emergency_contact_name VARCHAR(255),
  emergency_contact_phone VARCHAR(20),
  emergency_contact_relation VARCHAR(50),
  
  -- Address Information
  permanent_address TEXT,
  current_address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100) DEFAULT 'Pakistan',
  postal_code VARCHAR(20),
  
  -- Employment Details
  employment_type VARCHAR(50) NOT NULL, -- full_time, part_time, contract, temporary
  employment_status VARCHAR(50) DEFAULT 'active', -- active, on_leave, suspended, terminated
  joining_date DATE NOT NULL,
  contract_start_date DATE,
  contract_end_date DATE,
  probation_period_days INTEGER DEFAULT 90,
  
  -- Institution-Specific Details
  teaching_type VARCHAR(100), -- For Madarsa: Quran, Hadith, Fiqh, Arabic, etc.
  course_type VARCHAR(100), -- For Coaching/Tuition Centers: Subject specialization
  qualification VARCHAR(255), -- Highest qualification
  specialization VARCHAR(255), -- Area of specialization
  experience_years INTEGER, -- Total years of experience
  
  -- Financial Information
  monthly_salary DECIMAL(18,2),
  hourly_rate DECIMAL(10,2),
  bank_account_number VARCHAR(50),
  bank_name VARCHAR(100),
  bank_branch VARCHAR(100),
  
  -- Administrative
  employee_id VARCHAR(50) UNIQUE, -- Institution-specific employee ID
  designation VARCHAR(100) NOT NULL,
  department VARCHAR(100),
  reporting_to UUID REFERENCES users(id), -- Manager/Supervisor
  branch_id UUID REFERENCES schools(id), -- For multi-branch support
  
  -- Documents & Media
  profile_picture_url TEXT,
  resume_url TEXT,
  qualification_documents JSONB DEFAULT '[]', -- Array of document URLs
  
  -- System Metadata
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(school_id, user_id),
  UNIQUE(school_id, employee_id)
);

-- =============================================================
-- 2. STAFF ATTENDANCE SYSTEM
-- =============================================================
CREATE TABLE IF NOT EXISTS staff_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Attendance Details
  attendance_date DATE NOT NULL,
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  
  -- Status & Tracking
  status VARCHAR(50) DEFAULT 'present', -- present, absent, late, half_day, leave
  session_identifier VARCHAR(100), -- Morning, Evening, Specific session
  shift_type VARCHAR(50), -- Regular, Overtime, Special
  
  -- Calculated Fields
  total_hours DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN check_in_time IS NOT NULL AND check_out_time IS NOT NULL 
      THEN EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 3600
      ELSE 0
    END
  ) STORED,
  
  -- Location Tracking (optional)
  check_in_latitude DECIMAL(10,8),
  check_in_longitude DECIMAL(11,8),
  check_out_latitude DECIMAL(10,8),
  check_out_longitude DECIMAL(11,8),
  
  -- Verification
  check_in_method VARCHAR(50), -- mobile_app, web_portal, biometric, manual
  check_out_method VARCHAR(50),
  verified_by UUID REFERENCES users(id),
  
  -- Notes & Adjustments
  notes TEXT,
  adjustment_reason TEXT, -- For manual adjustments
  
  -- System Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(school_id, staff_id, attendance_date)
);

-- =============================================================
-- 3. LEAVE MANAGEMENT SYSTEM
-- =============================================================
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Leave Details
  leave_type VARCHAR(50) NOT NULL, -- casual, sick, annual, maternity, paternity, emergency
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  reason TEXT NOT NULL,
  
  -- Status & Approval
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, cancelled
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Emergency Contact during leave
  emergency_contact_during_leave VARCHAR(20),
  handover_notes TEXT,
  
  -- Supporting Documents
  supporting_documents JSONB DEFAULT '[]', -- Array of document URLs
  
  -- System Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 4. SALARY STRUCTURES & COMPENSATION
-- =============================================================
CREATE TABLE IF NOT EXISTS salary_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  
  -- Structure Details
  role VARCHAR(100) NOT NULL, -- teacher, admin, principal, etc.
  employment_type VARCHAR(50) NOT NULL, -- full_time, part_time, contract
  
  -- Compensation Components
  base_salary DECIMAL(18,2) NOT NULL,
  hourly_rate DECIMAL(10,2),
  
  -- Allowances
  house_rent_allowance DECIMAL(18,2) DEFAULT 0,
  medical_allowance DECIMAL(18,2) DEFAULT 0,
  conveyance_allowance DECIMAL(18,2) DEFAULT 0,
  special_allowance DECIMAL(18,2) DEFAULT 0,
  
  -- Deductions
  income_tax DECIMAL(18,2) DEFAULT 0,
  provident_fund DECIMAL(18,2) DEFAULT 0,
  other_deductions DECIMAL(18,2) DEFAULT 0,
  
  -- Overtime & Bonuses
  overtime_rate DECIMAL(10,2) DEFAULT 0,
  bonus_percentage DECIMAL(5,2) DEFAULT 0,
  
  -- Pay Cycle
  pay_cycle VARCHAR(50) DEFAULT 'monthly', -- monthly, biweekly, weekly
  effective_date DATE NOT NULL,
  
  -- Institution-Specific
  teaching_type VARCHAR(100), -- For Madarsa-specific structures
  course_type VARCHAR(100), -- For Coaching Center-specific structures
  
  -- System Metadata
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(school_id, role, employment_type, teaching_type, course_type, effective_date)
);

-- =============================================================
-- 5. PAYROLL RECORDS
-- =============================================================
CREATE TABLE IF NOT EXISTS payroll_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Payroll Period
  payroll_month VARCHAR(7) NOT NULL, -- YYYY-MM format
  period_start_date DATE NOT NULL,
  period_end_date DATE NOT NULL,
  
  -- Salary Components
  basic_salary DECIMAL(18,2) NOT NULL,
  total_allowances DECIMAL(18,2) DEFAULT 0,
  total_deductions DECIMAL(18,2) DEFAULT 0,
  overtime_hours DECIMAL(5,2) DEFAULT 0,
  overtime_amount DECIMAL(18,2) DEFAULT 0,
  bonus_amount DECIMAL(18,2) DEFAULT 0,
  
  -- Final Calculations
  gross_salary DECIMAL(18,2) NOT NULL,
  net_salary DECIMAL(18,2) NOT NULL,
  
  -- Payment Details
  pay_date DATE,
  status VARCHAR(50) DEFAULT 'pending', -- pending, processed, paid, failed
  payment_method VARCHAR(50), -- bank_transfer, cash, easypaisa, jazzcash
  payment_reference VARCHAR(255),
  
  -- Attendance & Leave Impact
  days_present INTEGER,
  days_absent INTEGER,
  leaves_taken INTEGER,
  
  -- System Metadata
  generated_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(school_id, staff_id, payroll_month)
);

-- =============================================================
-- 6. PAYSLIPS & DOCUMENTS
-- =============================================================
CREATE TABLE IF NOT EXISTS payslips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  payroll_record_id UUID NOT NULL REFERENCES payroll_records(id) ON DELETE CASCADE,
  
  -- Document Information
  payslip_url TEXT, -- URL to generated PDF
  file_name VARCHAR(255),
  file_size BIGINT,
  
  -- Security
  access_code VARCHAR(100), -- For secure access
  is_emailed BOOLEAN DEFAULT false,
  emailed_at TIMESTAMPTZ,
  
  -- System Metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

-- =============================================================
-- 7. PERFORMANCE TRACKING SYSTEM
-- =============================================================
CREATE TABLE IF NOT EXISTS performance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Evaluation Period
  evaluation_period VARCHAR(7) NOT NULL, -- YYYY-MM format
  period_start_date DATE,
  period_end_date DATE,
  
  -- Performance Metrics
  classroom_hours DECIMAL(5,2) DEFAULT 0,
  student_feedback_score DECIMAL(3,2), -- 1.00 to 5.00 scale
  attendance_rate DECIMAL(5,2), -- Percentage
  completion_rate DECIMAL(5,2), -- For course completion
  
  -- Qualitative Assessment
  strengths TEXT,
  areas_for_improvement TEXT,
  goals_achieved TEXT,
  next_period_goals TEXT,
  
  -- Rating & Approval
  overall_rating DECIMAL(3,2), -- 1.00 to 5.00 scale
  evaluated_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  evaluation_date DATE,
  
  -- Supporting Evidence
  supporting_documents JSONB DEFAULT '[]',
  student_feedback_comments TEXT,
  
  -- System Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================
-- 8. BRANCH/INSTITUTE MANAGEMENT (Extended from schools table)
-- =============================================================
CREATE TABLE IF NOT EXISTS branch_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  
  -- Branch Specific Information
  branch_type VARCHAR(50) NOT NULL, -- school, madarsa, coaching_center, tuition_center
  branch_name VARCHAR(255) NOT NULL,
  branch_code VARCHAR(50) UNIQUE,
  
  -- Location & Contact
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100) DEFAULT 'Pakistan',
  phone VARCHAR(20),
  email VARCHAR(255),
  
  -- Operational Details
  timezone VARCHAR(50) DEFAULT 'Asia/Karachi',
  working_hours JSONB, -- {\"start\": \"08:00\", \"end\": \"16:00\"}
  
  -- Management
  reporting_head UUID REFERENCES users(id), -- Branch head/manager
  established_date DATE,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- System Metadata
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(school_id, branch_name)
);

-- =============================================================
-- INDEXES FOR OPTIMAL PERFORMANCE
-- =============================================================

-- Staff Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_staff_profiles_school ON staff_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_user ON staff_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_employee_id ON staff_profiles(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_department ON staff_profiles(department);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_status ON staff_profiles(employment_status);

-- Attendance Indexes
CREATE INDEX IF NOT EXISTS idx_staff_attendance_school ON staff_attendance(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_staff ON staff_attendance(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_date ON staff_attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_status ON staff_attendance(status);

-- Leave Requests Indexes
CREATE INDEX IF NOT EXISTS idx_leave_requests_school ON leave_requests(school_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_staff ON leave_requests(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_date_range ON leave_requests(start_date, end_date);

-- Salary Structures Indexes
CREATE INDEX IF NOT EXISTS idx_salary_structures_school ON salary_structures(school_id);
CREATE INDEX IF NOT EXISTS idx_salary_structures_role ON salary_structures(role);
CREATE INDEX IF NOT EXISTS idx_salary_structures_active ON salary_structures(is_active) WHERE is_active = true;

-- Payroll Records Indexes
CREATE INDEX IF NOT EXISTS idx_payroll_records_school ON payroll_records(school_id);
CREATE INDEX IF NOT EXISTS idx_payroll_records_staff ON payroll_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_payroll_records_month ON payroll_records(payroll_month);
CREATE INDEX IF NOT EXISTS idx_payroll_records_status ON payroll_records(status);

-- Performance Records Indexes
CREATE INDEX IF NOT EXISTS idx_performance_records_school ON performance_records(school_id);
CREATE INDEX IF NOT EXISTS idx_performance_records_staff ON performance_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_performance_records_period ON performance_records(evaluation_period);

-- Branch Details Indexes
CREATE INDEX IF NOT EXISTS idx_branch_details_school ON branch_details(school_id);
CREATE INDEX IF NOT EXISTS idx_branch_details_type ON branch_details(branch_type);
CREATE INDEX IF NOT EXISTS idx_branch_details_active ON branch_details(is_active) WHERE is_active = true;

-- =============================================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================================

-- Staff Profiles RLS
ALTER TABLE staff_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY staff_profiles_select_same_school ON staff_profiles
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY staff_profiles_manage_admin ON staff_profiles
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Staff Attendance RLS
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY staff_attendance_select_same_school ON staff_attendance
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY staff_attendance_manage_admin ON staff_attendance
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Leave Requests RLS
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY leave_requests_select_own ON leave_requests
  FOR SELECT USING (
    staff_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY leave_requests_select_same_school ON leave_requests
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY leave_requests_manage_admin ON leave_requests
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Salary Structures RLS
ALTER TABLE salary_structures ENABLE ROW LEVEL SECURITY;

CREATE POLICY salary_structures_select_same_school ON salary_structures
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY salary_structures_manage_admin ON salary_structures
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Payroll Records RLS
ALTER TABLE payroll_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY payroll_records_select_own ON payroll_records
  FOR SELECT USING (
    staff_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY payroll_records_select_same_school ON payroll_records
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY payroll_records_manage_admin ON payroll_records
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Performance Records RLS
ALTER TABLE performance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY performance_records_select_own ON performance_records
  FOR SELECT USING (
    staff_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY performance_records_select_same_school ON performance_records
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY performance_records_manage_admin ON performance_records
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- Branch Details RLS
ALTER TABLE branch_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY branch_details_select_same_school ON branch_details
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY branch_details_manage_admin ON branch_details
  FOR ALL USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE auth_id = auth.uid() 
      AND role IN ('admin', 'principal', 'super_admin')
    )
  );

-- =============================================================
-- UPDATE TRIGGERS
-- =============================================================

-- Create update_updated_at_column function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Staff Profiles Trigger
DROP TRIGGER IF EXISTS update_staff_profiles_updated_at ON staff_profiles;
CREATE TRIGGER update_staff_profiles_updated_at
  BEFORE UPDATE ON staff_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Staff Attendance Trigger
DROP TRIGGER IF EXISTS update_staff_attendance_updated_at ON staff_attendance;
CREATE TRIGGER update_staff_attendance_updated_at
  BEFORE UPDATE ON staff_attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Leave Requests Trigger
DROP TRIGGER IF EXISTS update_leave_requests_updated_at ON leave_requests;
CREATE TRIGGER update_leave_requests_updated_at
  BEFORE UPDATE ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Salary Structures Trigger
DROP TRIGGER IF EXISTS update_salary_structures_updated_at ON salary_structures;
CREATE TRIGGER update_salary_structures_updated_at
  BEFORE UPDATE ON salary_structures
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Payroll Records Trigger
DROP TRIGGER IF EXISTS update_payroll_records_updated_at ON payroll_records;
CREATE TRIGGER update_payroll_records_updated_at
  BEFORE UPDATE ON payroll_records
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Performance Records Trigger
DROP TRIGGER IF EXISTS update_performance_records_updated_at ON performance_records;
CREATE TRIGGER update_performance_records_updated_at
  BEFORE UPDATE ON performance_records
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Branch Details Trigger
DROP TRIGGER IF EXISTS update_branch_details_updated_at ON branch_details;
CREATE TRIGGER update_branch_details_updated_at
  BEFORE UPDATE ON branch_details
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- 9. STUDENT LEAVE REQUESTS (For Parent/Student Portal)
-- =============================================================
CREATE TABLE IF NOT EXISTS student_leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  
  -- Leave Details
  leave_type VARCHAR(50) NOT NULL, -- sick, family_event, medical, personal, emergency
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  reason TEXT NOT NULL,
  
  -- Parent/Guardian Information
  requested_by UUID REFERENCES users(id), -- Parent/guardian who requested
  requested_by_role VARCHAR(50), -- parent, guardian, student (for older students)
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Status & Approval
  status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, cancelled
  approved_by UUID REFERENCES users(id), -- Teacher/principal who approved
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Supporting Documents
  supporting_documents JSONB DEFAULT '[]', -- Array of document URLs
  
  -- Emergency Contact during leave
  emergency_contact_during_leave VARCHAR(20),
  
  -- Class Information for filtering
  class_id INT REFERENCES classes(id),
  section_id INT REFERENCES sections(id),
  
  -- System Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CHECK (end_date >= start_date),
  CHECK (total_days > 0)
);

-- Indexes for student leave requests
CREATE INDEX IF NOT EXISTS idx_student_leave_school ON student_leave_requests(school_id);
CREATE INDEX IF NOT EXISTS idx_student_leave_student ON student_leave_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_student_leave_status ON student_leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_student_leave_dates ON student_leave_requests(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_student_leave_class ON student_leave_requests(class_id, section_id);

-- RLS Policies for student_leave_requests
ALTER TABLE student_leave_requests ENABLE ROW LEVEL SECURITY;

-- Students can view their own leave requests
CREATE POLICY student_leave_select_own ON student_leave_requests
  FOR SELECT USING (
    student_id IN (
      SELECT id FROM students 
      WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    )
    OR
    requested_by = (SELECT id FROM users WHERE auth_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM users
      WHERE auth_id = auth.uid()
      AND school_id = student_leave_requests.school_id
      AND role IN ('admin', 'principal', 'teacher')
    )
  );

-- Parents can insert leave requests for their children
CREATE POLICY student_leave_insert_parent ON student_leave_requests
  FOR INSERT WITH CHECK (
    requested_by = (SELECT id FROM users WHERE auth_id = auth.uid())
    AND requested_by_role IN ('parent', 'guardian')
    AND EXISTS (
      SELECT 1 FROM parent_student_mapping
      WHERE parent_id = (SELECT id FROM users WHERE auth_id = auth.uid())
      AND student_id = student_leave_requests.student_id
    )
  );

-- Teachers/admins can update leave requests (approve/reject)
CREATE POLICY student_leave_update_staff ON student_leave_requests
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE auth_id = auth.uid()
      AND school_id = student_leave_requests.school_id
      AND role IN ('admin', 'principal', 'teacher')
    )
  );

-- Update trigger
CREATE TRIGGER update_student_leave_updated_at
  BEFORE UPDATE ON student_leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- 10. ENHANCED ATTENDANCE SUMMARY VIEWS
-- =============================================================

-- Monthly Attendance Summary View
CREATE OR REPLACE VIEW attendance_monthly_summary AS
SELECT 
  school_id,
  student_id,
  DATE_TRUNC('month', attendance_date) AS month,
  COUNT(*) FILTER (WHERE status = 'present') AS present_days,
  COUNT(*) FILTER (WHERE status = 'absent') AS absent_days,
  COUNT(*) FILTER (WHERE status = 'late') AS late_days,
  COUNT(*) FILTER (WHERE status = 'excused') AS excused_days,
  COUNT(*) FILTER (WHERE status = 'half_day') AS half_days,
  COUNT(*) AS total_days
FROM attendance_records
GROUP BY school_id, student_id, DATE_TRUNC('month', attendance_date);

-- Student Leave Balance View
CREATE OR REPLACE VIEW student_leave_balance AS
SELECT 
  slr.student_id,
  slr.school_id,
  EXTRACT(YEAR FROM slr.start_date) AS academic_year,
  COUNT(*) FILTER (WHERE slr.status = 'approved') AS approved_leaves,
  COUNT(*) FILTER (WHERE slr.leave_type = 'sick') AS sick_leaves,
  COUNT(*) FILTER (WHERE slr.leave_type = 'family_event') AS family_event_leaves
FROM student_leave_requests slr
GROUP BY slr.student_id, slr.school_id, EXTRACT(YEAR FROM slr.start_date);

-- =============================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================

COMMENT ON TABLE staff_profiles IS 'Extended staff information for HR management across multiple institution types';
COMMENT ON TABLE staff_attendance IS 'Staff attendance tracking with check-in/check-out system';
COMMENT ON TABLE leave_requests IS 'Staff leave management and approval system';
COMMENT ON TABLE student_leave_requests IS 'Student leave requests from parent/student portal with approval workflow';
COMMENT ON TABLE salary_structures IS 'Salary templates for different roles and institution types';
COMMENT ON TABLE payroll_records IS 'Monthly payroll processing and records';
COMMENT ON TABLE payslips IS 'Generated payslip documents storage';
COMMENT ON TABLE performance_records IS 'Staff performance evaluation and tracking';
COMMENT ON TABLE branch_details IS 'Multi-branch management for educational institutions';
COMMENT ON VIEW attendance_monthly_summary IS 'Monthly attendance summary for students and reporting';
COMMENT ON VIEW student_leave_balance IS 'Student leave balance and usage statistics';

-- =============================================================
-- SCHEMA COMPLETE
-- =============================================================