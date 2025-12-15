-- ===========================================================
-- Finance & Payments Module Database Schema
-- ILMA Cloud - Complete Payment System
-- ===========================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================================================
-- 1. SUBSCRIPTION PLANS TABLE (Super Admin managed)
-- ===========================================================
CREATE TABLE subscription_plans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- Basic, Standard, Enterprise
    description TEXT,
    price_per_month DECIMAL(10,2) NOT NULL,
    price_per_quarter DECIMAL(10,2),
    price_per_half_year DECIMAL(10,2),
    price_per_year DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'PKR',
    max_students INTEGER,
    max_teachers INTEGER,
    max_storage_mb INTEGER,
    features JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 2. SCHOOL SUBSCRIPTIONS TABLE
-- ===========================================================
CREATE TABLE school_subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id),
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('monthly', 'quarterly', 'half_yearly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'pending', 'suspended', 'cancelled', 'expired')),
    next_billing_date DATE,
    payment_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 3. SCHOOL INVOICES TABLE (SaaS billing)
-- ===========================================================
CREATE TABLE school_invoices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    subscription_id UUID REFERENCES school_subscriptions(id),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'PKR',
    status VARCHAR(20) DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid', 'overdue', 'expired')),
    payment_method VARCHAR(50),
    paid_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 4. PAYMENT TRANSACTIONS TABLE (All payments)
-- ===========================================================
CREATE TABLE payment_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    invoice_id UUID, -- Can reference school_invoices or student_invoices
    invoice_type VARCHAR(20) CHECK (invoice_type IN ('school', 'student')),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'PKR',
    payment_method VARCHAR(50) NOT NULL,
    payment_provider VARCHAR(50), -- stripe, jazzcash, easypaisa, etc.
    transaction_id VARCHAR(100), -- Gateway transaction ID
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    gateway_response JSONB,
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 5. STUDENT INVOICES TABLE
-- ===========================================================
CREATE TABLE student_invoices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    month VARCHAR(7), -- YYYY-MM format
    subtotal DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    outstanding_amount DECIMAL(10,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    currency VARCHAR(3) DEFAULT 'PKR',
    status VARCHAR(20) DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid', 'overdue')),
    payment_terms TEXT,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 6. STUDENT FEE ITEMS TABLE (Line items for invoices)
-- ===========================================================
CREATE TABLE student_fee_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    invoice_id UUID REFERENCES student_invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL, -- tuition, transport, exam, activity, etc.
    description VARCHAR(255) NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    is_taxable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 7. PAYMENT METHODS TABLE (Configurable payment options)
-- ===========================================================
CREATE TABLE payment_methods (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    method_type VARCHAR(50) NOT NULL CHECK (method_type IN ('card', 'bank_transfer', 'jazzcash', 'easypaisa', 'cash')),
    provider_name VARCHAR(100), -- stripe, payfast, jazzcash merchant, etc.
    is_active BOOLEAN DEFAULT TRUE,
    config JSONB DEFAULT '{}', -- API keys, merchant IDs, etc.
    fee_percentage DECIMAL(5,2) DEFAULT 0,
    min_amount DECIMAL(10,2) DEFAULT 0,
    max_amount DECIMAL(10,2),
    supported_currencies VARCHAR(10)[] DEFAULT '{PKR}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 8. BANK TRANSFER RECEIPTS TABLE
-- ===========================================================
CREATE TABLE bank_transfer_receipts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    transaction_id UUID REFERENCES payment_transactions(id),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50),
    transfer_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    receipt_image_url TEXT,
    reference_number VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 9. PAYMENT GATEWAY CONFIG TABLE
-- ===========================================================
CREATE TABLE payment_gateway_configs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider VARCHAR(50) NOT NULL UNIQUE, -- stripe, payfast, jazzcash, easypaisa
    is_active BOOLEAN DEFAULT FALSE,
    is_test_mode BOOLEAN DEFAULT TRUE,
    api_key TEXT,
    api_secret TEXT,
    webhook_secret TEXT,
    merchant_id VARCHAR(100),
    base_url TEXT,
    supported_currencies VARCHAR(10)[] DEFAULT '{PKR}',
    config JSONB DEFAULT '{}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- 10. INVOICE REMINDERS TABLE
-- ===========================================================
CREATE TABLE invoice_reminders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    invoice_id UUID NOT NULL,
    invoice_type VARCHAR(20) CHECK (invoice_type IN ('school', 'student')),
    reminder_type VARCHAR(20) CHECK (reminder_type IN ('upcoming', 'due', 'overdue')),
    sent_via VARCHAR(20) DEFAULT 'email' CHECK (sent_via IN ('email', 'sms', 'in_app')),
    sent_to VARCHAR(255), -- email or phone number
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message TEXT,
    is_delivered BOOLEAN DEFAULT FALSE,
    delivery_status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================================
-- INDEXES FOR PERFORMANCE
-- ===========================================================
CREATE INDEX idx_school_invoices_school_id ON school_invoices(school_id);
CREATE INDEX idx_school_invoices_status ON school_invoices(status);
CREATE INDEX idx_school_invoices_due_date ON school_invoices(due_date);
CREATE INDEX idx_student_invoices_student_id ON student_invoices(student_id);
CREATE INDEX idx_student_invoices_status ON student_invoices(status);
CREATE INDEX idx_payment_transactions_invoice ON payment_transactions(invoice_id, invoice_type);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_created ON payment_transactions(created_at);
CREATE INDEX idx_bank_transfers_status ON bank_transfer_receipts(status);
CREATE INDEX idx_subscription_school ON school_subscriptions(school_id);

-- ===========================================================
-- RLS (Row Level Security) Policies
-- ===========================================================
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fee_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transfer_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_gateway_configs ENABLE ROW LEVEL SECURITY;

-- Super Admin can manage all finance data
CREATE POLICY "Super Admin full access" ON subscription_plans FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Super Admin full access" ON school_subscriptions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Super Admin full access" ON school_invoices FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Super Admin full access" ON payment_transactions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Super Admin full access" ON payment_gateway_configs FOR ALL USING (auth.role() = 'authenticated');

-- Schools can only see their own data
CREATE POLICY "School view own subscriptions" ON school_subscriptions FOR SELECT USING (school_id IN (SELECT id FROM schools WHERE owner_id = auth.uid()));
CREATE POLICY "School view own invoices" ON school_invoices FOR SELECT USING (school_id IN (SELECT id FROM schools WHERE owner_id = auth.uid()));
CREATE POLICY "School view own transactions" ON payment_transactions FOR SELECT USING (school_id IN (SELECT id FROM schools WHERE owner_id = auth.uid()));
CREATE POLICY "School manage own payment methods" ON payment_methods FOR ALL USING (school_id IN (SELECT id FROM schools WHERE owner_id = auth.uid()));

-- ===========================================================
-- FUNCTIONS AND TRIGGERS
-- ===========================================================

-- Function to generate invoice numbers
CREATE OR REPLACE FUNCTION generate_invoice_number(prefix TEXT, entity_type TEXT)
RETURNS TEXT AS $$
DECLARE
    next_seq INTEGER;
    new_number TEXT;
BEGIN
    IF entity_type = 'school' THEN
        SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '^INV-SCH-([0-9]+)$') AS INTEGER)), 0) + 1 
        INTO next_seq 
        FROM school_invoices;
        new_number := prefix || 'SCH-' || LPAD(next_seq::TEXT, 6, '0');
    ELSE
        SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '^INV-STU-([0-9]+)$') AS INTEGER)), 0) + 1 
        INTO next_seq 
        FROM student_invoices;
        new_number := prefix || 'STU-' || LPAD(next_seq::TEXT, 6, '0');
    END IF;
    
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Function to update invoice status based on payments
CREATE OR REPLACE FUNCTION update_invoice_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_type = 'school' THEN
        UPDATE school_invoices 
        SET status = 'paid', paid_at = NEW.processed_at, payment_method = NEW.payment_method
        WHERE id = NEW.invoice_id AND NEW.status = 'completed';
    ELSIF NEW.invoice_type = 'student' THEN
        UPDATE student_invoices 
        SET paid_amount = COALESCE(paid_amount, 0) + NEW.amount,
            status = CASE 
                WHEN (paid_amount + NEW.amount) >= total_amount THEN 'paid'
                WHEN (paid_amount + NEW.amount) > 0 THEN 'partial'
                ELSE 'unpaid'
            END
        WHERE id = NEW.invoice_id AND NEW.status = 'completed';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update invoice status on payment completion
