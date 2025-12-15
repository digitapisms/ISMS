#!/usr/bin/env python3
"""
Supabase SQL Query Runner (Python version)

Usage:
    python scripts/run_sql.py "SELECT * FROM schools LIMIT 5;"
    python scripts/run_sql.py --file path/to/query.sql

Requires:
    - SUPABASE_URL and SUPABASE_DB_PASSWORD in .env file
    - pip install psycopg2-binary python-dotenv
    - Or use Supabase connection string
"""

import os
import sys
import argparse
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

# Load environment variables
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD', '')
SUPABASE_DB_HOST = os.getenv('SUPABASE_DB_HOST', '')
SUPABASE_DB_NAME = os.getenv('SUPABASE_DB_NAME', 'db')
SUPABASE_DB_USER = os.getenv('SUPABASE_DB_USER', 'postgres')
SUPABASE_DB_PORT = os.getenv('SUPABASE_DB_PORT', '5432')

def get_connection_string():
    """Build PostgreSQL connection string from environment variables"""
    # Try to extract from SUPABASE_URL if it's a full connection string
    if SUPABASE_URL.startswith('postgresql://') or SUPABASE_URL.startswith('postgres://'):
        return SUPABASE_URL
    
    # Build from individual components
    if not all([SUPABASE_DB_HOST, SUPABASE_DB_NAME, SUPABASE_DB_USER, SUPABASE_DB_PASSWORD]):
        print("❌ Error: Database connection details not found in .env")
        print("\nRequired variables:")
        print("  - SUPABASE_URL (postgresql://...) OR")
        print("  - SUPABASE_DB_HOST, SUPABASE_DB_NAME, SUPABASE_DB_USER, SUPABASE_DB_PASSWORD")
        sys.exit(1)
    
    return f"postgresql://{SUPABASE_DB_USER}:{SUPABASE_DB_PASSWORD}@{SUPABASE_DB_HOST}:{SUPABASE_DB_PORT}/{SUPABASE_DB_NAME}"

def run_sql(query, output_format='table'):
    """Execute SQL query and return results"""
    conn_string = get_connection_string()
    
    try:
        print('🔍 Connecting to Supabase database...\n')
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print('📝 Executing query:\n')
        print(query)
        print('\n---\n')
        
        cursor.execute(query)
        
        # Check if query returns results
        if cursor.description:
            results = cursor.fetchall()
            print(f'✅ Query executed successfully! ({len(results)} rows)\n')
            
            if results:
                # Print as table
                if output_format == 'table':
                    # Get column names
                    columns = [desc[0] for desc in cursor.description]
                    print(' | '.join(columns))
                    print('-' * (sum(len(str(col)) for col in columns) + len(columns) * 3))
                    
                    for row in results:
                        print(' | '.join(str(row[col]) for col in columns))
                else:
                    # Print as JSON
                    import json
                    print(json.dumps([dict(row) for row in results], indent=2, default=str))
            else:
                print('(No rows returned)')
        else:
            # DDL/DML query
            conn.commit()
            print('✅ Query executed successfully!')
            print(f'Rows affected: {cursor.rowcount}')
        
        cursor.close()
        conn.close()
        
    except psycopg2.Error as e:
        print(f'❌ Database error: {e}')
        sys.exit(1)
    except Exception as e:
        print(f'❌ Error: {e}')
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Run SQL queries against Supabase database')
    parser.add_argument('query', nargs='?', help='SQL query to execute')
    parser.add_argument('--file', '-f', help='Read query from file')
    parser.add_argument('--format', choices=['table', 'json'], default='table', help='Output format')
    
    args = parser.parse_args()
    
    if args.file:
        file_path = Path(__file__).parent.parent / args.file
        if not file_path.exists():
            print(f'❌ Error: File not found: {file_path}')
            sys.exit(1)
        query = file_path.read_text()
    elif args.query:
        query = args.query
    else:
        parser.print_help()
        sys.exit(0)
    
    run_sql(query, args.format)

if __name__ == '__main__':
    main()

