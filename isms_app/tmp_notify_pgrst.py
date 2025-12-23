import psycopg
conn_params = dict(
    host='aws-1-ap-northeast-1.pooler.supabase.com',
    port=5432,
    dbname='postgres',
    user='postgres.aduazpxwhvosrhgusrhn',
    password='Tiger@1979###',
    sslmode='require',
)
sql = [
    "NOTIFY pgrst, 'reload schema';",
]
with psycopg.connect(**conn_params) as conn:
    with conn.cursor() as cur:
        for stmt in sql:
            cur.execute(stmt)
        conn.commit()
print('notify sent on 5432')
