-- Library Management System Schema
-- Supports physical books, digital resources, issue/return, fines, and reservations

-- ============================================================
-- BOOK CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS book_categories (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  parent_category_id INTEGER REFERENCES book_categories(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, name)
);

-- ============================================================
-- BOOKS TABLE (Book catalog/master records)
-- ============================================================
CREATE TABLE IF NOT EXISTS books (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  isbn VARCHAR(50),
  title VARCHAR(500) NOT NULL,
  author VARCHAR(255),
  publisher VARCHAR(255),
  publication_year INTEGER,
  edition VARCHAR(50),
  language VARCHAR(50) DEFAULT 'english',
  category_id INTEGER REFERENCES book_categories(id) ON DELETE SET NULL,
  book_type VARCHAR(50) DEFAULT 'physical', -- physical, digital, both
  description TEXT,
  cover_image_url TEXT,
  total_copies INTEGER DEFAULT 0,
  available_copies INTEGER DEFAULT 0,
  price DECIMAL(10,2),
  shelf_location VARCHAR(255),
  tags TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, isbn)
);

-- ============================================================
-- BOOK COPIES TABLE (Individual physical copies)
-- ============================================================
CREATE TABLE IF NOT EXISTS book_copies (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  copy_number INTEGER NOT NULL,
  barcode VARCHAR(100),
  qr_code TEXT,
  status VARCHAR(50) DEFAULT 'available', -- available, issued, reserved, lost, damaged, maintenance
  condition_status VARCHAR(50) DEFAULT 'good', -- excellent, good, fair, poor, damaged
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(book_id, copy_number)
);

