# Supabase Storage Setup

The student management screens rely on two Supabase Storage buckets:

| Bucket | Purpose | Suggested Folder Structure |
| ------ | ------- | -------------------------- |
| `student-media` | Stores student profile photos uploaded from the Add/Edit student forms. | `avatars/{school_id}/...` |
| `student-documents` | Stores supporting documents uploaded from the student detail screen (birth certificates, report cards, etc.). | `{student_id}/{document_type}/...` |

## Creating the buckets

Run the following once per Supabase project (CLI or SQL editor):

```sql
-- Student profile photos
insert into storage.buckets (id, name, public)
values ('student-media', 'student-media', true)
on conflict (id) do nothing;

-- Student documents
insert into storage.buckets (id, name, public)
values ('student-documents', 'student-documents', true)
on conflict (id) do nothing;
```

## Recommended policies

Grant read access to anyone that can view students, and restrict writes to authenticated school users:

```sql
-- Allow authenticated users to upload/update
create policy "Allow school staff to manage student-media"
on storage.objects for all
using (bucket_id = 'student-media' and auth.role() = 'authenticated')
with check (bucket_id = 'student-media' and auth.role() = 'authenticated');

create policy "Allow school staff to manage student-documents"
on storage.objects for all
using (bucket_id = 'student-documents' and auth.role() = 'authenticated')
with check (bucket_id = 'student-documents' and auth.role() = 'authenticated');

-- Public read access (optional)
create policy "Public read student-media"
on storage.objects for select
using (bucket_id = 'student-media');

create policy "Public read student-documents"
on storage.objects for select
using (bucket_id = 'student-documents');
```

Adjust the policies to fit your security requirements (e.g., limit reads to authenticated users only).

