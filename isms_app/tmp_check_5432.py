import psycopg
conn_params = dict(
    host='aws-1-ap-northeast-1.pooler.supabase.com',
    port=5432,
    dbname='postgres',
    user='postgres.aduazpxwhvosrhgusrhn',
    password='Tiger@1979###',
    sslmode='require',
)
with psycopg.connect(**conn_params) as conn:
    with conn.cursor() as cur:
        cur.execute("""
            select column_name, data_type, is_nullable, column_default
            from information_schema.columns
            where table_schema = 'public' and table_name = 'system_settings'
            order by column_name;
        """)
        cols = cur.fetchall()
        print('Columns 5432:')
        for row in cols:
            print(row)
    with conn.cursor() as cur:
        cur.execute("select setting_key, is_encrypted from public.system_settings where setting_key like 'ZOOM%';")
        rows = cur.fetchall()
        print('Zoom rows 5432:')
        for r in rows:
            print(r)
print('Done')