-- ============================================================
-- DIGITAL RESOURCES TABLE (E-books, PDFs, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS digital_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  book_id INTEGER REFERENCES books(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  resource_type VARCHAR(50) DEFAULT 'ebook', -- ebook, pdf, audio, video, document
  file_path TEXT NOT NULL,
  file_size BIGINT,
  file_type VARCHAR(100),
  file_url TEXT,
  thumbnail_url TEXT,
  description TEXT,
  access_level VARCHAR(50) DEFAULT 'public', -- public, restricted, premium
  download_allowed BOOLEAN DEFAULT true,
  max_downloads INTEGER,
  current_downloads INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BOOK ISSUES TABLE (Book issuance records)
-- ============================================================
CREATE TABLE IF NOT EXISTS book_issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  book_copy_id INTEGER REFERENCES book_copies(id) ON DELETE SET NULL,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES users(id) ON DELETE CASCADE,
  issued_by UUID NOT NULL REFERENCES users(id),
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  return_date DATE,
  status VARCHAR(50) DEFAULT 'issued', -- issued, returned, overdue, lost
  renewal_count INTEGER DEFAULT 0,
  max_renewals INTEGER DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BOOK RETURNS TABLE (Return records)
-- ============================================================
CREATE TABLE IF NOT EXISTS book_returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  issue_id UUID NOT NULL REFERENCES book_issues(id) ON DELETE CASCADE,
  returned_by UUID NOT NULL REFERENCES users(id),
  return_date DATE NOT NULL DEFAULT CURRENT_DATE,
  condition_on_return VARCHAR(50) DEFAULT 'good',
  days_overdue INTEGER DEFAULT 0,
  fine_amount DECIMAL(10,2) DEFAULT 0,
  fine_paid BOOLEAN DEFAULT false,
  damage_notes TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BOOK RESERVATIONS TABLE (Reservation system)
-- ============================================================
CREATE TABLE IF NOT EXISTS book_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reservation_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date DATE,
  status VARCHAR(50) DEFAULT 'pending', -- pending, fulfilled, cancelled, expired
  priority INTEGER DEFAULT 0,
  notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BOOK FINES TABLE (Fine records)
-- ============================================================
CREATE TABLE IF NOT EXISTS book_fines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  issue_id UUID NOT NULL REFERENCES book_issues(id) ON DELETE CASCADE,
  return_id UUID REFERENCES book_returns(id) ON DELETE SET NULL,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES users(id) ON DELETE CASCADE,
  fine_type VARCHAR(50) DEFAULT 'overdue', -- overdue, damage, loss
  amount DECIMAL(10,2) NOT NULL,
  days_overdue INTEGER DEFAULT 0,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- pending, paid, waived, cancelled
  paid_at TIMESTAMPTZ,
  paid_by UUID REFERENCES users(id),
  payment_method VARCHAR(50),
  waived_by UUID REFERENCES users(id),
  waived_at TIMESTAMPTZ,
  waiver_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DIGITAL RESOURCE ANNOTATIONS TABLE (Modern learning features)
-- ============================================================
CREATE TABLE IF NOT EXISTS digital_resource_annotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  annotation_type VARCHAR(50) NOT NULL DEFAULT 'note', -- note, highlight, comment, question, answer
  content TEXT NOT NULL,
  page_number INTEGER,
  position_x DOUBLE PRECISION,
  position_y DOUBLE PRECISION,
  highlight_color VARCHAR(20),
  is_public BOOLEAN DEFAULT false,
  replies_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ANNOTATION REPLIES TABLE (Collaboration and discussion)
-- ============================================================
CREATE TABLE IF NOT EXISTS annotation_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  annotation_id UUID NOT NULL REFERENCES digital_resource_annotations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES annotation_replies(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  is_edited BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ANNOTATION LIKES TABLE (Track user likes)
-- ============================================================
CREATE TABLE IF NOT EXISTS annotation_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  annotation_id UUID NOT NULL REFERENCES digital_resource_annotations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(annotation_id, user_id)
);

-- ============================================================
-- DIGITAL RESOURCE ACCESS TABLE (Track digital resource usage)
-- ============================================================
CREATE TABLE IF NOT EXISTS digital_resource_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_type VARCHAR(50) DEFAULT 'view', -- view, download
  accessed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address VARCHAR(50),
  device_info TEXT
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_book_categories_school_id ON book_categories(school_id);
CREATE INDEX IF NOT EXISTS idx_books_school_id ON books(school_id);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);
CREATE INDEX IF NOT EXISTS idx_books_category_id ON books(category_id);
CREATE INDEX IF NOT EXISTS idx_book_copies_book_id ON book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_book_copies_status ON book_copies(status);
CREATE INDEX IF NOT EXISTS idx_digital_resources_school_id ON digital_resources(school_id);
CREATE INDEX IF NOT EXISTS idx_digital_resources_book_id ON digital_resources(book_id);
CREATE INDEX IF NOT EXISTS idx_book_issues_school_id ON book_issues(school_id);
CREATE INDEX IF NOT EXISTS idx_book_issues_book_id ON book_issues(book_id);
CREATE INDEX IF NOT EXISTS idx_book_issues_student_id ON book_issues(student_id);
CREATE INDEX IF NOT EXISTS idx_book_issues_status ON book_issues(status);
CREATE INDEX IF NOT EXISTS idx_book_issues_due_date ON book_issues(due_date);
CREATE INDEX IF NOT EXISTS idx_book_returns_issue_id ON book_returns(issue_id);
CREATE INDEX IF NOT EXISTS idx_book_reservations_book_id ON book_reservations(book_id);
CREATE INDEX IF NOT EXISTS idx_book_reservations_student_id ON book_reservations(student_id);
CREATE INDEX IF NOT EXISTS idx_book_fines_issue_id ON book_fines(issue_id);
CREATE INDEX IF NOT EXISTS idx_book_fines_student_id ON book_fines(student_id);
CREATE INDEX IF NOT EXISTS idx_book_fines_status ON book_fines(status);
CREATE INDEX IF NOT EXISTS idx_digital_resource_annotations_resource_id ON digital_resource_annotations(resource_id);
CREATE INDEX IF NOT EXISTS idx_digital_resource_annotations_user_id ON digital_resource_annotations(user_id);
CREATE INDEX IF NOT EXISTS idx_digital_resource_annotations_type ON digital_resource_annotations(annotation_type);
CREATE INDEX IF NOT EXISTS idx_annotation_replies_annotation_id ON annotation_replies(annotation_id);
CREATE INDEX IF NOT EXISTS idx_annotation_replies_user_id ON annotation_replies(user_id);
CREATE INDEX IF NOT EXISTS idx_annotation_replies_parent_id ON annotation_replies(parent_reply_id);
CREATE INDEX IF NOT EXISTS idx_annotation_likes_annotation_id ON annotation_likes(annotation_id);
CREATE INDEX IF NOT EXISTS idx_annotation_likes_user_id ON annotation_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_digital_resource_access_resource_id ON digital_resource_access(resource_id);
CREATE INDEX IF NOT EXISTS idx_digital_resource_access_user_id ON digital_resource_access(user_id);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_book_categories_updated_at BEFORE UPDATE ON book_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_copies_updated_at BEFORE UPDATE ON book_copies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_digital_resources_updated_at BEFORE UPDATE ON digital_resources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_issues_updated_at BEFORE UPDATE ON book_issues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_reservations_updated_at BEFORE UPDATE ON book_reservations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_fines_updated_at BEFORE UPDATE ON book_fines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_digital_resource_annotations_updated_at BEFORE UPDATE ON digital_resource_annotations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_annotation_replies_updated_at BEFORE UPDATE ON annotation_replies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

-- Enable RLS on annotation tables
alter table digital_resource_annotations enable row level security;
alter table annotation_replies enable row level security;
alter table annotation_likes enable row level security;

-- Drop existing policies if they exist
drop policy if exists "annotations_select_school" on digital_resource_annotations;
drop policy if exists "annotations_insert_authenticated" on digital_resource_annotations;
drop policy if exists "annotations_update_owner" on digital_resource_annotations;
drop policy if exists "annotations_delete_owner" on digital_resource_annotations;

drop policy if exists "annotation_replies_select_school" on annotation_replies;
drop policy if exists "annotation_replies_insert_authenticated" on annotation_replies;
drop policy if exists "annotation_replies_update_owner" on annotation_replies;
drop policy if exists "annotation_replies_delete_owner" on annotation_replies;

drop policy if exists "annotation_likes_select_school" on annotation_likes;
drop policy if exists "annotation_likes_insert_authenticated" on annotation_likes;
drop policy if exists "annotation_likes_delete_owner" on annotation_likes;

-- Annotation policies
create policy "annotations_select_school"
on digital_resource_annotations for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "annotations_insert_authenticated"
on digital_resource_annotations for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "annotations_update_owner"
on digital_resource_annotations for update to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = digital_resource_annotations.school_id
  )
);

