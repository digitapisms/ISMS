-- Document Management System Schema
-- Handles file storage, sharing, and versioning

-- Documents Table
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL, -- Storage path
    file_url TEXT NOT NULL, -- Public URL
    file_size BIGINT NOT NULL, -- Size in bytes
    mime_type VARCHAR(100) NOT NULL,
    category VARCHAR(100), -- academic, administrative, student_records, etc.
    tags TEXT[], -- Array of tags for search
    folder_id UUID, -- For folder organization (self-referencing)
    shared_with_classes INTEGER[], -- Array of class IDs
    shared_with_users UUID[], -- Array of user IDs
    is_public BOOLEAN DEFAULT FALSE, -- Public to all school users
    is_archived BOOLEAN DEFAULT FALSE,
    version_number INTEGER NOT NULL DEFAULT 1,
    current_version_id UUID, -- Points to latest version
    uploaded_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Document Versions Table
CREATE TABLE IF NOT EXISTS document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    change_summary TEXT, -- What changed in this version
    uploaded_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(document_id, version_number)
);

-- Document Shares Table (for tracking who has access)
CREATE TABLE IF NOT EXISTS document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    shared_with_class_id INTEGER REFERENCES classes(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) NOT NULL DEFAULT 'view', -- view, download, edit
    shared_by UUID NOT NULL REFERENCES users(id),
    shared_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Document Access Log (for audit trail)
CREATE TABLE IF NOT EXISTS document_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    accessed_by UUID NOT NULL REFERENCES users(id),
    access_type VARCHAR(20) NOT NULL, -- view, download, edit
    accessed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_documents_school ON documents(school_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_documents_folder ON documents(folder_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_document_versions_document ON document_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_document_shares_document ON document_shares(document_id);
CREATE INDEX IF NOT EXISTS idx_document_access_logs_document ON document_access_logs(document_id);
CREATE INDEX IF NOT EXISTS idx_document_access_logs_user ON document_access_logs(accessed_by);

-- Full-text search index on documents
CREATE INDEX IF NOT EXISTS idx_documents_search ON documents USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_documents_updated_at();

-- Function to create new document version
CREATE OR REPLACE FUNCTION create_document_version(
    p_document_id UUID,
    p_file_name VARCHAR,
    p_file_path TEXT,
    p_file_url TEXT,
    p_file_size BIGINT,
    p_mime_type VARCHAR,
    p_change_summary TEXT,
    p_uploaded_by UUID
) RETURNS UUID AS $$
DECLARE
    v_version_number INTEGER;
    v_version_id UUID;
BEGIN
    -- Get next version number
    SELECT COALESCE(MAX(version_number), 0) + 1
    INTO v_version_number
    FROM document_versions
    WHERE document_id = p_document_id;
    
    -- Create version record
    INSERT INTO document_versions (
        document_id, version_number, file_name, file_path, file_url,
        file_size, mime_type, change_summary, uploaded_by
    ) VALUES (
        p_document_id, v_version_number, p_file_name, p_file_path, p_file_url,
        p_file_size, p_mime_type, p_change_summary, p_uploaded_by
    ) RETURNING id INTO v_version_id;
    
    -- Update document with new version
    UPDATE documents
    SET version_number = v_version_number,
        current_version_id = v_version_id,
        file_name = p_file_name,
        file_path = p_file_path,
        file_url = p_file_url,
        file_size = p_file_size,
        mime_type = p_mime_type,
        updated_at = NOW()
    WHERE id = p_document_id;
    
    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;

-- Policies for documents
CREATE POLICY documents_select_school ON documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = documents.school_id
            AND (
                documents.is_public = TRUE
                OR documents.uploaded_by = users.id
                OR users.id = ANY(documents.shared_with_users)
                OR users.class_id = ANY(documents.shared_with_classes)
                OR EXISTS (
                    SELECT 1 FROM document_shares ds
                    WHERE ds.document_id = documents.id
                    AND (ds.shared_with_user_id = users.id OR ds.shared_with_class_id = users.class_id)
                )
            )
        )
    );

CREATE POLICY documents_insert_school ON documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = documents.school_id
            AND users.role IN ('admin', 'principal', 'teacher', 'staff')
        )
    );

CREATE POLICY documents_update_school ON documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = documents.school_id
            AND (
                documents.uploaded_by = users.id
                OR users.role IN ('admin', 'principal')
            )
        )
    );

CREATE POLICY documents_delete_school ON documents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = documents.school_id
            AND (
                documents.uploaded_by = users.id
                OR users.role IN ('admin', 'principal')
            )
        )
    );

-- Similar policies for other tables...
CREATE POLICY document_versions_select_school ON document_versions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM documents d
            JOIN users u ON u.school_id = d.school_id
            WHERE u.auth_id = auth.uid()
            AND d.id = document_versions.document_id
        )
    );

CREATE POLICY document_shares_select_school ON document_shares
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM documents d
            JOIN users u ON u.school_id = d.school_id
            WHERE u.auth_id = auth.uid()
            AND d.id = document_shares.document_id
        )
    );

