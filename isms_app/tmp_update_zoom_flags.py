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
    "UPDATE public.system_settings SET is_encrypted = true WHERE setting_key IN ('ZOOM_ACCOUNT_ID','ZOOM_CLIENT_ID','ZOOM_CLIENT_SECRET');"
]
with psycopg.connect(**conn_params) as conn:
    with conn.cursor() as cur:
        for stmt in sql:
            cur.execute(stmt)
        conn.commit()
    with conn.cursor() as cur:
        cur.execute("select setting_key, is_encrypted from public.system_settings where setting_key like 'ZOOM%';")
        rows = cur.fetchall()
        print('Zoom rows:')
        for r in rows:
            print(r)
print('Done')
