-- Enable Bank Transfer payment option for all users (schools and super admin)
-- This ensures bank_transfer is always available without requiring API configuration

-- Ensure bank_transfer is active in payment_providers table
INSERT INTO payment_providers (provider_key, display_name, provider_type, is_active, metadata_schema)
VALUES (
  'bank_transfer',
  'Bank Transfer',
  'bank_transfer',
  true,
  '{"fields":["account_title","account_number","iban","bank_name","branch_code"]}'
)
ON CONFLICT (provider_key) DO UPDATE SET
  is_active = true,
  display_name = EXCLUDED.display_name,
  provider_type = EXCLUDED.provider_type,
  metadata_schema = EXCLUDED.metadata_schema,
  updated_at = now();

-- Ensure bank_transfer is active in payment_gateway_configs table (if it exists)
INSERT INTO payment_gateway_configs (provider, is_active, is_test_mode, supported_currencies)
VALUES ('bank_transfer', true, false, '{"PKR", "USD", "EUR", "GBP"}')
ON CONFLICT (provider) DO UPDATE SET
  is_active = true,
  updated_at = now();

-- Grant access to bank_transfer for all authenticated users
-- RLS policies should already allow this, but ensure bank_transfer is accessible
