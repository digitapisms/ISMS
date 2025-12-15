# SQL Query Runner for Supabase

This directory contains scripts to run SQL queries directly against your Supabase database from the command line.

## Options

### Option 1: Supabase CLI (Recommended)

The easiest way is to use Supabase CLI:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Run SQL file
supabase db execute --file path/to/query.sql

# Or run SQL directly
supabase db execute "SELECT * FROM schools LIMIT 5;"
```

### Option 2: Python Script (Direct PostgreSQL Connection)

**Prerequisites:**
```bash
pip install psycopg2-binary python-dotenv
```

**Setup `.env` file:**
```env
# Option A: Full connection string
SUPABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres

# Option B: Individual components
SUPABASE_DB_HOST=db.xxxxx.supabase.co
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=your_password
SUPABASE_DB_PORT=5432
```

**Usage:**
```bash
# Run a query
python scripts/run_sql.py "SELECT * FROM schools LIMIT 5;"

# Run from file
python scripts/run_sql.py --file CREATE_PAYMENT_INTEGRATION_SCHEMA.sql

# Output as JSON
python scripts/run_sql.py "SELECT * FROM schools;" --format json
```

### Option 3: Node.js Script (Using Supabase REST API)

**Prerequisites:**
```bash
npm install @supabase/supabase-js dotenv
```

**Setup `.env` file:**
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**Usage:**
```bash
node scripts/run_sql.js "SELECT * FROM schools LIMIT 5;"
node scripts/run_sql.js --file path/to/query.sql
```

**Note:** This method has limitations - it works best for SELECT queries via REST API. For DDL/DML, use Python script or Supabase CLI.

### Option 4: Direct psql Connection

If you have PostgreSQL client installed:

```bash
# Get connection string from Supabase Dashboard > Settings > Database
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# Then run queries
\i path/to/query.sql
```

## Getting Database Credentials

1. Go to Supabase Dashboard
2. Select your project
3. Go to **Settings** > **Database**
4. Find **Connection string** or **Connection pooling**
5. Copy the connection details

## Example Queries

```sql
-- Check if table exists
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'schools'
);

-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

## Security Notes

⚠️ **Important:**
- Never commit `.env` files with real credentials
- Use service role key only in secure environments
- For production, use connection pooling with limited permissions
- Consider using Supabase CLI with proper authentication

## Troubleshooting

**Connection refused:**
- Check if your IP is allowed in Supabase Dashboard > Settings > Database > Connection Pooling
- Verify connection string format

**Authentication failed:**
- Verify password is correct
- Check if using correct user (postgres vs service_role)

**Permission denied:**
- Some queries require service_role key
- Check RLS policies if querying user data

