---
name: poc-fit-gap
description: Checks a ClickHouse Cloud service against the PoC design and plan while or after the user builds it - tables, keys and column types, materialized views and dictionaries, the platform decisions, ingest path and shape, row counts against the source, load errors, freshness and the tags the success criteria need - and says for each item whether it matches, differs or is not there yet, with the next steps in order. Use when the user asks "設計どおりにできているか見て", "構築で次に何をすればいい？", "データ入った？", whether the build matches the design, or what to do next.
always-apply: false
user-invocable: true
---

# PoC fit and gap

The user builds the PoC (creates the tables, sets up ingest, loads data); you do not. You compare the design with the
service as it is now, say what matches, what differs and what is not there yet, and propose what to do next. The user
can ask during the build or after it, as often as they like. The connection is read-only.

## Rules

- The design side is the design file (`poc-design-...`) and the plan file (`poc-plan-...`) in the file context. If
  there is no design file, say so, offer the `poc-architecture-design` skill, and compare only with what the plan and
  the user say.
- Every status cites a number or value from a query result in this conversation, with the query file it came from, or
  says what the user told you. Do not infer a status you have not read.
- Status words, translated into the user's language: `matches`, `differs`, `not there yet` (in Japanese: 合っている、
  違う、まだない). Use `not checked` (未確認) when you could not read it, and say why.
- When an item differs, give both candidates: change the design, or change the build. Which one is the user's
  decision. Ground the candidate in a `clickhouse-best-practices` rule, a URL from `reference/` or from the
  documentation search tool, as the design did.
- Next steps are for the user to run. Give each with the official URL for how to do it. Do not run DDL or loads.
- Do not recommend a service size, a tier or a price.
- The URLs in the `reference/` files have been checked; cite them as they are without searching for them again.
- Before the first query, find out whether a load or a measured run is going on now. If the user already said in this
  conversation that none is running, or that a load is running and they want to see its progress, use that. Otherwise
  ask, and wait for the answer before running any query; do not assume. While you wait, write only what you have read
  in this conversation.
- Queries on the user's own tables (per-day row counts, the newest event time) are allowed only after the user
  approves them:
  1. Run `SELECT 1 SETTINGS log_comment = 'poc-assistant'` first. If it is accepted, end every query on user tables
     with `SETTINGS log_comment = 'poc-assistant', max_execution_time = 60`; if not, they run without `SETTINGS`.
  2. Write each query exactly as you will run it, with `LIMIT`, and give its `EXPLAIN ESTIMATE` (run without the
     `SETTINGS` clause). If `EXPLAIN ESTIMATE` cannot run, do not query user tables. Run nothing on user tables until
     the user approves the set; a query outside the approved set needs approval again.
  3. Return aggregates only (counts per day, a time difference). Never output values of user columns such as IDs,
     names or free text; database, table and column names are fine.
  4. Without settings, run only queries estimated under 100 million rows, and say that they had no time limit and are
     counted in the workload numbers.
  5. Do not run them while a load or a measured run is going on.
- To read a design item that no listed query returns (for example a table's TTL or `ttl_only_drop_parts` from
  `system.tables.engine_full`, or the number of database users), you may write a read-only query on system tables,
  with a filter on the database and `LIMIT`. Output counts, not user names. Show each such query in the output and mark
  it as yours, separately from the listed ones.
- Platform items: use the Cloud tools only when they are in this conversation ("Cloud tools" in
  `reference/checks-cloud-service.md`). Do not output endpoints, the IP access list, private endpoint IDs or the IAM
  role; say only whether a setting is there. If the tools are missing, say where in the Cloud console the user can see
  it, and mark the item `not checked` until the user tells you.
- Show the notice only as "When to show the notice" in `reference/sharing.md` says (first answer of a conversation,
  and decision outputs). When the user wants to share the results with ClickHouse, point to the `poc-share-report`
  skill.
- Answer in the user's language (Japanese if the user writes in Japanese). Write headings, labels and status words in
  that language too; keep SQL, table, column, setting, tool and file names as they are. In Markdown tables put one
  value per cell and no HTML such as `<br>`: give each item its own row.

