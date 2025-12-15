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

-- ============================================================
-- FUNCTIONS
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

