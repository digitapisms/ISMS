param(
  [string]$ConnectionString = "postgres://postgres:postgres@localhost:5432/isms",
  [string]$MigrationsDir = "supabase\migrations"
)

$uri = [Uri]$ConnectionString
$dbName = $uri.AbsolutePath.TrimStart('/')
$adminConn = $ConnectionString.Replace("/$dbName","/postgres")

psql "$adminConn" -c "CREATE DATABASE $dbName" 2>$null

Get-ChildItem -Path $MigrationsDir -Filter *.sql | Sort-Object Name | ForEach-Object {
  psql "$ConnectionString" -f $_.FullName
}
