-- =============================================================
-- FEE MANAGEMENT SCHEMA
-- Complete fee lifecycle management for Pakistani schools
-- =============================================================

-- 1. Fee categories (tuition, transport, library, etc.)
create table if not exists fee_categories (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null, -- Tuition, Transport, Library, Lab, Sports, etc.
  code text, -- Short code like TUITION, TRANS, LIB, etc.
  description text,
  is_active boolean not null default true,
  display_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  constraint fee_categories_unique_school_name 
    unique (school_id, name)
);

create index if not exists idx_fee_categories_school 
  on fee_categories(school_id);

drop trigger if exists update_fee_categories_updated_at on fee_categories;
create trigger update_fee_categories_updated_at
before update on fee_categories
for each row execute function update_updated_at_column();

-- 2. Fee structures (defines fee amounts for different categories)
create table if not exists fee_structures (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  category_id uuid not null references fee_categories(id) on delete cascade,
  name text not null, -- e.g., "Class 1 Tuition Fee", "Transport Route A"
  description text,
  amount numeric(18,2) not null,
  currency text not null default 'PKR',
  frequency text not null default 'monthly', -- monthly, quarterly, yearly, one_time
  applicable_to text not null default 'all', -- all, class, section, student
  class_id int references classes(id) on delete set null,
  section_id int references sections(id) on delete set null,
  student_id uuid references students(id) on delete set null,
  start_date date, -- When this fee structure becomes active
  end_date date, -- When this fee structure expires
  is_active boolean not null default true,
  late_fee_percentage numeric(5,2) default 0, -- Late fee percentage
  late_fee_fixed_amount numeric(18,2) default 0, -- Fixed late fee amount
  discount_percentage numeric(5,2) default 0, -- Discount percentage
  discount_fixed_amount numeric(18,2) default 0, -- Fixed discount amount
  metadata jsonb default '{}'::jsonb, -- Additional fee-specific data
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_fee_structures_school 
  on fee_structures(school_id);
create index if not exists idx_fee_structures_category 
  on fee_structures(category_id);
create index if not exists idx_fee_structures_class 
  on fee_structures(class_id);
create index if not exists idx_fee_structures_student 
  on fee_structures(student_id);
create index if not exists idx_fee_structures_active 
  on fee_structures(is_active) where is_active = true;

drop trigger if exists update_fee_structures_updated_at on fee_structures;
create trigger update_fee_structures_updated_at
before update on fee_structures
for each row execute function update_updated_at_column();

-- 3. Fee invoices (challans/vouchers)
create table if not exists fee_invoices (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  invoice_number text not null, -- Unique invoice/challan number
  invoice_type text not null default 'fee', -- fee, admission, security_deposit, etc.
  issue_date date not null default current_date,
  due_date date not null,
  status text not null default 'pending', -- pending, partial, paid, overdue, cancelled
  total_amount numeric(18,2) not null,
  paid_amount numeric(18,2) not null default 0,
  discount_amount numeric(18,2) not null default 0,
  late_fee_amount numeric(18,2) not null default 0,
  currency text not null default 'PKR',
  notes text,
  metadata jsonb default '{}'::jsonb,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  constraint fee_invoices_unique_number 
    unique (school_id, invoice_number)
);

create index if not exists idx_fee_invoices_school 
  on fee_invoices(school_id);
create index if not exists idx_fee_invoices_student 
  on fee_invoices(student_id);
create index if not exists idx_fee_invoices_status 
  on fee_invoices(status);
create index if not exists idx_fee_invoices_due_date 
  on fee_invoices(due_date);
create index if not exists idx_fee_invoices_number 
  on fee_invoices(invoice_number);

drop trigger if exists update_fee_invoices_updated_at on fee_invoices;
create trigger update_fee_invoices_updated_at
before update on fee_invoices
for each row execute function update_updated_at_column();

-- 4. Fee invoice items (line items in an invoice)
create table if not exists fee_invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references fee_invoices(id) on delete cascade,
  fee_structure_id uuid references fee_structures(id) on delete set null,
  category_id uuid references fee_categories(id) on delete set null,
  description text not null,
  quantity int not null default 1,
  unit_amount numeric(18,2) not null,
  total_amount numeric(18,2) not null,
  discount_amount numeric(18,2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_fee_invoice_items_invoice 
  on fee_invoice_items(invoice_id);
create index if not exists idx_fee_invoice_items_structure 
  on fee_invoice_items(fee_structure_id);

-- 5. Fee payments (links payments to invoices)
create table if not exists fee_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  invoice_id uuid not null references fee_invoices(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  payment_transaction_id uuid references payment_transactions(id) on delete set null,
  cash_receipt_id uuid references cash_fee_receipts(id) on delete set null,
  payment_method text not null, -- easypaisa, jazzcash, bank_transfer, card, cash
  amount numeric(18,2) not null,
  currency text not null default 'PKR',
  payment_date date not null default current_date,
  payment_reference text, -- Transaction reference, cheque number, etc.
  notes text,
  received_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_fee_payments_school 
  on fee_payments(school_id);
create index if not exists idx_fee_payments_invoice 
  on fee_payments(invoice_id);
create index if not exists idx_fee_payments_student 
  on fee_payments(student_id);
create index if not exists idx_fee_payments_date 
  on fee_payments(payment_date);

-- 6. Fee waivers and concessions
create table if not exists fee_waivers (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  fee_structure_id uuid references fee_structures(id) on delete set null,
  waiver_type text not null, -- full, percentage, fixed_amount
  waiver_amount numeric(18,2), -- For fixed amount waivers
  waiver_percentage numeric(5,2), -- For percentage waivers
  reason text not null, -- Merit, sibling, financial hardship, etc.
  start_date date,
  end_date date,
  is_active boolean not null default true,
  approved_by uuid references users(id) on delete set null,
  approved_at timestamptz,
  created_by uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_fee_waivers_school 
  on fee_waivers(school_id);
create index if not exists idx_fee_waivers_student 
  on fee_waivers(student_id);
create index if not exists idx_fee_waivers_active 
  on fee_waivers(is_active) where is_active = true;

drop trigger if exists update_fee_waivers_updated_at on fee_waivers;
create trigger update_fee_waivers_updated_at
before update on fee_waivers
for each row execute function update_updated_at_column();

-- 7. RLS Policies for fee_categories
alter table if exists fee_categories enable row level security;

drop policy if exists fee_categories_select_school on fee_categories;
create policy fee_categories_select_school
on fee_categories
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_categories.school_id
  )
);

drop policy if exists fee_categories_insert_school on fee_categories;
create policy fee_categories_insert_school
on fee_categories
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_categories.school_id
    and users.role in ('admin', 'principal')
  )
);

