-- Views, materialized views and dictionaries, with what each reads from and writes to, for comparing a design with
-- the service. One row per object. Names, engines and status only; no query text.
SELECT
    t.database AS database,
    t.name AS object,
    t.engine AS engine,
    -- Target of a materialized view with TO; empty for one with an inner table.
    if(t.engine = 'MaterializedView',
       replaceAll(extract(t.create_table_query, '^CREATE MATERIALIZED VIEW\\s+\\S+(?:\\s+UUID\\s+\\S+)?(?:\\s+REFRESH\\s.*?)?\\s+TO\\s+(\\S+)'), '`', ''),
       '') AS writes_to,
    t.engine = 'MaterializedView' AND match(t.create_table_query, '^CREATE MATERIALIZED VIEW\\s+\\S+(?:\\s+UUID\\s+\\S+)?\\s+REFRESH\\s') AS refreshable,
    -- Tables whose inserts trigger this materialized view; for a dictionary, its source as system.dictionaries gives it.
    if(t.engine = 'Dictionary', any(d.source), arrayStringConcat(arraySort(groupUniqArrayIf(s.src, s.src != '')), ', ')) AS reads_from,
    any(d.status) AS dictionary_status,
    any(d.element_count) AS dictionary_elements
FROM system.tables AS t
LEFT JOIN
(
    SELECT concat(database, '.', name) AS src, dep.1 AS dep_database, dep.2 AS dep_name
    FROM system.tables
    ARRAY JOIN arrayZip(dependencies_database, dependencies_table) AS dep
    WHERE database NOT IN ('system', 'INFORMATION_SCHEMA', 'information_schema')
) AS s ON s.dep_database = t.database AND s.dep_name = t.name
LEFT JOIN system.dictionaries AS d ON d.database = t.database AND d.name = t.name
WHERE t.engine IN ('View', 'MaterializedView', 'Dictionary')
  AND t.database NOT IN ('system', 'INFORMATION_SCHEMA', 'information_schema')
GROUP BY t.database, t.name, t.engine, t.create_table_query
ORDER BY database, object
LIMIT 1000
