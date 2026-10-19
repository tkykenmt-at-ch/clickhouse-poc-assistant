# Development: layout, build and query conventions

For contributors: how the repository is laid out, how the zips are built and tested, and the rules every query follows. To install and use the agent, see [Setup](setup.md).

## Repository layout

| Path | Contents |
|---|---|
| `queries/` | Sizing queries (01–08). The single source for every tool below. |
| `queries/optional/` | A query that includes sample query text. Not run by default. |
| `queries/advisor/` | Queries for the advisor (10–13). |
| `queries/progress/` | Queries for the daily note (20–28; 22 onwards pick up changes, 26–28 cover errors, background work and async insert flushes). |
| `queries/loadtest/` | Queries for one load-test window (30–31) and for comparing two runs (32). |
| `queries/fitgap/` | Queries for checking the service against the design (40: views, materialized views and dictionaries with their sources and targets). |
| `reference/poc-criteria.md` | PoC evaluation areas and how to measure each, with public sources only (ClickHouse docs and customer stories on clickhouse.com/blog). |
| `reference/architecture-platform.md` | Platform decisions for the design stage (deployment, provider and region, connection paths, integrations, security, compute separation, backups): the questions, how they branch and the official pages, and the rules for the cloud providers' documentation tools. |
| `reference/checks-*.md` | Checks for a running service, one file per area (CPU and concurrency, reads and queries, inserts and parts, errors and background work, autoscaling and test design, the Cloud service). Each check names the columns it reads, the rule and its public source. The bundled design rules (`clickhouse-best-practices`) cover how to build tables and inserts; these cover what to look at once a workload runs. |
| `clickhouse-agents/skills/poc-assistant/` | The skill. `SKILL.md` picks the stage and holds the rules for every stage; `stages/` has one file per stage (`help.md` explains the agent's own setup). |
| `export/` | A kit for users who export the statistics themselves with `export.sh` (bash and curl) or the SQL console. |
| `scripts/build.sh` | Builds the skill zip (`poc-assistant-skill.zip`) and the export kit into `dist/`. |
| `scripts/fetch-public-skills.sh` | Downloads public skills unmodified at a pinned commit, with their license; `build.sh` puts them under the skill's `vendor/`. |
| `scripts/test-queries.sh` | Runs every query on a throwaway local ClickHouse server as a least-privilege user. |
| `.github/workflows/build.yml` | CI and releases (see below). |
| `docs/`, `mkdocs.yml` | The docs site: setup guide and walkthrough (`docs/images/` holds its screenshots), built with MkDocs Material. Japanese pages end in `.ja.md`. |
| `scripts/mkdocs/` | The site's pinned requirements and a hook that forwards the old `<page>.ja.html` URLs to `ja/<page>.html`. |
| `.github/workflows/pages.yml` | Builds the docs site on pull requests and publishes it to GitHub Pages from `main`. |
| `LICENSE` | Apache-2.0. Every zip carries a copy; the bundled public skill carries the ClickHouse/agent-skills license. |

## Build

GitHub Actions runs on every push and pull request: it checks the SQL syntax, runs every query on a throwaway server (`scripts/test-queries.sh`), runs ShellCheck, and builds the zips. Pushing a `v*` tag publishes them to a release. To build locally:

```bash
scripts/build.sh                # dist/ch-sizing-export.zip and dist/poc-assistant-skill.zip (needs network for the public skill)
scripts/test-queries.sh         # needs a clickhouse binary on PATH
pip install -r scripts/mkdocs/requirements.txt && mkdocs serve   # the docs site at http://127.0.0.1:8000/clickhouse-poc-assistant/
```

The skill zip contains `SKILL.md`, `stages/`, the license, exactly the files the stages name (`queries/...sql`, `reference/...md`, `tools/...py`) and the public skills under `vendor/`. Reference files that a shipped reference file names are shipped too. The agent cannot list folders, so `SKILL.md` lists every stage file and each stage names the files it uses; the build fails if a named file is missing or a stage file is not listed.

## Query conventions

- Read system tables only. (Queries that the agent runs on user tables with the user's approval are written in the conversation, not stored here; they carry `log_comment = 'poc-assistant'`, and every `query_log` query here leaves them out.)
- On ClickHouse Cloud, logs are per replica: read them with `clusterAllReplicas('default', merge('system', '^<table>'))`.
- From `query_log`, exclude this connection's own reads of system tables (queries by `currentUser()` whose `tables` are not empty and are only `system.*`, `information_schema.*`, `clusterAllReplicas` and `merge`; queries that failed before they started have no `tables` and are kept) and ClickHouse Cloud's own monitoring users (names ending in `-internal`). Without this, monitoring queries dominated the SELECT counts in testing. Other queries of the connected user are kept, so a workload that runs as the same database user is still counted; queries that the agent runs on user tables with `log_comment = 'poc-assistant'` are left out, and any other query on user tables over that connection is counted.
- Filter on `event_date` as well as `event_time` so only the needed partitions are read.
- Do not output user names; output counts. Output `normalized_query_hash` as a string (`toString`) so no digits are lost.
- Write the period as `30 /*days*/`, and a load-test window as `now() - INTERVAL 1 HOUR /*window_start*/` and `now() /*window_end*/`; tools replace these markers.
- Small tables stored only in compact parts report 0 compressed bytes until they are merged.
- The review, load-test, daily and fit-gap stages may write further read-only queries on system tables to confirm a finding, with the same filters, and show them as their own in the output. The sizing stage runs only the listed queries, so its numbers can be reproduced.