create policy "annotations_delete_owner"
on digital_resource_annotations for delete to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = digital_resource_annotations.school_id
  )
);

-- Annotation reply policies
create policy "annotation_replies_select_school"
on annotation_replies for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "annotation_replies_insert_authenticated"
on annotation_replies for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "annotation_replies_update_owner"
on annotation_replies for update to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = annotation_replies.school_id
  )
);

create policy "annotation_replies_delete_owner"
on annotation_replies for delete to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = annotation_replies.school_id
  )
);

-- Annotation like policies
create policy "annotation_likes_select_school"
on annotation_likes for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "annotation_likes_insert_authenticated"
on annotation_likes for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "annotation_likes_delete_owner"
on annotation_likes for delete to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = annotation_likes.school_id
  )
);

-- ============================================================
-- ROW LEVEL SECURITY POLICIES FOR RESOURCE SHARING TABLES
-- ============================================================

-- Drop existing policies if they exist
drop policy if exists "resource_share_links_select_school" on resource_share_links;
drop policy if exists "resource_share_links_insert_authenticated" on resource_share_links;
drop policy if exists "resource_share_links_update_owner" on resource_share_links;
drop policy if exists "resource_share_links_delete_owner" on resource_share_links;

drop policy if exists "resource_share_permissions_select_school" on resource_share_permissions;
drop policy if exists "resource_share_permissions_insert_authenticated" on resource_share_permissions;
drop policy if exists "resource_share_permissions_update_owner" on resource_share_permissions;
drop policy if exists "resource_share_permissions_delete_owner" on resource_share_permissions;

drop policy if exists "resource_share_invitations_select_school" on resource_share_invitations;
drop policy if exists "resource_share_invitations_insert_authenticated" on resource_share_invitations;
drop policy if exists "resource_share_invitations_update_owner" on resource_share_invitations;
drop policy if exists "resource_share_invitations_delete_owner" on resource_share_invitations;

drop policy if exists "resource_collaborators_select_school" on resource_collaborators;
drop policy if exists "resource_collaborators_insert_authenticated" on resource_collaborators;
drop policy if exists "resource_collaborators_update_owner" on resource_collaborators;
drop policy if exists "resource_collaborators_delete_owner" on resource_collaborators;

-- Resource Share Links policies
create policy "resource_share_links_select_school"
on resource_share_links for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_share_links_insert_authenticated"
on resource_share_links for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and created_by = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "resource_share_links_update_owner"
on resource_share_links for update to authenticated
using (
  created_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_links.school_id
  )
);

create policy "resource_share_links_delete_owner"
on resource_share_links for delete to authenticated
using (
  created_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_links.school_id
  )
);