drop policy if exists fee_categories_update_school on fee_categories;
create policy fee_categories_update_school
on fee_categories
for update
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_categories.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 8. RLS Policies for fee_structures
alter table if exists fee_structures enable row level security;

drop policy if exists fee_structures_select_school on fee_structures;
create policy fee_structures_select_school
on fee_structures
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_structures.school_id
  )
);

drop policy if exists fee_structures_insert_school on fee_structures;
create policy fee_structures_insert_school
on fee_structures
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_structures.school_id
    and users.role in ('admin', 'principal')
  )
);

drop policy if exists fee_structures_update_school on fee_structures;
create policy fee_structures_update_school
on fee_structures
for update
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_structures.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 9. RLS Policies for fee_invoices
alter table if exists fee_invoices enable row level security;

drop policy if exists fee_invoices_select_school on fee_invoices;
create policy fee_invoices_select_school
on fee_invoices
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_invoices.school_id
  )
);

drop policy if exists fee_invoices_insert_school on fee_invoices;
create policy fee_invoices_insert_school
on fee_invoices
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_invoices.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

drop policy if exists fee_invoices_update_school on fee_invoices;
create policy fee_invoices_update_school
on fee_invoices
for update
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_invoices.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 10. RLS Policies for fee_payments
alter table if exists fee_payments enable row level security;

