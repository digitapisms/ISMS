-- Communication & Messaging System Schema
-- Supports direct messaging, announcements, circulars, and templates

-- ============================================================
-- CONVERSATIONS TABLE (Chat conversations)
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  conversation_type VARCHAR(50) DEFAULT 'direct', -- direct, group, class, broadcast
  title VARCHAR(255), -- For group conversations
  created_by UUID NOT NULL REFERENCES users(id),
  is_active BOOLEAN DEFAULT true,
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CONVERSATION PARTICIPANTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'participant', -- participant, admin, moderator
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  UNIQUE(conversation_id, user_id)
);

-- ============================================================
-- MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_type VARCHAR(50) DEFAULT 'text', -- text, image, file, voice, video, location
  content TEXT,
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  is_forwarded BOOLEAN DEFAULT false,
  forwarded_from_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- MESSAGE ATTACHMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS message_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT,
  file_type VARCHAR(100),
  file_size BIGINT,
  mime_type VARCHAR(100),
  thumbnail_url TEXT,
  duration INTEGER, -- For voice/video messages in seconds
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- READ RECEIPTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS read_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- ============================================================
-- ANNOUNCEMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS school_announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  announcement_type VARCHAR(50) DEFAULT 'general', -- general, urgent, event, academic
  priority VARCHAR(50) DEFAULT 'normal', -- low, normal, high, urgent
  target_audience VARCHAR(50) DEFAULT 'all', -- all, students, parents, staff, teachers
  class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
  published_by UUID NOT NULL REFERENCES users(id),
  published_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  is_published BOOLEAN DEFAULT false,
  requires_acknowledgment BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ANNOUNCEMENT ATTACHMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS announcement_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  announcement_id UUID NOT NULL REFERENCES school_announcements(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT,
  file_type VARCHAR(100),
  file_size BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ANNOUNCEMENT READ TRACKING TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS announcement_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  announcement_id UUID NOT NULL REFERENCES school_announcements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  UNIQUE(announcement_id, user_id)
);

-- ============================================================
-- CIRCULARS TABLE (Formal notices with numbering)
-- ============================================================
CREATE TABLE IF NOT EXISTS circulars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  circular_number VARCHAR(100) NOT NULL,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  circular_type VARCHAR(50) DEFAULT 'general', -- general, academic, administrative, event
  target_audience VARCHAR(50) DEFAULT 'all', -- all, students, parents, staff
  class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
  section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
  issued_by UUID NOT NULL REFERENCES users(id),
  issued_date DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_date DATE,
  expiry_date DATE,
  is_active BOOLEAN DEFAULT true,
  requires_acknowledgment BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, circular_number)
);

-- ============================================================
-- CIRCULAR ATTACHMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS circular_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  circular_id UUID NOT NULL REFERENCES circulars(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT,
  file_type VARCHAR(100),
  file_size BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CIRCULAR READ TRACKING TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS circular_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  circular_id UUID NOT NULL REFERENCES circulars(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  UNIQUE(circular_id, user_id)
);

-- ============================================================
-- MESSAGE TEMPLATES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  template_name VARCHAR(255) NOT NULL,
  template_category VARCHAR(100), -- attendance, fee, assignment, general
  subject VARCHAR(500),
  content TEXT NOT NULL,
  variables TEXT[], -- Placeholder variables like {student_name}, {date}
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, template_name)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_chat_conversations_school_id ON chat_conversations(school_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_message_attachments_message_id ON message_attachments(message_id);
CREATE INDEX IF NOT EXISTS idx_read_receipts_message_id ON read_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_read_receipts_user_id ON read_receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_school_announcements_school_id ON school_announcements(school_id);
CREATE INDEX IF NOT EXISTS idx_school_announcements_published_at ON school_announcements(published_at);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement_id ON announcement_reads(announcement_id);
CREATE INDEX IF NOT EXISTS idx_circulars_school_id ON circulars(school_id);
CREATE INDEX IF NOT EXISTS idx_circulars_circular_number ON circulars(circular_number);
CREATE INDEX IF NOT EXISTS idx_circular_reads_circular_id ON circular_reads(circular_id);
CREATE INDEX IF NOT EXISTS idx_chat_message_templates_school_id ON chat_message_templates(school_id);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_chat_conversations_updated_at BEFORE UPDATE ON chat_conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_school_announcements_updated_at BEFORE UPDATE ON school_announcements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_circulars_updated_at BEFORE UPDATE ON circulars
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_message_templates_updated_at BEFORE UPDATE ON chat_message_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Function to update conversation last message
CREATE OR REPLACE FUNCTION update_chat_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_conversations
  SET last_message_at = NEW.created_at,
      last_message_preview = LEFT(NEW.content, 100)
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_conversation_last_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_conversation_last_message();

-- Function to generate circular number
CREATE OR REPLACE FUNCTION generate_circular_number(p_school_id UUID)
RETURNS VARCHAR AS $$
DECLARE
  v_year INTEGER;
  v_count INTEGER;
  v_number VARCHAR;
BEGIN
  v_year := EXTRACT(YEAR FROM CURRENT_DATE);
  
  SELECT COUNT(*) + 1 INTO v_count
  FROM circulars
  WHERE school_id = p_school_id
    AND EXTRACT(YEAR FROM created_at) = v_year;
  
  v_number := 'CIR/' || v_year || '/' || LPAD(v_count::TEXT, 4, '0');
  
  RETURN v_number;
END;
$$ LANGUAGE plpgsql;

