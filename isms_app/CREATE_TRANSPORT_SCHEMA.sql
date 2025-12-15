-- Transport Management System Schema
-- Designed for Pakistani schools with multiple pickup points, helpers, and fitness certificates

-- ============================================================
-- VEHICLES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS vehicles (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  vehicle_number VARCHAR(50) NOT NULL,
  vehicle_type VARCHAR(50) DEFAULT 'bus', -- bus, van, car, coaster
  make VARCHAR(100),
  model VARCHAR(100),
  year INTEGER,
  color VARCHAR(50),
  capacity INTEGER NOT NULL,
  registration_number VARCHAR(100) UNIQUE,
  chassis_number VARCHAR(100),
  engine_number VARCHAR(100),
  fitness_certificate_number VARCHAR(100),
  fitness_certificate_expiry DATE,
  insurance_number VARCHAR(100),
  insurance_expiry DATE,
  route_id INTEGER REFERENCES routes(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'active', -- active, maintenance, retired
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  current_value DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, vehicle_number)
);

-- ============================================================
-- ROUTES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS routes (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  route_name VARCHAR(255) NOT NULL,
  route_number VARCHAR(50),
  start_location VARCHAR(255) NOT NULL,
  end_location VARCHAR(255) NOT NULL,
  total_distance DECIMAL(10,2), -- in kilometers
  estimated_time INTEGER, -- in minutes
  vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
  helper_id UUID REFERENCES users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  morning_pickup_time TIME,
  morning_dropoff_time TIME,
  afternoon_pickup_time TIME,
  afternoon_dropoff_time TIME,
  transport_fee DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, route_name)
);

-- ============================================================
-- ROUTE STOPS TABLE (Multiple pickup/drop points per route)
-- ============================================================
CREATE TABLE IF NOT EXISTS route_stops (
  id SERIAL PRIMARY KEY,
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  route_id INTEGER NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  stop_name VARCHAR(255) NOT NULL,
  stop_address TEXT,
  stop_sequence INTEGER NOT NULL, -- Order of stops on route
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  estimated_time_from_start INTEGER, -- minutes from route start
  is_pickup_point BOOLEAN DEFAULT true,
  is_dropoff_point BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(route_id, stop_sequence)
);

-- ============================================================
-- DRIVERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  full_name VARCHAR(255) NOT NULL,
  cnic VARCHAR(20) UNIQUE,
  license_number VARCHAR(100) NOT NULL,
  license_type VARCHAR(50) DEFAULT 'PSV', -- PSV, LTV, HTV
  license_expiry DATE NOT NULL,
  phone_number VARCHAR(20),
  alternate_phone VARCHAR(20),
  address TEXT,
  emergency_contact VARCHAR(255),
  emergency_phone VARCHAR(20),
  experience_years INTEGER,
  date_of_joining DATE,
  salary DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'active', -- active, on_leave, terminated
  vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- HELPERS/ATTENDANTS TABLE (Common in Pakistani schools)
-- ============================================================
CREATE TABLE IF NOT EXISTS helpers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  full_name VARCHAR(255) NOT NULL,
  cnic VARCHAR(20) UNIQUE,
  phone_number VARCHAR(20),
  alternate_phone VARCHAR(20),
  address TEXT,
  emergency_contact VARCHAR(255),
  emergency_phone VARCHAR(20),
  date_of_joining DATE,
  salary DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'active', -- active, on_leave, terminated
  route_id INTEGER REFERENCES routes(id) ON DELETE SET NULL,
  vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TRANSPORT ASSIGNMENTS TABLE (Student-Route assignments)
-- ============================================================
CREATE TABLE IF NOT EXISTS transport_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  route_id INTEGER NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  pickup_stop_id INTEGER REFERENCES route_stops(id) ON DELETE SET NULL,
  dropoff_stop_id INTEGER REFERENCES route_stops(id) ON DELETE SET NULL,
  assignment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_until DATE,
  transport_fee DECIMAL(10,2),
  fee_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, waived
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, route_id, effective_from)
);

-- ============================================================
-- TRANSPORT ATTENDANCE TABLE (Daily bus attendance)
-- ============================================================
CREATE TABLE IF NOT EXISTS transport_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  route_id INTEGER NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  trip_type VARCHAR(50) DEFAULT 'morning', -- morning, afternoon, both
  pickup_status VARCHAR(50) DEFAULT 'present', -- present, absent, late
  dropoff_status VARCHAR(50) DEFAULT 'present', -- present, absent
  pickup_time TIME,
  dropoff_time TIME,
  marked_by UUID REFERENCES users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, route_id, attendance_date, trip_type)
);

-- ============================================================
-- TRANSPORT FEES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS transport_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES transport_assignments(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  route_id INTEGER NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  fee_month DATE NOT NULL, -- First day of month
  amount DECIMAL(10,2) NOT NULL,
  due_date DATE,
  paid_date DATE,
  payment_method VARCHAR(50), -- cash, easypaisa, jazzcash, bank_transfer, card
  payment_reference VARCHAR(255),
  challan_number VARCHAR(100),
  voucher_number VARCHAR(100),
  status VARCHAR(50) DEFAULT 'pending', -- pending, paid, overdue, waived
  waived_by UUID REFERENCES users(id),
  waived_at TIMESTAMPTZ,
  waiver_reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- VEHICLE MAINTENANCE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS vehicle_maintenance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  maintenance_type VARCHAR(50) NOT NULL, -- service, repair, inspection, fitness_renewal, insurance_renewal
  maintenance_date DATE NOT NULL,
  next_service_date DATE,
  cost DECIMAL(10,2),
  service_provider VARCHAR(255),
  description TEXT,
  parts_replaced TEXT,
  mileage_at_service INTEGER,
  performed_by UUID REFERENCES users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_vehicles_school_id ON vehicles(school_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_routes_school_id ON routes(school_id);
CREATE INDEX IF NOT EXISTS idx_routes_vehicle_id ON routes(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_route_id ON route_stops(route_id);
CREATE INDEX IF NOT EXISTS idx_drivers_school_id ON drivers(school_id);
CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_id ON drivers(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_helpers_school_id ON helpers(school_id);
CREATE INDEX IF NOT EXISTS idx_helpers_route_id ON helpers(route_id);
CREATE INDEX IF NOT EXISTS idx_transport_assignments_student_id ON transport_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_transport_assignments_route_id ON transport_assignments(route_id);
CREATE INDEX IF NOT EXISTS idx_transport_attendance_student_id ON transport_attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_transport_attendance_date ON transport_attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_transport_fees_student_id ON transport_fees(student_id);
CREATE INDEX IF NOT EXISTS idx_transport_fees_status ON transport_fees(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_maintenance_vehicle_id ON vehicle_maintenance(vehicle_id);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_helpers_updated_at BEFORE UPDATE ON helpers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transport_assignments_updated_at BEFORE UPDATE ON transport_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transport_fees_updated_at BEFORE UPDATE ON transport_fees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicle_maintenance_updated_at BEFORE UPDATE ON vehicle_maintenance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

