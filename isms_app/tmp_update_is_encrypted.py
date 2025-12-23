import psycopg
conn_params = dict(
    host='aws-1-ap-northeast-1.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.aduazpxwhvosrhgusrhn',
    password='Tiger@1979###',
    sslmode='require',
)
sql = [
    "ALTER TABLE public.system_settings ADD COLUMN IF NOT EXISTS is_encrypted boolean NOT NULL DEFAULT false;",
    "UPDATE public.system_settings SET is_encrypted = COALESCE(is_encrypted, false);",
    "NOTIFY pgrst, 'reload schema';",
]
with psycopg.connect(**conn_params) as conn:
    with conn.cursor() as cur:
        for stmt in sql:
            cur.execute(stmt)
        conn.commit()
    with conn.cursor() as cur:
        cur.execute("""
            select column_name, data_type, is_nullable, column_default
            from information_schema.columns
            where table_schema = 'public' and table_name = 'system_settings'
            order by column_name;
        """)
        cols = cur.fetchall()
        print('Columns:')
        for row in cols:
            print(row)
    with conn.cursor() as cur:
        cur.execute("select setting_key, is_encrypted from public.system_settings limit 5;")
        rows = cur.fetchall()
        print('Sample rows:')
        for r in rows:
            print(r)
print('Done')
