# Tool to find redundant tables, functions, indexes

if [ -z "$1" ]; then
   echo "Usage: $0 <dbname>"
   echo
   exit 1
fi

db=$1

echo List of \(Possibly\) Redundant Tables
echo

SQL=$(cat<<EOF
    SELECT
    schemaname,
    relname,
    seq_scan,
    idx_scan,
    n_tup_ins + n_tup_upd + n_tup_del AS writes
    FROM pg_stat_user_tables WHERE seq_scan = 0
    AND (idx_scan = 0 or idx_scan IS NULL);
EOF
)

psql -c "$SQL" $db

echo List of Duplicate Indexes
echo

SQL=$(
       cat<<'EOF'
       SELECT PG_SIZE_PRETTY(SUM(PG_RELATION_SIZE(idx))::bigint) as size,
       (array_agg(idx))[1] as idx1, (array_agg(idx))[2] as idx2,
       (array_agg(idx))[3] as idx3, (array_agg(idx))[4] as idx4
       FROM (
	SELECT indexrelid::regclass as idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'||
        COALESCE(indexprs::text,'')||E'\n' || COALESCE(indpred::text,'')) as key FROM pg_index) sub
        GROUP BY key HAVING count(*)>1
	ORDER BY SUM(PG_RELATION_SIZE(idx)) DESC;
EOF
)

psql -c "$SQL" $db

echo List of \(Possibly\) Redundant Indexes
echo

SQL=$(cat<<EOF
    SELECT
    ui.schemaname,
    ui.relname AS table_name,
    ui.indexrelname AS index_name,
    ui.idx_scan,
    pg_size_pretty(pg_relation_size(ui.indexrelid)) AS index_size
    FROM pg_stat_user_indexes ui
    JOIN pg_index i
    ON ui.indexrelid = i.indexrelid
    WHERE ui.idx_scan = 0
    AND NOT i.indisprimary
    AND NOT i.indisunique
    AND NOT EXISTS (
      SELECT 1
      FROM pg_constraint c
      WHERE c.conindid = ui.indexrelid
    )
    ORDER BY pg_relation_size(ui.indexrelid) DESC;
EOF
)

psql -c "$SQL" $db

echo List of \(Possibly\) Redundant Functions
echo

SQL=$(cat<<EOF
    SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    COALESCE(s.calls, 0) AS calls
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    LEFT JOIN pg_stat_user_functions s
    ON p.oid = s.funcid
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND COALESCE(s.calls, 0) = 0
    ORDER BY schema_name, function_name;
EOF
)

psql -c "$SQL" $db