-- Resource Share Permissions policies
create policy "resource_share_permissions_select_school"
on resource_share_permissions for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_share_permissions_insert_authenticated"
on resource_share_permissions for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and granted_by = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "resource_share_permissions_update_owner"
on resource_share_permissions for update to authenticated
using (
  granted_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_permissions.school_id
  )
);

create policy "resource_share_permissions_delete_owner"
on resource_share_permissions for delete to authenticated
using (
  granted_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_permissions.school_id
  )
);

-- Resource Share Invitations policies
create policy "resource_share_invitations_select_school"
on resource_share_invitations for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_share_invitations_insert_authenticated"
on resource_share_invitations for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and inviter_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "resource_share_invitations_update_owner"
on resource_share_invitations for update to authenticated
using (
  inviter_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_invitations.school_id
  )
);

create policy "resource_share_invitations_delete_owner"
on resource_share_invitations for delete to authenticated
using (
  inviter_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_share_invitations.school_id
  )
);

-- Resource Collaborators policies
create policy "resource_collaborators_select_school"
on resource_collaborators for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_collaborators_insert_authenticated"
on resource_collaborators for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and added_by = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "resource_collaborators_update_owner"
on resource_collaborators for update to authenticated
using (
  added_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_collaborators.school_id
  )
);

create policy "resource_collaborators_delete_owner"
on resource_collaborators for delete to authenticated
using (
  added_by = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_collaborators.school_id
  )
);

-- ============================================================
-- ROW LEVEL SECURITY POLICIES FOR ANALYTICS TABLES
-- ============================================================

-- Drop existing policies if they exist
drop policy if exists "resource_progress_tracking_select_school" on resource_progress_tracking;
drop policy if exists "resource_progress_tracking_insert_authenticated" on resource_progress_tracking;
drop policy if exists "resource_progress_tracking_update_owner" on resource_progress_tracking;

drop policy if exists "learning_sessions_select_school" on learning_sessions;
drop policy if exists "learning_sessions_insert_authenticated" on learning_sessions;
drop policy if exists "learning_sessions_update_owner" on learning_sessions;

drop policy if exists "user_learning_analytics_select_school" on user_learning_analytics;
drop policy if exists "user_learning_analytics_insert_authenticated" on user_learning_analytics;
drop policy if exists "user_learning_analytics_update_owner" on user_learning_analytics;

drop policy if exists "resource_analytics_select_school" on resource_analytics;
drop policy if exists "resource_analytics_insert_authenticated" on resource_analytics;
drop policy if exists "resource_analytics_update_owner" on resource_analytics;

-- Resource Progress Tracking policies
create policy "resource_progress_tracking_select_school"
on resource_progress_tracking for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_progress_tracking_insert_authenticated"
on resource_progress_tracking for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "resource_progress_tracking_update_owner"
on resource_progress_tracking for update to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_progress_tracking.school_id
  )
);

-- Learning Sessions policies
create policy "learning_sessions_select_school"
on learning_sessions for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "learning_sessions_insert_authenticated"
on learning_sessions for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "learning_sessions_update_owner"
on learning_sessions for update to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = learning_sessions.school_id
  )
);

-- User Learning Analytics policies
create policy "user_learning_analytics_select_school"
on user_learning_analytics for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "user_learning_analytics_insert_authenticated"
on user_learning_analytics for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  and user_id = (
    select id from users where auth_id = auth.uid()
  )
);

create policy "user_learning_analytics_update_owner"
on user_learning_analytics for update to authenticated
using (
  user_id = (
    select id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = user_learning_analytics.school_id
  )
);

-- Resource Analytics policies
create policy "resource_analytics_select_school"
on resource_analytics for select to authenticated
using (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
  or exists (
    select 1 from users where auth_id = auth.uid() and role = 'super_admin'
  )
);

create policy "resource_analytics_insert_authenticated"
on resource_analytics for insert to authenticated
with check (
  school_id in (
    select school_id from users where auth_id = auth.uid()
  )
);

create policy "resource_analytics_update_owner"
on resource_analytics for update to authenticated
using (
  exists (
    select 1 from users 
    where auth_id = auth.uid() 
    and role in ('admin', 'principal', 'teacher')
    and school_id = resource_analytics.school_id
  )
);

-- ============================================================
-- FUNCTIONS
-- ============================================================
-- RESOURCE SHARING TABLES
-- ============================================================