drop policy if exists fee_payments_select_school on fee_payments;
create policy fee_payments_select_school
on fee_payments
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_payments.school_id
  )
);

drop policy if exists fee_payments_insert_school on fee_payments;
create policy fee_payments_insert_school
on fee_payments
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_payments.school_id
    and users.role in ('admin', 'principal', 'teacher')
  )
);

-- 11. RLS Policies for fee_waivers
alter table if exists fee_waivers enable row level security;

drop policy if exists fee_waivers_select_school on fee_waivers;
create policy fee_waivers_select_school
on fee_waivers
for select
to authenticated
using (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_waivers.school_id
  )
);

drop policy if exists fee_waivers_insert_school on fee_waivers;
create policy fee_waivers_insert_school
on fee_waivers
for insert
to authenticated
with check (
  exists (
    select 1 from users
    where users.auth_id = auth.uid()
    and users.school_id = fee_waivers.school_id
    and users.role in ('admin', 'principal')
  )
);

-- 12. Function to generate invoice number (Pakistani format: INV-YYYY-MM-XXXXX)
create or replace function generate_fee_invoice_number(
  p_school_id uuid
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text := 'INV';
  v_year text := to_char(current_date, 'YYYY');
  v_month text := to_char(current_date, 'MM');
  v_sequence int;
  v_invoice_number text;
begin
  -- Get the next sequence number for this month
  select coalesce(max(
    cast(substring(invoice_number from '-\d+$') as int)
  ), 0) + 1
  into v_sequence
  from fee_invoices
  where school_id = p_school_id
    and invoice_number like v_prefix || '-' || v_year || '-' || v_month || '-%';
  
  -- Format: INV-YYYY-MM-XXXXX (5 digit sequence)
  v_invoice_number := v_prefix || '-' || v_year || '-' || v_month || '-' || 
    lpad(v_sequence::text, 5, '0');
  
  return v_invoice_number;
end;
$$;

-- 13. Function to calculate invoice total with discounts and late fees
create or replace function calculate_invoice_total(
  p_invoice_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subtotal numeric;
  v_discount numeric;
  v_late_fee numeric;
  v_total numeric;
  v_due_date date;
  v_days_overdue int;
begin
  -- Calculate subtotal from invoice items
  select coalesce(sum(total_amount - discount_amount), 0)
  into v_subtotal
  from fee_invoice_items
  where invoice_id = p_invoice_id;
  
  -- Get invoice details
  select due_date, discount_amount, late_fee_amount
  into v_due_date, v_discount, v_late_fee
  from fee_invoices
  where id = p_invoice_id;
  
  -- Calculate late fee if overdue
  if v_due_date < current_date and v_late_fee = 0 then
    v_days_overdue := current_date - v_due_date;
    -- Apply late fee calculation if needed
    -- This can be enhanced based on fee structure late fee rules
  end if;
  
  v_total := v_subtotal - coalesce(v_discount, 0) + coalesce(v_late_fee, 0);
  
  return v_total;
end;
$$;

-- 14. Function to get student fee summary
create or replace function get_student_fee_summary(
  p_student_id uuid,
  p_school_id uuid
)
returns table (
  total_invoices int,
  pending_invoices int,
  paid_invoices int,
  overdue_invoices int,
  total_due_amount numeric,
  total_paid_amount numeric,
  total_outstanding numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_pending int;
  v_paid int;
  v_overdue int;
  v_due numeric;
  v_paid numeric;
  v_outstanding numeric;
begin
  -- Count invoices
  select count(*) into v_total
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id
    and status != 'cancelled';
  
  select count(*) into v_pending
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id
    and status = 'pending';
  
  select count(*) into v_paid
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id
    and status = 'paid';
  
  select count(*) into v_overdue
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id
    and status = 'overdue';
  
  -- Calculate amounts
  select coalesce(sum(total_amount), 0) into v_due
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id
    and status in ('pending', 'partial', 'overdue');
  
  select coalesce(sum(paid_amount), 0) into v_paid
  from fee_invoices
  where student_id = p_student_id
    and school_id = p_school_id;
  
  v_outstanding := v_due - v_paid;
  
  return query select
    v_total,
    v_pending,
    v_paid,
    v_overdue,
    v_due,
    v_paid,
    v_outstanding;
end;
$$;

-- 15. Trigger to update invoice status based on payments
create or replace function update_invoice_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_amount numeric;
  v_paid_amount numeric;
  v_due_date date;
  v_new_status text;
begin
  -- Get invoice details
  select total_amount, paid_amount, due_date
  into v_total_amount, v_paid_amount, v_due_date
  from fee_invoices
  where id = NEW.invoice_id;
  
  -- Recalculate paid amount
  select coalesce(sum(amount), 0)
  into v_paid_amount
  from fee_payments
  where invoice_id = NEW.invoice_id;
  
  -- Determine new status
  if v_paid_amount >= v_total_amount then
    v_new_status := 'paid';
  elsif v_paid_amount > 0 then
    v_new_status := 'partial';
  elsif v_due_date < current_date then
    v_new_status := 'overdue';
  else
    v_new_status := 'pending';
  end if;
  
  -- Update invoice
  update fee_invoices
  set 
    paid_amount = v_paid_amount,
    status = v_new_status,
    updated_at = now()
  where id = NEW.invoice_id;
  
  return NEW;
end;
$$;

drop trigger if exists fee_payments_update_invoice_status on fee_payments;
create trigger fee_payments_update_invoice_status
after insert or update or delete on fee_payments
for each row execute function update_invoice_status();

-- 16. Insert default fee categories for Pakistani schools
insert into fee_categories (school_id, name, code, description, display_order)
select 
  s.id,
  cat.name,
  cat.code,
  cat.description,
  cat.display_order
from schools s
cross join (
  values
    ('Tuition Fee', 'TUITION', 'Monthly/Quarterly/Yearly tuition fee', 1),
    ('Admission Fee', 'ADMISSION', 'One-time admission fee', 2),
    ('Security Deposit', 'SECURITY', 'Refundable security deposit', 3),
    ('Transport Fee', 'TRANSPORT', 'Monthly transport charges', 4),
    ('Library Fee', 'LIBRARY', 'Library and reading material charges', 5),
    ('Lab Fee', 'LAB', 'Science laboratory charges', 6),
    ('Sports Fee', 'SPORTS', 'Sports and physical education fee', 7),
    ('Exam Fee', 'EXAM', 'Examination and assessment fee', 8),
    ('Stationery Fee', 'STATIONERY', 'Books and stationery charges', 9),
    ('Development Fund', 'DEVELOPMENT', 'School development fund', 10),
    ('Computer Fee', 'COMPUTER', 'Computer lab and IT charges', 11),
    ('Activity Fee', 'ACTIVITY', 'Extra-curricular activities fee', 12),
    ('Medical Fee', 'MEDICAL', 'Medical and health services fee', 13),
    ('Uniform Fee', 'UNIFORM', 'School uniform charges', 14),
    ('Miscellaneous', 'MISC', 'Other miscellaneous charges', 99)
) as cat(name, code, description, display_order)
where not exists (
  select 1 from fee_categories 
  where school_id = s.id and name = cat.name
);

comment on table fee_categories is 'Fee categories for Pakistani schools (Tuition, Transport, etc.)';
comment on table fee_structures is 'Fee structure definitions with amounts and frequencies';
comment on table fee_invoices is 'Fee invoices/challans generated for students';
comment on table fee_invoice_items is 'Line items in fee invoices';
comment on table fee_payments is 'Fee payments linked to invoices and transactions';
comment on table fee_waivers is 'Fee waivers and concessions for students';
comment on function generate_fee_invoice_number is 'Generate unique invoice number in format INV-YYYY-MM-XXXXX';
comment on function calculate_invoice_total is 'Calculate total invoice amount with discounts and late fees';
comment on function get_student_fee_summary is 'Get comprehensive fee summary for a student';

