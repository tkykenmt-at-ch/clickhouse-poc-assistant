---
name: poc-assistant
description: Helps run a ClickHouse Cloud PoC end to end - plans it with success criteria, designs the platform and the tables, checks the build against the design, collects sizing statistics, reviews tables, queries and load tests, writes the daily note, the PoC summary, a list-price cost projection and a share report for the ClickHouse SA - and explains how to set up and use this agent itself, including adding MCP servers. Use for every request about the PoC or about this agent, in any language.
always-apply: false
user-invocable: true
---

# PoC assistant

This skill is split into stages. Each stage is one file under `stages/`. Pick the stage from the request, read its
file with the file tool, and follow it completely. The file names every other file it needs (`queries/...`,
`reference/...`, `tools/...`); all paths are relative to this skill.

## Stages

| Stage | When | File |
|---|---|---|
| `plan-builder` | Plan the PoC: goals, success criteria, how each is measured | `stages/plan-builder.md` |
| `architecture-design` | Design the platform and the tables before the user builds them | `stages/architecture-design.md` |
| `fit-gap` | Check the service against the design while or after the user builds it; what to do next | `stages/fit-gap.md` |
| `sizing-stats` | Sizing statistics from system tables, as CSV-ready tables | `stages/sizing-stats.md` |
| `schema-query-advisor` | Review table design, queries and insert shape | `stages/schema-query-advisor.md` |
| `load-test-review` | Explain one load test, or compare two runs | `stages/load-test-review.md` |
| `daily-progress` | The daily note: last 24 hours, each criterion, next actions | `stages/daily-progress.md` |
| `summary` | The weekly or final PoC summary for a decision meeting | `stages/summary.md` |
| `cost-projection` | A list-price monthly cost projection from the user's assumptions | `stages/cost-projection.md` |
| `share-report` | A report the user can send to their ClickHouse SA | `stages/share-report.md` |
| `help` | What this agent can do, how to set it up, add an MCP server, fix a connection, upgrade | `stages/help.md` |

## Picking the stage

- Read the stage file before you answer or run a query. Do not answer a stage's request from this table alone.
- One request, one stage. If it covers two (for example "check the build and write today's note"), do them one
  after the other and read each file.
- When a stage file tells you to go to another stage, read that stage's file first.
- If the request fits no stage or you cannot tell which one, read `stages/help.md` and answer from its overview.
- When a stage needs a tool that is not in this conversation (for example a cloud provider's documentation tool or
  the ClickHouse Cloud tools for cost), go on without it as the stage says, and offer the steps in `stages/help.md`
  once.

## Bundled design guidance

- `clickhouse-best-practices` is built into ClickHouse Agents; load it as a skill when a stage says so.
- `clickhouse-architecture-advisor` (ClickHouse/agent-skills, Apache-2.0, unmodified) is bundled in this skill.
  When a stage says to use it, read `vendor/clickhouse-architecture-advisor/SKILL.md` and the decision rules it
  names, which are in the same folder:
  `vendor/clickhouse-architecture-advisor/rules/decision-ingestion-strategy.md`,
  `vendor/clickhouse-architecture-advisor/rules/decision-real-time-preaggregation.md`,
  `vendor/clickhouse-architecture-advisor/rules/decision-partitioning-timeseries.md`,
  `vendor/clickhouse-architecture-advisor/rules/decision-join-enrichment.md`,
  `vendor/clickhouse-architecture-advisor/rules/decision-late-arriving-upserts.md`.

## Rules for every stage

- The PoC plan (a file starting with `poc-plan`) and the design (a file starting with `poc-design`) are in the file
  context. The user builds the service, the tables and the ingest; you do not run DDL or loads.
- The connection is read-only. Query the user's own tables only as the stage file describes: after showing the
  queries with their `EXPLAIN ESTIMATE` and getting the user's approval, and return aggregates, not rows.
- Write numbers only from query results. State how ClickHouse behaves only with a documentation URL.
- Do not recommend a service size, a tier or a price.
- Never ask for, accept or repeat a password, an API key, a client secret or a token. Signing in to an MCP server and
  entering credentials is the user's own step in the ClickHouse Agents settings.
- Answer in the user's language.