-- ============================================================
-- RESOURCE SHARE LINKS TABLE (Shareable resource links)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_share_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  share_token VARCHAR(100) NOT NULL UNIQUE,
  share_type VARCHAR(50) DEFAULT 'view', -- view, download, edit
  access_level VARCHAR(50) DEFAULT 'public', -- public, restricted, private
  expires_at TIMESTAMPTZ,
  max_uses INTEGER,
  current_uses INTEGER DEFAULT 0,
  password_hash TEXT,
  is_active BOOLEAN DEFAULT true,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RESOURCE SHARE PERMISSIONS TABLE (Individual access permissions)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_share_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  share_link_id UUID REFERENCES resource_share_links(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  email VARCHAR(255),
  permission_level VARCHAR(50) DEFAULT 'view', -- view, download, edit, comment
  granted_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, revoked
  expires_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(share_link_id, user_id),
  UNIQUE(share_link_id, email)
);

-- ============================================================
-- RESOURCE SHARE INVITATIONS TABLE (Invitation management)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_share_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invitee_email VARCHAR(255) NOT NULL,
  invitee_name VARCHAR(255),
  permission_level VARCHAR(50) DEFAULT 'view', -- view, download, edit, comment
  message TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, declined, expired
  share_token VARCHAR(100) UNIQUE,
  expires_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  accepted_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RESOURCE COLLABORATORS TABLE (Track active collaborators)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_level VARCHAR(50) DEFAULT 'view', -- view, download, edit, comment
  added_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  last_accessed_at TIMESTAMPTZ,
  UNIQUE(resource_id, user_id)
);

