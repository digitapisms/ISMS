import psycopg
conn_params = dict(
    host='aws-1-ap-northeast-1.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.aduazpxwhvosrhgusrhn',
    password='Tiger@1979###',
    sslmode='require',
)
with psycopg.connect(**conn_params) as conn:
    with conn.cursor() as cur:
        cur.execute("select current_database(), current_user, current_schemas(true);")
        print(cur.fetchone())
print('done')
