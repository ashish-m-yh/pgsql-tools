
# Tool to list largest tables and schemas in a DB

if [ -z "$1" ]; then
   echo "Usage: $0 <dbname>"
   echo
   exit 1
fi

db=$1

echo
echo View Largest Tables
echo

psql -c "SELECT table_name, PG_SIZE_PRETTY(PG_TOTAL_RELATION_SIZE(QUOTE_IDENT(table_name))), PG_TOTAL_RELATION_SIZE(QUOTE_IDENT(table_name))
FROM information_schema.tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY 3 DESC LIMIT 10;" $db

echo
echo View Largest Schemas
echo

SQL=$(cat<<EOF

WITH
schemas AS (
SELECT schemaname AS name, SUM(PG_RELATION_SIZE(QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(tablename)))::bigint AS size FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') GROUP BY schemaname
),

db AS (
    SELECT pg_database_size(current_database()) AS size
)

SELECT schemas.name, PG_SIZE_PRETTY(schemas.size) AS absolute_size, schemas.size::float / (SELECT size FROM db)  * 100 AS relative_size FROM schemas ORDER BY relative_size DESC;
EOF
)

psql -c "$SQL" $db

SQL=$(cat<<EOF

WITH index_stats AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS index_name,
        pg_relation_size(c.oid) AS index_size,
        s.idx_scan
    FROM pg_class c
    JOIN pg_index i ON i.indexrelid = c.oid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_stat_user_indexes s ON s.indexrelid = c.oid
    WHERE c.relkind = 'i' and c.relname !~ 'pg_' AND c.relname !~ '_pkey'
)
SELECT
    schema_name,
    index_name,
    pg_size_pretty(index_size) AS index_size
FROM index_stats 
ORDER BY index_size DESC;
EOF
)

echo
echo View Largest Indexes 
echo
psql -c "$SQL" $db