-- ============================================================
-- INDEXES FOR RESOURCE SHARING TABLES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_resource_share_links_school_id ON resource_share_links(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_links_resource_id ON resource_share_links(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_links_share_token ON resource_share_links(share_token);
CREATE INDEX IF NOT EXISTS idx_resource_share_links_created_by ON resource_share_links(created_by);
CREATE INDEX IF NOT EXISTS idx_resource_share_links_expires_at ON resource_share_links(expires_at);

CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_school_id ON resource_share_permissions(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_resource_id ON resource_share_permissions(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_share_link_id ON resource_share_permissions(share_link_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_user_id ON resource_share_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_email ON resource_share_permissions(email);
CREATE INDEX IF NOT EXISTS idx_resource_share_permissions_status ON resource_share_permissions(status);

CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_school_id ON resource_share_invitations(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_resource_id ON resource_share_invitations(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_inviter_id ON resource_share_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_invitee_email ON resource_share_invitations(invitee_email);
CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_status ON resource_share_invitations(status);
CREATE INDEX IF NOT EXISTS idx_resource_share_invitations_share_token ON resource_share_invitations(share_token);

CREATE INDEX IF NOT EXISTS idx_resource_collaborators_school_id ON resource_collaborators(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_collaborators_resource_id ON resource_collaborators(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_collaborators_user_id ON resource_collaborators(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_collaborators_permission_level ON resource_collaborators(permission_level);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_resource_share_links_updated_at BEFORE UPDATE ON resource_share_links
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resource_share_permissions_updated_at BEFORE UPDATE ON resource_share_permissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resource_share_invitations_updated_at BEFORE UPDATE ON resource_share_invitations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- LEARNING ANALYTICS TABLES
-- ============================================================

-- ============================================================
-- RESOURCE_PROGRESS_TRACKING TABLE (Detailed progress tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_progress_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL,
  progress_type VARCHAR(50) DEFAULT 'view', -- view, read, completed, quiz, exercise
  progress_value DOUBLE PRECISION DEFAULT 0, -- percentage, score, etc.
  time_spent_seconds INTEGER DEFAULT 0,
  page_number INTEGER,
  total_pages INTEGER,
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT false,
  completion_percentage DOUBLE PRECISION DEFAULT 0,
  engagement_score DOUBLE PRECISION DEFAULT 0,
  device_info TEXT,
  ip_address VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LEARNING_SESSIONS TABLE (Track learning sessions)
-- ============================================================
CREATE TABLE IF NOT EXISTS learning_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_type VARCHAR(50) DEFAULT 'resource_study', -- resource_study, quiz, exercise, review
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  total_duration_seconds INTEGER DEFAULT 0,
  resources_accessed INTEGER DEFAULT 0,
  total_progress_made DOUBLE PRECISION DEFAULT 0,
  avg_engagement_score DOUBLE PRECISION DEFAULT 0,
  device_type VARCHAR(50),
  ip_address VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- USER_LEARNING_ANALYTICS TABLE (Aggregated analytics)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_learning_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_learning_time_seconds INTEGER DEFAULT 0,
  resources_accessed INTEGER DEFAULT 0,
  resources_completed INTEGER DEFAULT 0,
  avg_completion_rate DOUBLE PRECISION DEFAULT 0,
  total_progress_made DOUBLE PRECISION DEFAULT 0,
  engagement_score DOUBLE PRECISION DEFAULT 0,
  learning_pattern VARCHAR(50), -- morning, afternoon, evening, night
  preferred_resource_types TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, user_id, date)
);

-- ============================================================
-- RESOURCE_ANALYTICS TABLE (Resource-level analytics)
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES digital_resources(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_views INTEGER DEFAULT 0,
  unique_users INTEGER DEFAULT 0,
  total_time_spent_seconds INTEGER DEFAULT 0,
  avg_time_spent_seconds DOUBLE PRECISION DEFAULT 0,
  completion_count INTEGER DEFAULT 0,
  completion_rate DOUBLE PRECISION DEFAULT 0,
  avg_engagement_score DOUBLE PRECISION DEFAULT 0,
  popular_sections TEXT[],
  difficulty_rating DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, resource_id, date)
);

-- ============================================================
-- INDEXES FOR ANALYTICS TABLES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_resource_progress_tracking_school_id ON resource_progress_tracking(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_progress_tracking_user_id ON resource_progress_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_progress_tracking_resource_id ON resource_progress_tracking(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_progress_tracking_session_id ON resource_progress_tracking(session_id);
CREATE INDEX IF NOT EXISTS idx_resource_progress_tracking_created_at ON resource_progress_tracking(created_at);

CREATE INDEX IF NOT EXISTS idx_learning_sessions_school_id ON learning_sessions(school_id);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_id ON learning_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_start_time ON learning_sessions(start_time);

CREATE INDEX IF NOT EXISTS idx_user_learning_analytics_school_id ON user_learning_analytics(school_id);
CREATE INDEX IF NOT EXISTS idx_user_learning_analytics_user_id ON user_learning_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_learning_analytics_date ON user_learning_analytics(date);

CREATE INDEX IF NOT EXISTS idx_resource_analytics_school_id ON resource_analytics(school_id);
CREATE INDEX IF NOT EXISTS idx_resource_analytics_resource_id ON resource_analytics(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_analytics_date ON resource_analytics(date);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_resource_progress_tracking_updated_at BEFORE UPDATE ON resource_progress_tracking
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_sessions_updated_at BEFORE UPDATE ON learning_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_learning_analytics_updated_at BEFORE UPDATE ON user_learning_analytics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resource_analytics_updated_at BEFORE UPDATE ON resource_analytics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================

-- Function to update book copy counts
CREATE OR REPLACE FUNCTION update_book_copy_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE books
    SET total_copies = total_copies + 1,
        available_copies = available_copies + CASE WHEN NEW.status = 'available' THEN 1 ELSE 0 END
    WHERE id = NEW.book_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status != NEW.status THEN
      UPDATE books
      SET available_copies = available_copies + 
        CASE WHEN NEW.status = 'available' THEN 1 ELSE 0 END -
        CASE WHEN OLD.status = 'available' THEN 1 ELSE 0 END
      WHERE id = NEW.book_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE books
    SET total_copies = total_copies - 1,
        available_copies = available_copies - CASE WHEN OLD.status = 'available' THEN 1 ELSE 0 END
    WHERE id = OLD.book_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_book_copy_counts
  AFTER INSERT OR UPDATE OR DELETE ON book_copies
  FOR EACH ROW EXECUTE FUNCTION update_book_copy_counts();

-- Function to calculate overdue days and fines
CREATE OR REPLACE FUNCTION calculate_overdue_fine(
  p_issue_id UUID,
  p_fine_per_day DECIMAL DEFAULT 5.0
)
RETURNS TABLE (
  days_overdue INTEGER,
  fine_amount DECIMAL
) AS $$
DECLARE
  v_due_date DATE;
  v_days INTEGER;
  v_fine DECIMAL;
BEGIN
  SELECT due_date INTO v_due_date
  FROM book_issues
  WHERE id = p_issue_id AND status = 'issued';
  
  IF v_due_date IS NULL THEN
    RETURN;
  END IF;
  
  v_days := GREATEST(0, CURRENT_DATE - v_due_date);
  v_fine := v_days * p_fine_per_day;
  
  RETURN QUERY SELECT v_days, v_fine;
END;
$$ LANGUAGE plpgsql;