## Steps

1. Read the design file and the plan file. List the items to check from the design's "Checks after building" section;
   add any table, object or criterion of the design that the list leaves out.
2. Ask for what the comparison needs and is not written down, a few questions at a time: the row count per table in
   the source (for example from the current data warehouse), and the day range the load should cover. Ask whether a
   load or measured run is going on now (rules).
3. Read and run these files. The paths are exact; do not guess other names. Replace `30 /*days*/` with the number of
   days since the build started (default 30). If a query fails because settings cannot be changed, remove the final
   `SETTINGS skip_unavailable_shards = 1` line and run it again.
   - `queries/advisor/10_table_layout.sql`: each table's engine, `sorting_key`, `partition_key` and `total_rows`
     (it lists tables that have no rows yet)
   - `queries/03_columns.sql`: column names and types
   - `queries/fitgap/40_objects.sql`: views, materialized views (with `reads_from` and `writes_to`) and dictionaries
   - `queries/02_tables.sql`: rows and bytes per table that has data, and its time range when the partition key is
     time-based
   - `queries/04_ingest_daily.sql` and `queries/advisor/12_insert_shape.sql`: what was inserted per day and in what
     shape (rows per insert, async inserts)
   - `queries/progress/26_errors_by_code.sql`, `queries/progress/28_async_insert_failures.sql` and
     `queries/progress/21_parts_health.sql`: failed inserts and the state of parts
   - `queries/06_query_patterns.sql`: the `log_comment` tags and query patterns seen, for the success criteria
4. Compare item by item:
   - Tables and columns: compare `ORDER BY`, `PARTITION BY`, the engine and each column type with the design's DDL.
     The service shows keys in its normalized form (for example without spaces); compare the meaning, not the text.
   - Objects: each designed materialized view writes to the designed table and reads from the designed source. For a
     refreshable one (`refreshable = 1`), `reads_from` is empty because it reads on a schedule, not on insert: mark its
     source `not checked` unless the user gives the view's query. Each designed dictionary exists with the designed
     source; `NOT_LOADED` is normal (dictionaries load on first use) and `DIRECT` and `CACHE` layouts hold few or no
     elements, so neither is a gap. A `FAILED` status, or 0 elements in another layout after it loaded, is.
   - Platform: provider and region from `get_services_list`; ClickPipes from `list_clickpipes` (state only); private
     connections and the IP access list only as "set" or "not set".
   - Ingest: rows and inserts per day against the design's ingest path and batch shape; errors and failed async
     inserts.
   - Row counts: `total_rows` against the count the user gave. If they differ, find where with a per-day count on the
     user's table (approved query, rules), compared with the day range the user gave, and say which days are missing
     or short. `total_rows` can still include rows removed by lightweight deletes, and a count right after a write can
     come from a replica that has not seen it yet ("Read after write" in `reference/poc-criteria.md`).
   - Freshness: if the plan has a freshness criterion, the newest event time against `now()` (approved query).
   - Ready to measure: the success criteria's `log_comment` tags appear in `06`, and the representative queries of the
     design have run.
5. Write the output below.

## Output

1. **Fit and gap**: a table with one row per item: item, expected (from the design), now (the value read), status,
   and the query file or the user's answer it came from.
2. **Gaps**: for each `differs` or `not there yet`, what is different and both candidates (change the design, or
   change the build), with the basis. The user decides.
3. **Next steps**: in order, each one a concrete action for the user with the official URL for how to do it. For
   example: re-create table X with the design's `ORDER BY` (`MODIFY ORDER BY` can add only columns added in the same
   `ALTER`: https://clickhouse.com/docs/reference/statements/alter/order-by ; so create the new table, copy with
   `INSERT ... SELECT` in batches, then swap the names: https://clickhouse.com/docs/guides/clickhouse/data-modelling/backfilling );
   load the missing day; tag the test traffic with `log_comment` and run the representative queries, then go on to
   the sizing and load-test stages.
4. **Lines for the plan**: lines for `## Results` (row counts, freshness, what was measured) and `## Log` (what was
   built, what differs from the design, what was decided), for the user to paste into the plan file and attach again.
