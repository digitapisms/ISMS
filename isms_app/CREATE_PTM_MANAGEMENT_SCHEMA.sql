-- PTM (Parent-Teacher Meeting) Management Schema
-- Handles scheduling, notes, and follow-ups

-- PTM Meetings Table
CREATE TABLE IF NOT EXISTS ptm_meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES users(id), -- Parent user ID
    teacher_id UUID NOT NULL REFERENCES users(id),
    meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    meeting_type VARCHAR(50) NOT NULL DEFAULT 'scheduled', -- scheduled, walk_in, emergency
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- scheduled, confirmed, in_progress, completed, cancelled, no_show
    location VARCHAR(255), -- Room number, office, etc.
    agenda TEXT, -- Meeting agenda items
    scheduled_by UUID NOT NULL REFERENCES users(id),
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- PTM Notes Table
CREATE TABLE IF NOT EXISTS ptm_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID NOT NULL REFERENCES ptm_meetings(id) ON DELETE CASCADE,
    note_type VARCHAR(50) NOT NULL DEFAULT 'general', -- general, academic, behavior, attendance, etc.
    content TEXT NOT NULL,
    action_items TEXT[], -- Array of action items
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- PTM Follow-ups Table
CREATE TABLE IF NOT EXISTS ptm_follow_ups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID NOT NULL REFERENCES ptm_meetings(id) ON DELETE CASCADE,
    note_id UUID REFERENCES ptm_notes(id),
    follow_up_type VARCHAR(50) NOT NULL, -- action_item, reminder, check_in
    description TEXT NOT NULL,
    due_date DATE,
    assigned_to UUID REFERENCES users(id), -- Teacher, parent, or student
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, cancelled
    completed_at TIMESTAMP WITH TIME ZONE,
    completed_by UUID REFERENCES users(id),
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- PTM Availability Slots (for teachers to set available times)
CREATE TABLE IF NOT EXISTS ptm_availability_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id),
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    is_recurring BOOLEAN DEFAULT FALSE, -- Weekly recurring slot
    recurrence_pattern VARCHAR(50), -- weekly, biweekly, etc.
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ptm_meetings_school ON ptm_meetings(school_id);
CREATE INDEX IF NOT EXISTS idx_ptm_meetings_student ON ptm_meetings(student_id);
CREATE INDEX IF NOT EXISTS idx_ptm_meetings_parent ON ptm_meetings(parent_id);
CREATE INDEX IF NOT EXISTS idx_ptm_meetings_teacher ON ptm_meetings(teacher_id);
CREATE INDEX IF NOT EXISTS idx_ptm_meetings_date ON ptm_meetings(meeting_date);
CREATE INDEX IF NOT EXISTS idx_ptm_notes_meeting ON ptm_notes(meeting_id);
CREATE INDEX IF NOT EXISTS idx_ptm_follow_ups_meeting ON ptm_follow_ups(meeting_id);
CREATE INDEX IF NOT EXISTS idx_ptm_availability_teacher ON ptm_availability_slots(teacher_id);
CREATE INDEX IF NOT EXISTS idx_ptm_availability_date ON ptm_availability_slots(slot_date);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_ptm_meetings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ptm_meetings_updated_at
    BEFORE UPDATE ON ptm_meetings
    FOR EACH ROW
    EXECUTE FUNCTION update_ptm_meetings_updated_at();

CREATE OR REPLACE FUNCTION update_ptm_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ptm_notes_updated_at
    BEFORE UPDATE ON ptm_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_ptm_notes_updated_at();

CREATE OR REPLACE FUNCTION update_ptm_follow_ups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ptm_follow_ups_updated_at
    BEFORE UPDATE ON ptm_follow_ups
    FOR EACH ROW
    EXECUTE FUNCTION update_ptm_follow_ups_updated_at();

CREATE OR REPLACE FUNCTION update_ptm_availability_slots_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ptm_availability_slots_updated_at
    BEFORE UPDATE ON ptm_availability_slots
    FOR EACH ROW
    EXECUTE FUNCTION update_ptm_availability_slots_updated_at();

-- RLS Policies
ALTER TABLE ptm_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_follow_ups ENABLE ROW LEVEL SECURITY;
ALTER TABLE ptm_availability_slots ENABLE ROW LEVEL SECURITY;

-- Policies for ptm_meetings
CREATE POLICY ptm_meetings_select_school ON ptm_meetings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = ptm_meetings.school_id
            AND (
                ptm_meetings.parent_id = users.id
                OR ptm_meetings.teacher_id = users.id
                OR users.role IN ('admin', 'principal')
            )
        )
    );

CREATE POLICY ptm_meetings_insert_school ON ptm_meetings
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = ptm_meetings.school_id
            AND users.role IN ('admin', 'principal', 'teacher', 'parent')
        )
    );

CREATE POLICY ptm_meetings_update_school ON ptm_meetings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = ptm_meetings.school_id
            AND (
                ptm_meetings.parent_id = users.id
                OR ptm_meetings.teacher_id = users.id
                OR users.role IN ('admin', 'principal')
            )
        )
    );

CREATE POLICY ptm_meetings_delete_school ON ptm_meetings
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = ptm_meetings.school_id
            AND users.role IN ('admin', 'principal')
        )
    );

-- Similar policies for other PTM tables...
CREATE POLICY ptm_notes_select_school ON ptm_notes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM ptm_meetings pm
            JOIN users u ON u.school_id = pm.school_id
            WHERE u.auth_id = auth.uid()
            AND pm.id = ptm_notes.meeting_id
        )
    );

CREATE POLICY ptm_follow_ups_select_school ON ptm_follow_ups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM ptm_meetings pm
            JOIN users u ON u.school_id = pm.school_id
            WHERE u.auth_id = auth.uid()
            AND pm.id = ptm_follow_ups.meeting_id
        )
    );

