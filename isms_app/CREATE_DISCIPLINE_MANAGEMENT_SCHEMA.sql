-- Discipline Management System Schema
-- Tracks student behavior, incidents, and disciplinary actions

-- Discipline Incidents Table
CREATE TABLE IF NOT EXISTS discipline_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    incident_type VARCHAR(50) NOT NULL, -- minor, major, serious, critical
    category VARCHAR(100), -- bullying, cheating, vandalism, violence, etc.
    description TEXT NOT NULL,
    location VARCHAR(255),
    reported_by UUID REFERENCES users(id),
    witnesses TEXT[], -- Array of witness names/IDs
    evidence_urls TEXT[], -- Array of file URLs
    status VARCHAR(20) NOT NULL DEFAULT 'reported', -- reported, investigating, resolved, closed
    severity_level VARCHAR(20) NOT NULL DEFAULT 'low', -- low, medium, high, critical
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Discipline Actions Table
CREATE TABLE IF NOT EXISTS discipline_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    incident_id UUID NOT NULL REFERENCES discipline_incidents(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- warning, detention, suspension, expulsion, counseling, etc.
    action_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    description TEXT NOT NULL,
    duration_days INTEGER, -- For suspensions, etc.
    start_date DATE,
    end_date DATE,
    assigned_by UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, completed, cancelled
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Discipline History View (for quick access)
CREATE OR REPLACE VIEW discipline_history AS
SELECT 
    di.id,
    di.school_id,
    di.student_id,
    s.full_name as student_name,
    s.admission_no,
    di.incident_date,
    di.incident_type,
    di.category,
    di.description,
    di.status as incident_status,
    di.severity_level,
    COUNT(da.id) as action_count,
    MAX(da.action_date) as last_action_date
FROM discipline_incidents di
LEFT JOIN students s ON s.id = di.student_id
LEFT JOIN discipline_actions da ON da.incident_id = di.id
GROUP BY di.id, s.full_name, s.admission_no;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_discipline_incidents_school ON discipline_incidents(school_id);
CREATE INDEX IF NOT EXISTS idx_discipline_incidents_student ON discipline_incidents(student_id);
CREATE INDEX IF NOT EXISTS idx_discipline_incidents_date ON discipline_incidents(incident_date);
CREATE INDEX IF NOT EXISTS idx_discipline_actions_incident ON discipline_actions(incident_id);
CREATE INDEX IF NOT EXISTS idx_discipline_actions_student ON discipline_actions(student_id);
CREATE INDEX IF NOT EXISTS idx_discipline_actions_school ON discipline_actions(school_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_discipline_incidents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_discipline_incidents_updated_at
    BEFORE UPDATE ON discipline_incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_discipline_incidents_updated_at();

CREATE OR REPLACE FUNCTION update_discipline_actions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_discipline_actions_updated_at
    BEFORE UPDATE ON discipline_actions
    FOR EACH ROW
    EXECUTE FUNCTION update_discipline_actions_updated_at();

-- RLS Policies
ALTER TABLE discipline_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline_actions ENABLE ROW LEVEL SECURITY;

-- Policies for discipline_incidents
CREATE POLICY discipline_incidents_select_school ON discipline_incidents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_incidents.school_id
        )
    );

CREATE POLICY discipline_incidents_insert_school ON discipline_incidents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_incidents.school_id
            AND users.role IN ('admin', 'principal', 'teacher')
        )
    );

CREATE POLICY discipline_incidents_update_school ON discipline_incidents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_incidents.school_id
            AND users.role IN ('admin', 'principal', 'teacher')
        )
    );

CREATE POLICY discipline_incidents_delete_school ON discipline_incidents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_incidents.school_id
            AND users.role IN ('admin', 'principal')
        )
    );

-- Policies for discipline_actions
CREATE POLICY discipline_actions_select_school ON discipline_actions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_actions.school_id
        )
    );

CREATE POLICY discipline_actions_insert_school ON discipline_actions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_actions.school_id
            AND users.role IN ('admin', 'principal', 'teacher')
        )
    );

CREATE POLICY discipline_actions_update_school ON discipline_actions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_actions.school_id
            AND users.role IN ('admin', 'principal', 'teacher')
        )
    );

CREATE POLICY discipline_actions_delete_school ON discipline_actions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = discipline_actions.school_id
            AND users.role IN ('admin', 'principal')
        )
    );

