-- Views, materialized views and dictionaries, with what each reads from and writes to, for comparing a design with
-- the service. One row per object. Names, engines and status only; no query text.
-- Names are matched as written without spaces; a quoted name with a space gives an empty writes_to.
SELECT
    t.database AS database,
    t.name AS object,
    t.engine AS engine,
    -- Target of a materialized view with TO; empty for one with an inner table.
    if(t.engine = 'MaterializedView',
       replaceAll(extract(t.create_table_query, '^CREATE MATERIALIZED VIEW\\s+\\S+(?:\\s+UUID\\s+\\S+)?(?:\\s+REFRESH\\s.*?)?\\s+TO\\s+(\\S+)'), '`', ''),
       '') AS writes_to,
    t.engine = 'MaterializedView' AND match(t.create_table_query, '^CREATE MATERIALIZED VIEW\\s+\\S+(?:\\s+UUID\\s+\\S+)?\\s+REFRESH\\s') AS refreshable,
    -- Tables whose inserts trigger this materialized view (empty for a refreshable one, which reads on its schedule).
    -- For a dictionary, its source: from system.dictionaries once loaded, otherwise the DB and TABLE of its definition.
    if(t.engine = 'Dictionary',
       if(any(d.source) != '', any(d.source),
          concat(extract(t.create_table_query, 'SOURCE\\((\\w+)\\('), ': ',
                 extract(t.create_table_query, 'DB\\s+\'([^\']+)\''), '.',
                 extract(t.create_table_query, 'TABLE\\s+\'([^\']+)\''))),
       arrayStringConcat(arraySort(groupUniqArrayIf(s.src, s.src != '')), ', ')) AS reads_from,
    -- NOT_LOADED is normal: dictionaries load on first use. DIRECT and CACHE layouts hold few or no elements.
    if(t.engine = 'Dictionary', toString(any(d.status)), '') AS dictionary_status,
    if(t.engine = 'Dictionary', toString(any(d.element_count)), '') AS dictionary_elements,
    if(t.engine = 'Dictionary', any(d.type), '') AS dictionary_layout
FROM system.tables AS t
LEFT JOIN
(
    SELECT concat(database, '.', name) AS src, dep.1 AS dep_database, dep.2 AS dep_name
    FROM system.tables
    ARRAY JOIN arrayZip(dependencies_database, dependencies_table) AS dep
    WHERE database NOT IN ('system', 'INFORMATION_SCHEMA', 'information_schema')
) AS s ON s.dep_database = t.database AND s.dep_name = t.name
LEFT JOIN
(
    SELECT database, name, any(status) AS status, max(element_count) AS element_count, any(source) AS source,
           any(type) AS type
    FROM clusterAllReplicas('default', system.dictionaries)
    GROUP BY database, name
) AS d ON d.database = t.database AND d.name = t.name
WHERE t.engine IN ('View', 'MaterializedView', 'Dictionary')
  AND t.database NOT IN ('system', 'INFORMATION_SCHEMA', 'information_schema')
GROUP BY t.database, t.name, t.engine, t.create_table_query
ORDER BY database, object
LIMIT 1000
SETTINGS skip_unavailable_shards = 1
