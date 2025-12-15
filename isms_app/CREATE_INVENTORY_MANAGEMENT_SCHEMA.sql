-- Inventory Management System Schema
-- Manages school assets, supplies, and equipment

-- Inventory Categories Table
CREATE TABLE IF NOT EXISTS inventory_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_category_id UUID REFERENCES inventory_categories(id), -- For subcategories
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(school_id, name)
);

-- Inventory Items Table
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    category_id UUID REFERENCES inventory_categories(id),
    item_code VARCHAR(100) NOT NULL, -- Unique item code
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit VARCHAR(50) NOT NULL DEFAULT 'piece', -- piece, box, kg, liter, etc.
    current_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
    minimum_quantity DECIMAL(10, 2) DEFAULT 0, -- Reorder threshold
    maximum_quantity DECIMAL(10, 2),
    unit_price DECIMAL(10, 2),
    total_value DECIMAL(12, 2), -- current_quantity * unit_price
    location VARCHAR(255), -- Storage location
    supplier_name VARCHAR(255),
    supplier_contact TEXT,
    condition_status VARCHAR(50) DEFAULT 'good', -- good, fair, poor, damaged
    is_consumable BOOLEAN DEFAULT TRUE, -- Consumable vs durable asset
    is_active BOOLEAN DEFAULT TRUE,
    last_restocked_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(school_id, item_code)
);

-- Inventory Transactions Table
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL, -- purchase, issue, return, adjustment, damage, loss
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(12, 2),
    reference_number VARCHAR(100), -- Invoice number, requisition number, etc.
    issued_to_user_id UUID REFERENCES users(id), -- Who received the item
    issued_to_class_id INTEGER REFERENCES classes(id), -- Which class received
    reason TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    processed_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Inventory Requisitions Table (for requesting items)
CREATE TABLE IF NOT EXISTS inventory_requisitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    requisition_number VARCHAR(100) NOT NULL,
    requested_by UUID NOT NULL REFERENCES users(id),
    requested_for_class_id INTEGER REFERENCES classes(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, fulfilled, cancelled
    requested_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    required_date DATE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    fulfilled_by UUID REFERENCES users(id),
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(school_id, requisition_number)
);

-- Inventory Requisition Items Table
CREATE TABLE IF NOT EXISTS inventory_requisition_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requisition_id UUID NOT NULL REFERENCES inventory_requisitions(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES inventory_items(id),
    requested_quantity DECIMAL(10, 2) NOT NULL,
    approved_quantity DECIMAL(10, 2),
    issued_quantity DECIMAL(10, 2),
    unit VARCHAR(50),
    purpose TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_inventory_categories_school ON inventory_categories(school_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_school ON inventory_items(school_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON inventory_items(category_id);
CREATE INDEX IF NOT EXISTS idx_inventory_items_code ON inventory_items(item_code);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item ON inventory_transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_school ON inventory_transactions(school_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_date ON inventory_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_inventory_requisitions_school ON inventory_requisitions(school_id);
CREATE INDEX IF NOT EXISTS idx_inventory_requisitions_status ON inventory_requisitions(status);
CREATE INDEX IF NOT EXISTS idx_inventory_requisition_items_requisition ON inventory_requisition_items(requisition_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_inventory_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_categories_updated_at
    BEFORE UPDATE ON inventory_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_categories_updated_at();

CREATE OR REPLACE FUNCTION update_inventory_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_items_updated_at
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_items_updated_at();

CREATE OR REPLACE FUNCTION update_inventory_requisitions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_requisitions_updated_at
    BEFORE UPDATE ON inventory_requisitions
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_requisitions_updated_at();

-- Trigger to update inventory quantity on transaction
CREATE OR REPLACE FUNCTION update_inventory_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_type = 'purchase' OR NEW.transaction_type = 'return' THEN
        UPDATE inventory_items
        SET current_quantity = current_quantity + NEW.quantity,
            last_restocked_at = CASE WHEN NEW.transaction_type = 'purchase' THEN NEW.transaction_date ELSE last_restocked_at END,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    ELSIF NEW.transaction_type = 'issue' OR NEW.transaction_type = 'damage' OR NEW.transaction_type = 'loss' THEN
        UPDATE inventory_items
        SET current_quantity = current_quantity - NEW.quantity,
            last_used_at = NEW.transaction_date,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    ELSIF NEW.transaction_type = 'adjustment' THEN
        -- For adjustments, quantity can be positive or negative
        UPDATE inventory_items
        SET current_quantity = current_quantity + NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_quantity_trigger
    AFTER INSERT ON inventory_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_quantity();

-- Function to calculate total value
CREATE OR REPLACE FUNCTION calculate_inventory_value()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.unit_price IS NOT NULL THEN
        NEW.total_value = NEW.current_quantity * NEW.unit_price;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_inventory_value_trigger
    BEFORE INSERT OR UPDATE ON inventory_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_inventory_value();

-- RLS Policies
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_requisition_items ENABLE ROW LEVEL SECURITY;

-- Policies for inventory_categories
CREATE POLICY inventory_categories_select_school ON inventory_categories
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_categories.school_id
        )
    );

CREATE POLICY inventory_categories_insert_school ON inventory_categories
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_categories.school_id
            AND users.role IN ('admin', 'principal', 'staff')
        )
    );

-- Similar policies for other inventory tables...
CREATE POLICY inventory_items_select_school ON inventory_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_items.school_id
        )
    );

CREATE POLICY inventory_items_insert_school ON inventory_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_items.school_id
            AND users.role IN ('admin', 'principal', 'staff')
        )
    );

CREATE POLICY inventory_transactions_select_school ON inventory_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_transactions.school_id
        )
    );

CREATE POLICY inventory_transactions_insert_school ON inventory_transactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.school_id = inventory_transactions.school_id
            AND users.role IN ('admin', 'principal', 'staff', 'teacher')
        )
    );

