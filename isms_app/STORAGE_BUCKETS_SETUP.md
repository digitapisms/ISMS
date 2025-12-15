# Supabase Storage Buckets Setup Guide

This guide explains how to set up the required storage buckets for the ISMS application.

## Required Buckets

1. **school-assets** - For school logos and branding assets
2. **student-documents** - For student documents, photos, and certificates

## Setup Steps

### 1. Create Buckets in Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **New Bucket**

#### Create `school-assets` bucket:
- **Name**: `school-assets`
- **Public**: ✅ Yes (logos need to be publicly accessible)
- **File size limit**: 5MB
- **Allowed MIME types**: 
  - `image/jpeg`
  - `image/png`
  - `image/gif`
  - `image/webp`

#### Create `student-documents` bucket:
- **Name**: `student-documents`
- **Public**: ❌ No (private documents)
- **File size limit**: 10MB
- **Allowed MIME types**:
  - Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
  - Documents: `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`

### 2. Set Up RLS Policies

RLS (Row Level Security) policies control who can access files in each bucket.

#### For `school-assets` bucket:

**Policy 1: Allow authenticated users to upload to their school's folder**
```sql
CREATE POLICY "school_assets_upload_own_school"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] = 'logos' AND
  (storage.foldername(name))[2] = current_user_school_id()::text
);
```

**Policy 2: Allow authenticated users to read public assets**
```sql
CREATE POLICY "school_assets_select_public"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'school-assets');
```

**Policy 3: Allow school admins to delete their school's assets**
```sql
CREATE POLICY "school_assets_delete_own_school"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] = 'logos' AND
  (storage.foldername(name))[2] = current_user_school_id()::text AND
  current_user_role() IN ('admin', 'principal', 'super_admin')
);
```

#### For `student-documents` bucket:

**Policy 1: Allow authenticated users to upload to their own student folder**
```sql
CREATE POLICY "student_documents_upload_own"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'student-documents' AND
  (storage.foldername(name))[1] = 'documents' AND
  (
    -- Students can upload to their own folder
    (storage.foldername(name))[2] IN (
      SELECT id::text FROM students 
      WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    )
    OR
    -- Admins/teachers can upload to any student in their school
    (
      current_user_role() IN ('admin', 'principal', 'teacher', 'super_admin') AND
      (storage.foldername(name))[2] IN (
        SELECT id::text FROM students 
        WHERE school_id = current_user_school_id()
      )
    )
  )
);
```

**Policy 2: Allow users to read documents for students in their school**
```sql
CREATE POLICY "student_documents_select_school"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'student-documents' AND
  (
    -- Students can read their own documents
    (storage.foldername(name))[2] IN (
      SELECT id::text FROM students 
      WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    )
    OR
    -- Parents can read their children's documents
    (storage.foldername(name))[2] IN (
      SELECT student_id::text FROM parent_student_mapping
      WHERE parent_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    )
    OR
    -- School staff can read documents for students in their school
    (
      current_user_role() IN ('admin', 'principal', 'teacher', 'staff', 'super_admin') AND
      (storage.foldername(name))[2] IN (
        SELECT id::text FROM students 
        WHERE school_id = current_user_school_id()
      )
    )
  )
);
```

**Policy 3: Allow admins to delete documents**
```sql
CREATE POLICY "student_documents_delete_admin"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'student-documents' AND
  current_user_role() IN ('admin', 'principal', 'super_admin') AND
  (storage.foldername(name))[2] IN (
    SELECT id::text FROM students 
    WHERE school_id = current_user_school_id()
  )
);
```

### 3. Folder Structure

The buckets use the following folder structure:

#### `school-assets`:
```
school-assets/
  └── logos/
      └── {school_id}/
          └── logo_{timestamp}.jpg
```

#### `student-documents`:
```
student-documents/
  └── documents/
      └── {student_id}/
          ├── {document_type}/
          │   └── {filename}
          └── {filename}
```

### 4. Testing

After setup, test the storage functionality:

1. **Test Logo Upload**:
   - Go to School Branding Settings
   - Upload a logo
   - Verify it appears in `school-assets/logos/{school_id}/`

2. **Test Document Upload**:
   - Go to Student Details
   - Upload a document
   - Verify it appears in `student-documents/documents/{student_id}/`

3. **Test Access Control**:
   - Try accessing files from different user roles
   - Verify RLS policies are working correctly

## Troubleshooting

### Issue: "Bucket not found"
- Ensure buckets are created in Supabase Dashboard
- Check bucket names match exactly: `school-assets` and `student-documents`

### Issue: "Permission denied"
- Check RLS policies are created and active
- Verify user has correct role
- Check `current_user_school_id()` function is working

### Issue: "File too large"
- Check file size limits in bucket settings
- Verify file is within allowed size (5MB for logos, 10MB for documents)

### Issue: "Invalid MIME type"
- Check file extension matches allowed MIME types
- Verify bucket MIME type restrictions

## Notes

- Storage policies use `current_user_school_id()` and `current_user_role()` functions
- These functions must be defined in your database schema
- See `CREATE_AUTH_ROLES_SCHEMA.sql` for function definitions
- Files are organized by school/student ID for easy management and RLS enforcement

