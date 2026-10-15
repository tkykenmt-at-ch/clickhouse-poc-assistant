# Checks: the Cloud service itself

These are rules about the service and about how the skills read it. The URLs have been checked; cite them as they are.

## Reading system tables keeps the service awake

- **Rule**: querying system tables wakes an idled service and keeps it from idling, which can affect cost. Run the skills when the user asks, not continuously; for continuous monitoring point to the Cloud console or the Prometheus endpoint.
- **Source**: https://clickhouse.com/docs/products/cloud/features/monitoring/system-tables

## Services in a warehouse

- **Rule**: `clusterAllReplicas('default', …)` covers only the current service. In a warehouse with several services, `all_groups.default` covers all of them; merges and inserts run by another read-write service of the warehouse are not visible with `default`. If the user says the service is part of a warehouse, say which scope the results cover.
- **Source**: https://clickhouse.com/docs/products/cloud/features/infrastructure/warehouses

## Why the service does not idle

- **Columns**: rows with `check` = `active parts on replica` (`queries/advisor/13_service_objects.sql`), `active_parts` (`queries/advisor/10_table_layout.sql`), running merges (`queries/progress/27_background_health.sql`), query counts by hour (`queries/07_query_load_hourly.sql`).
- **Rule**: the service is not idled while the number of active parts exceeds the threshold (default 10,000) or while merges are running. The documentation does not say which databases' parts count; this assistant compares the replica total from `13`, which includes the `system` database, to be conservative, and says so. Queries from anywhere keep it awake; the default IP access list allows any address, so restricting it is recommended.
- **Source**: https://clickhouse.com/docs/products/cloud/features/autoscaling/idling

## Did something stop while the service was idle?

- **Columns**: `uptime_seconds` (`queries/01_service.sql`), rows with `check` = `refreshable view failing` (`queries/progress/27_background_health.sql`), `queries` by hour (`queries/07_query_load_hourly.sql`).
- **Rule**: while idle, the service can suspend refreshes of refreshable materialized views, consumption from S3Queue and the scheduling of new merges; merges already running finish first. To keep them running, disable idling. Connections can time out while the service is paused, so a client's first query after a quiet period can fail; the client must tolerate the wake-up delay and retry, and the documentation recommends testing its timeout and retry behaviour against an idle service. The system tables do not record idling itself: when hours with no queries line up with a view that stopped refreshing, S3Queue lag or a connect timeout reported by the user, say that idling is the likely cause and that it is inferred.
- **Source**: https://clickhouse.com/docs/products/cloud/features/autoscaling/idling

## How far back the evidence goes

- **Rule**: system table data is kept for 30 days (and copied to new replicas when they replace old ones). Findings older than that cannot be checked; say so when the user asks about an earlier period.
- **Source**: https://clickhouse.com/docs/products/cloud/features/autoscaling/make-before-break

## Usage limits

- **Columns**: rows with `check` = `databases` and `tables` (`queries/advisor/13_service_objects.sql`).
- **Rule**: ClickHouse Cloud enforces soft limits on the number of tables, databases, views, dictionaries and other objects; the documentation lists default values (for example 1000 databases, 5000 tables, and views and dictionaries counted separately), and the service's own values below take precedence. One database or table per tenant does not scale to thousands of tenants; the multi-tenancy guide describes the alternatives. Read the service's own values with `SELECT name, value FROM system.server_settings WHERE name LIKE 'max_%_num_to_warn' OR name LIKE 'max_%_num_to_throw'` and compare with the counts; quote the documented default only when the service's value is not available.
- **Source**: https://clickhouse.com/docs/products/cloud/guides/best-practices/usagelimits , https://clickhouse.com/docs/products/cloud/guides/best-practices/multitenancy

## ClickPipes

- **Rule**: ClickPipes latency, errors and replica CPU are not in the service's system tables; they are in the Prometheus endpoint (for example `ClickPipes_Latency`) and the console. Point the user there instead of guessing.
- **Source**: https://clickhouse.com/docs/integrations/clickpipes/monitoring

## Did the server version change during the PoC?

