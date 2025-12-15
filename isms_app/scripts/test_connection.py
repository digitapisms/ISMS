#!/usr/bin/env python3
"""
Quick connection test script for Supabase database
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

def test_connection():
    """Test database connection"""
    SUPABASE_URL = os.getenv('SUPABASE_URL', '')
    SUPABASE_DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD', '')
    SUPABASE_DB_HOST = os.getenv('SUPABASE_DB_HOST', '')
    SUPABASE_DB_NAME = os.getenv('SUPABASE_DB_NAME', 'db')
    SUPABASE_DB_USER = os.getenv('SUPABASE_DB_USER', 'postgres')
    SUPABASE_DB_PORT = os.getenv('SUPABASE_DB_PORT', '5432')
    
    if SUPABASE_URL.startswith('postgresql://') or SUPABASE_URL.startswith('postgres://'):
        conn_string = SUPABASE_URL
    elif all([SUPABASE_DB_HOST, SUPABASE_DB_NAME, SUPABASE_DB_USER, SUPABASE_DB_PASSWORD]):
        conn_string = f"postgresql://{SUPABASE_DB_USER}:{SUPABASE_DB_PASSWORD}@{SUPABASE_DB_HOST}:{SUPABASE_DB_PORT}/{SUPABASE_DB_NAME}"
    else:
        print("❌ Error: Database connection details not found in .env")
        print("\nAdd to .env file:")
        print("  SUPABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres")
        print("  OR")
        print("  SUPABASE_DB_HOST=db.xxxxx.supabase.co")
        print("  SUPABASE_DB_NAME=postgres")
        print("  SUPABASE_DB_USER=postgres")
        print("  SUPABASE_DB_PASSWORD=your_password")
        sys.exit(1)
    
    try:
        print("🔍 Testing connection...")
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        # Test query
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print("✅ Connection successful!")
        print(f"📊 PostgreSQL version: {version.split(',')[0]}")
        
        # List tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"\n📋 Found {len(tables)} tables:")
        for table in tables[:10]:  # Show first 10
            print(f"   - {table[0]}")
        if len(tables) > 10:
            print(f"   ... and {len(tables) - 10} more")
        
        cursor.close()
        conn.close()
        
    except psycopg2.OperationalError as e:
        print(f"❌ Connection failed: {e}")
        print("\n💡 Tips:")
        print("   1. Check your connection string in .env")
        print("   2. Verify your IP is allowed in Supabase Dashboard")
        print("   3. Check if password is correct")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    test_connection()