CREATE TRIGGER trigger_update_invoice_status
    AFTER INSERT OR UPDATE ON payment_transactions
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION update_invoice_status();

-- Function to check for overdue invoices
CREATE OR REPLACE FUNCTION check_overdue_invoices()
RETURNS void AS $$
BEGIN
    -- Update school invoices
    UPDATE school_invoices 
    SET status = 'overdue' 
    WHERE status = 'unpaid' AND due_date < CURRENT_DATE;
    
    -- Update student invoices
    UPDATE student_invoices 
    SET status = 'overdue' 
    WHERE status = 'unpaid' AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================
-- SAMPLE DATA
-- ===========================================================
INSERT INTO subscription_plans (
    name, description, price_per_month, price_per_quarter, 
    price_per_half_year, price_per_year, max_students, max_teachers,
    features, is_active, is_public
) VALUES 
('Basic', 'For small schools and startups', 5000, 13500, 25000, 48000, 100, 10, 
 '{"online_classes": true, "attendance": true, "basic_reports": true}', true, true),
('Standard', 'For growing schools', 8000, 21600, 40000, 76800, 500, 30, 
 '{"online_classes": true, "attendance": true, "advanced_reports": true, "sms_integration": true}', true, true),
('Enterprise', 'For large institutions', 15000, 40500, 75000, 144000, 2000, 100, 
 '{"online_classes": true, "attendance": true, "advanced_reports": true, "sms_integration": true, "custom_domain": true, "priority_support": true}', true, true);

INSERT INTO payment_gateway_configs (
    provider, is_active, is_test_mode, supported_currencies
) VALUES 
('stripe', true, true, '{"PKR", "USD"}'),
('jazzcash', true, true, '{"PKR"}'),
('easypaisa', true, true, '{"PKR"}'),
('payfast', false, true, '{"PKR", "USD"}');