- **Columns**: rows with `check` = `server revision seen` (the server's build revision: it changes with many releases but is not unique per version) (`queries/advisor/13_service_objects.sql`), `version` per replica (`queries/01_service.sql`).
- **Rule**: more than one revision in the period means the server was upgraded or rebuilt during the PoC; results measured before and after are not directly comparable. One revision does not prove there was no upgrade; give the current `version` from `01`. ClickHouse Cloud has release channels; agree on the channel at the start of the PoC, and note that moving to a slower channel does not downgrade the service.
- **Source**: https://clickhouse.com/docs/products/cloud/features/admin-features/upgrades , ClickHouse source: https://github.com/ClickHouse/ClickHouse/blob/master/cmake/autogenerated_versions.txt (`VERSION_REVISION`)

## Kafka engine tables on ClickHouse Cloud

- **Columns**: rows with `check` = `kafka engine table` (`queries/advisor/13_service_objects.sql`).
- **Rule**: on ClickHouse Cloud the documentation recommends ClickPipes instead of the Kafka table engine; ClickPipes supports private network connections and scales ingestion separately from the service.
- **Source**: https://clickhouse.com/docs/integrations/connectors/data-ingestion/kafka/kafka-table-engine

## Cloud tools: configuration, cost, backups and ClickPipes

- **Tools**: `get_services_list`, `get_service_details`, `get_organizations`, `get_organization_cost`, `list_service_backups`, `get_service_backup_configuration`, `list_clickpipes` and `get_clickpipe` from the ClickHouse Cloud remote MCP server. In ClickHouse Agents, the built-in ClickHouse tool has only `get_services_list` of these; the others are there only when the user has added the remote MCP server to the agent as a separate connection. If a tool is missing, say so and point to the Cloud console; do not guess the value.
- **Rule (finding the service)**: the tools that take `organizationId` need the organization of the service you query. Call `get_organizations`, then `get_services_list` with each organization ID, and take the organization whose list holds an entry with this service's `id`. Calling `get_service_details` with the wrong organization fails with an error that can name a Postgres service id; it means the wrong organization, not a wrong service. Do not output endpoints, the IP access list or the IAM role.
- **Rule (tier)**: tiers are set per organization, so all services of an organization have the same tier. `get_service_details` and `get_organization_details` do not return it; the `organizationTier` field of the `get_organization_cost` rows does (call it for one day). Report the tier only from `organizationTier`. Other fields of `get_services_list` or `get_service_details` (for example a plan or product label) are not the tier: do not report them as the tier, compare them with it, or raise them as a question.
- **Rule (cost)**: `get_organization_cost` takes `from_date` and `to_date` (at most 31 days) and returns `grandTotalCHC` for the whole organization and one row per day and entity, with `entityType` `service`, `datawarehouse` or `clickpipe`, `totalCHC` and `metrics` (for example `computeCHC`, `storageCHC`, `backupCHC`, `publicDataTransferCHC`). Call it one or two days at a time: in testing, seven days of an organization with a dozen services was longer than the tool output and was cut off. If a result is cut off, say which days are missing and do not add up a partial result. For this service, use the `service` and `clickpipe` rows whose `serviceId` is this service and the `datawarehouse` rows whose `dataWarehouseId` is this service's; the `datawarehouse` rows (storage and backups) are shared by every service in the warehouse, so say so. `grandTotalCHC` is not this service's cost. A running pipe can have no `clickpipe` row (in testing, a Pub/Sub pipe had none); say that it has no cost row rather than reporting 0. Today's row covers only part of the day. Report the values in CHC as returned; do not convert them to a currency and do not recommend a size, a tier or a price.
- **Rule (backups)**: `list_service_backups` returns each backup's `status`, `type` (full or incremental), `startedAt`, `durationInSeconds` and `sizeInBytes`, newest first; `get_service_backup_configuration` returns `backupPeriodInHours` and `backupRetentionPeriodInHours`. They show that backups ran, how often and how long they took; they do not measure how long a restore takes, which the user measures by restoring to a new service.
- **Rule (ClickPipes)**: `list_clickpipes` returns each pipe's `name`, `state` and `scaling`. Report the state; latency and errors are still only in the Prometheus endpoint and the console. Do not output the source's connection details (hosts, project IDs, topics, authentication).
- **Source**: https://clickhouse.com/docs/products/cloud/features/ai-ml/mcp/remote-mcp , https://clickhouse.com/docs/products/cloud/features/cloud-tiers , https://clickhouse.com/docs/products/cloud/features/backups/overview , https://clickhouse.com/docs/integrations/clickpipes/monitoring
