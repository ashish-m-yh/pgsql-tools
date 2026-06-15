if [ -z "$1" ]; then
   echo "Usage: $0 <dbname>"
   echo
   exit 1
fi

db=$1

SQL=$(cat<<EOF

SELECT
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(
        100.0 * n_dead_tup / NULLIF(n_live_tup, 0),
        2
    ) AS dead_pct,
    COALESCE(last_autovacuum, last_vacuum) AS last_vacuumed
    FROM pg_stat_user_tables
    WHERE n_live_tup > 0
    AND (
        COALESCE(last_autovacuum, last_vacuum) IS NULL
        OR COALESCE(last_autovacuum, last_vacuum) < now() - interval '3 days'
      )
    AND n_dead_tup > 10000 
    AND n_dead_tup::numeric / NULLIF(n_live_tup, 0) >= 0.5
    ORDER BY dead_pct DESC, n_dead_tup DESC;

EOF
)

psql -c "$SQL" $db
