# Supabase Setup Instructions

## 1. Create Storage Bucket for Student Documents

In Supabase Dashboard → Storage, create a new bucket:

- **Bucket Name**: `student-documents`
- **Public**: Yes (or configure RLS policies)
- **File Size Limit**: 10MB (or as needed)
- **Allowed MIME Types**: `image/*, application/pdf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document`

### Storage RLS Policy

Run this SQL to allow authenticated users to upload their own documents:

```sql
-- Allow authenticated users to upload documents for their own student records
create policy "Users upload own student documents"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'student-documents' and
  (storage.foldername(name))[1] in (
    select id::text from students
    where user_id in (
      select id from users where auth_id = auth.uid()
    )
  )
);

-- Allow users to read their own documents
create policy "Users read own student documents"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'student-documents' and
  (storage.foldername(name))[1] in (
    select id::text from students
    where user_id in (
      select id from users where auth_id = auth.uid()
    )
  )
);
```

## 2. Application Fee Payment Table (Optional)

If you want to add application fee payment, run this SQL:

```sql
create table if not exists application_fees (
  id            bigserial primary key,
  application_id uuid not null references applications(id) on delete cascade,
  amount        numeric(10,2) not null,
  payment_status text not null default 'pending', -- pending, paid, failed, refunded
  payment_date  timestamptz,
  transaction_id text,
  payment_gateway text, -- stripe, razorpay, etc.
  created_at    timestamptz not null default now()
);

alter table application_fees enable row level security;

create policy "Users view own application fees"
on application_fees for select
to authenticated
using (
  application_id in (
    select id from applications
    where applicant_user_id in (
      select id from users where auth_id = auth.uid()
    )
  )
);

create policy "Admins manage all application fees"
on application_fees
for all
to authenticated
using (
  exists (
    select 1 from users
    where auth_id = auth.uid()
    and role in ('admin', 'principal', 'super_admin')
  )
);
```

