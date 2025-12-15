-- =============================================================
-- PAYMENT INTEGRATION SCHEMA
-- Enables schools to configure payout accounts and track transactions
-- =============================================================

-- 1. Payment providers catalog
create table if not exists payment_providers (
  id uuid primary key default gen_random_uuid(),
  provider_key text not null unique, -- easypaisa, jazzcash, stripe, bank_transfer
  display_name text not null,
  provider_type text not null, -- wallet, card_gateway, bank_transfer
  is_active boolean not null default true,
  metadata_schema jsonb, -- Optional contract of required fields
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists update_payment_providers_updated_at on payment_providers;
create trigger update_payment_providers_updated_at
before update on payment_providers
for each row execute function update_updated_at_column();

-- 2. School payment accounts
create table if not exists school_payment_accounts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  provider_id uuid not null references payment_providers(id) on delete cascade,
  account_label text not null,
  country text,
  currency text default 'PKR',
  credentials jsonb not null default '{}'::jsonb, -- encrypted client-side before storing
  metadata jsonb default '{}'::jsonb, -- extra info (documents, notes)
  status text not null default 'pending', -- pending, active, rejected, suspended
  verified_at timestamptz,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_school_payment_accounts_school
  on school_payment_accounts(school_id);

drop trigger if exists update_school_payment_accounts_updated_at on school_payment_accounts;
create trigger update_school_payment_accounts_updated_at
before update on school_payment_accounts
for each row execute function update_updated_at_column();

-- 3. Payment transactions
create table if not exists payment_transactions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  provider_id uuid references payment_providers(id) on delete set null,
  account_id uuid references school_payment_accounts(id) on delete set null,
  external_reference text, -- provider charge id
  reference_code text, -- internal invoice/fee reference
  payer_name text,
  payer_email text,
  payer_phone text,
  amount numeric(18,2) not null,
  currency text not null default 'PKR',
  status text not null default 'pending', -- pending, succeeded, failed, refunded
  error_code text,
  error_message text,
  initiated_at timestamptz not null default now(),
  completed_at timestamptz,
  raw_response jsonb,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_payment_transactions_school
  on payment_transactions(school_id);

create index if not exists idx_payment_transactions_status
  on payment_transactions(status);

-- 4. Cash fee receipts for manual payments
create table if not exists cash_fee_receipts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid references students(id) on delete set null,
  payer_name text not null,
  receipt_number text,
  amount numeric(18,2) not null,
  currency text not null default 'PKR',
  payment_date date not null default current_date,
  notes text,
  received_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_cash_fee_receipts_school
  on cash_fee_receipts(school_id);

alter table if exists cash_fee_receipts enable row level security;

drop policy if exists cash_fee_receipts_select_school on cash_fee_receipts;
create policy cash_fee_receipts_select_school
on cash_fee_receipts
for select
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = cash_fee_receipts.school_id
  )
);

drop policy if exists cash_fee_receipts_manage_school on cash_fee_receipts;
create policy cash_fee_receipts_manage_school
on cash_fee_receipts
for all
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = cash_fee_receipts.school_id
      and users.role in ('admin','principal','staff')
  )
) with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = cash_fee_receipts.school_id
      and users.role in ('admin','principal','staff')
  )
);

-- 4. Seed common providers
insert into payment_providers (provider_key, display_name, provider_type, metadata_schema)
values
  ('easypaisa', 'Easypaisa Merchant', 'wallet', '{"fields":["merchant_id","store_id","hash_key"]}'),
  ('jazzcash', 'JazzCash Merchant', 'wallet', '{"fields":["merchant_id","password","hash_key"]}'),
  ('stripe', 'Stripe', 'card_gateway', '{"fields":["publishable_key","secret_key","webhook_secret"]}'),
  ('bank_transfer', 'Bank Transfer', 'bank_transfer', '{"fields":["account_title","account_number","iban","bank_name","branch_code"]}')
on conflict (provider_key) do update set
  display_name = excluded.display_name,
  provider_type = excluded.provider_type,
  metadata_schema = excluded.metadata_schema,
  updated_at = now();

-- 5. Enable RLS
alter table if exists payment_providers enable row level security;
alter table if exists school_payment_accounts enable row level security;
alter table if exists payment_transactions enable row level security;

-- Payment providers are readable by all authenticated users (metadata only)
drop policy if exists payment_providers_select_all on payment_providers;
create policy payment_providers_select_all
on payment_providers
for select
to authenticated
using (true);

-- School payment accounts policies
drop policy if exists school_payment_accounts_select_school on school_payment_accounts;
create policy school_payment_accounts_select_school
on school_payment_accounts
for select
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = school_payment_accounts.school_id
  )
);

drop policy if exists school_payment_accounts_manage_school on school_payment_accounts;
create policy school_payment_accounts_manage_school
on school_payment_accounts
for all
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = school_payment_accounts.school_id
      and users.role in ('admin','principal')
  )
) with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = school_payment_accounts.school_id
      and users.role in ('admin','principal')
  )
);

-- Payment transactions policies
drop policy if exists payment_transactions_select_school on payment_transactions;
create policy payment_transactions_select_school
on payment_transactions
for select
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = payment_transactions.school_id
  )
);

drop policy if exists payment_transactions_insert_school on payment_transactions;
create policy payment_transactions_insert_school
on payment_transactions
for insert
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
      and users.school_id = payment_transactions.school_id
  )
);

-- Super admin bypass via service role (handled by existing RPCs/Edge functions)

-- 6. Helper function to upsert school payment account
drop function if exists upsert_school_payment_account(uuid, text, jsonb, jsonb, text);
create or replace function upsert_school_payment_account(
  p_school_id uuid,
  p_provider_key text,
  p_credentials jsonb,
  p_metadata jsonb default '{}'::jsonb,
  p_account_label text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_provider_id uuid;
  v_account_id uuid;
  v_label text := coalesce(p_account_label, initcap(p_provider_key) || ' Account');
begin
  select id into v_provider_id
  from payment_providers
  where provider_key = p_provider_key;

  if v_provider_id is null then
    raise exception 'Unknown payment provider %', p_provider_key;
  end if;

  insert into school_payment_accounts (
    school_id,
    provider_id,
    account_label,
    credentials,
    metadata,
    status
  )
  values (
    p_school_id,
    v_provider_id,
    v_label,
    p_credentials,
    coalesce(p_metadata, '{}'::jsonb),
    'pending'
  )
  on conflict (school_id, provider_id)
  do update set
    account_label = excluded.account_label,
    credentials = excluded.credentials,
    metadata = excluded.metadata,
    status = 'pending',
    updated_at = now()
  returning id into v_account_id;

  return v_account_id;
end;
$function$;

grant execute on function upsert_school_payment_account(uuid, text, jsonb, jsonb, text)
  to authenticated;

