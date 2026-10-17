<div align="center">

# PoC Assistant

**powered by [ClickHouse Agents](https://clickhouse.com/docs/products/cloud/features/ai-ml/agents)**

Run a ClickHouse Cloud proof of concept with evidence, not guesses.<br>
The agent reads your service's system tables and the official documentation,<br>and answers with the numbers and the sources behind them.

[![Release](https://img.shields.io/github/v/release/tkykenmt-at-ch/clickhouse-poc-assistant?label=release)](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/tkykenmt-at-ch/clickhouse-poc-assistant/build.yml?branch=main&label=CI)](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/actions/workflows/build.yml)
[![License](https://img.shields.io/github/license/tkykenmt-at-ch/clickhouse-poc-assistant)](LICENSE)

[Get started](#get-started) · [Walkthrough](docs/walkthrough.md) · [Setup guide](docs/setup.md) · [日本語](README.ja.md)

<img src="docs/images/en/1-request.png" alt="A request in plain words, and the skill the agent picked" width="760">

</div>

> [!NOTE]
> This is an open-source project (Apache-2.0), not a supported ClickHouse product.

## Where it helps

One skill for each stage of a PoC. Ask in your own words; the agent picks the skill.

| 1&nbsp;·&nbsp;Plan | 2&nbsp;·&nbsp;Design | 3&nbsp;·&nbsp;Check | 4&nbsp;·&nbsp;Review | 5&nbsp;·&nbsp;Measure | 6&nbsp;·&nbsp;Track | 7&nbsp;·&nbsp;Project |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Success criteria and how to measure each | Platform, tables and ingest before you build | The service against the design, and what to do next | Table and query design against best practices | Sizing statistics and load-test comparisons | Daily notes and weekly summaries | Production cost and a report to share |

You build between the design and the check: create the tables, set up ingest and load the data. The agent's connection is read-only; it writes candidates and reads what you built.

<details>
<summary><b>The skills behind each stage</b></summary>

| Stage | Skill | What it does |
|---|---|---|
| Plan | `poc-plan-builder` | Asks about the workload and the environment, proposes success criteria with a measurement method and a public source for each, and writes the PoC plan as Markdown. Pass thresholds are left to you. |
| Design | `poc-architecture-design` | Goes through the platform decisions (deployment, provider and region, connection paths, integrations, security, compute separation, backups) with the conditions and official pages for each, and writes `CREATE TABLE` candidates, objects and the ingest path from your source schema, sample rows and representative queries, with the rule behind each choice. Asks instead of inventing when an input is missing. |
| Check | `poc-fit-gap` | Compares the service with the design during or after the build: tables and keys, column types, views and dictionaries, platform settings, ingest shape, row counts against the source, load errors and freshness. Says what matches, what differs and what is not there yet, and lists the next steps. |
| Review | `poc-schema-query-advisor` | Reviews table design, query patterns and insert shape, and proposes up to five improvement candidates, each with the rule or documentation page behind it and a way to verify it. |
| Measure | `poc-sizing-stats` | Collects sizing statistics (storage, compression, ingest volume and peaks, query load, per-query cost) as a summary and CSV-ready tables. |
| Measure | `poc-load-test-review` | Reviews one load-test window (where latency went, whether the replicas ran out of CPU, rows read against rows returned, autoscaling), or compares two runs before and after a change. |
| Track | `poc-daily-progress` | Daily note: what changed in the last 24 hours, where each success criterion stands, advice on what changed, and next actions, with result lines for the plan. |
| Track | `poc-summary` | Weekly or final summary for the people who decide: each criterion with its evidence and trend, open risks and next steps. |
| Project | `poc-cost-projection` | Monthly list-price projection of a production service from your assumptions, from the PoC's bill and from the public price list, with every formula and rate. Not a quote. |
| Project | `poc-share-report` | A report you can send to your ClickHouse Solutions Architect (SA): findings, aggregate numbers, checks and questions, with no data from your tables and names replaced by labels. |

Two public skills from [ClickHouse/agent-skills](https://github.com/ClickHouse/agent-skills) (Apache-2.0) are used unmodified: `clickhouse-best-practices` (built into ClickHouse Agents) and `clickhouse-architecture-advisor`.

</details>

## How it works

The agent queries your service over Remote MCP (Model Context Protocol) and cites the documentation.

```mermaid
flowchart LR
    U["You<br/>receive a plan file, findings,<br/>a cost projection and a share report"]
    subgraph AG["ClickHouse Agents"]
        A["PoC Assistant<br/>skills: plan, design, check, review,<br/>measure, track, project"]
    end
    SVC["Your service<br/>system tables, and your own tables<br/>only with approval"]
    D["ClickHouse documentation<br/>cited for how ClickHouse behaves"]
    C["Cloud tools (optional)<br/>cost, backups, ClickPipes"]
    U -- "request" --> A
    A -- "Remote MCP" --> SVC
    A -- "docs search" --> D
    A -. "Cloud remote MCP" .-> C
```

The Cloud tools are optional: add the ClickHouse Cloud remote MCP server to ClickHouse Agents as [docs/setup.md](docs/setup.md#4-create-the-agent) describes. Without it, the agent points to the Cloud console for cost, backups and ClickPipes.

## What you get

Every answer shows the numbers and the query or documentation page behind them.

<table>
  <tr>
    <th width="33%">Check against the design</th>
    <th width="33%">Load-test review</th>
    <th width="33%">Cost projection</th>
  </tr>
  <tr>
    <td><a href="docs/images/en/3-fitgap-table.png"><img src="docs/images/en/3-fitgap-table.png" alt="Each item of the design against the service, with its status and source"></a></td>
    <td><a href="docs/images/en/5-loadtest-compare.png"><img src="docs/images/en/5-loadtest-compare.png" alt="Two runs against a success criterion"></a></td>
    <td><a href="docs/images/en/7-cost-table.png"><img src="docs/images/en/7-cost-table.png" alt="Cost projection from the price list"></a></td>
  </tr>
  <tr>
    <td>What matches, differs or is not there yet, with the missing day found</td>
    <td>Two runs compared against a success criterion</td>
    <td>Monthly cost from the price list, with every formula</td>
  </tr>
</table>

> [!TIP]
> The [walkthrough](docs/walkthrough.md) follows one PoC on synthetic data through every step, from the plan to the share report.

## Guardrails

| Guardrail | What it means |
|---|---|
| 🔎 **Evidence, not guesses** | Numbers come from system tables; statements about how ClickHouse behaves cite the official documentation. |
| 🔐 **Your tables only with approval** | Before it queries your own tables, the agent shows the queries with their `EXPLAIN ESTIMATE` and asks. It returns aggregates, not rows. |
| 🚫 **No size, tier or price advice** | A cost projection uses your assumptions and is not a quote. |
| 🤖 **Generative AI terms** | Query results are processed by the model under the Generative AI features terms your organization accepts when it turns the features on. |
| 📤 **You decide what is shared** | The share report leaves out table data and names; you check it and send it yourself. |

## Get started

1. **Prepare the service**: turn on Remote MCP and Generative AI features on the service.
2. **Create the agent**: upload the eleven skill zips from the [latest release](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest) and create the agent.
3. **Ask for a plan**: and attach the plan file to the agent.

Step by step: **[docs/setup.md](docs/setup.md)**

## Status

- The whole flow, from plan through design, build and check to share report, was run in ClickHouse Agents in English and Japanese on a test service with synthetic data (2026-10-17); the build was done with `clickhouse-client`, with two deliberate mistakes that the check found; see the [walkthrough](docs/walkthrough.md).
- All queries pass on ClickHouse 26.7 and 26.8 as a least-privilege user (`scripts/test-queries.sh`, run by CI), and run without errors on a ClickHouse Cloud (26.6) test service.
- Not used: ClickHouse Agents memory (manually created memories did not reach the agent in testing), scheduled chats (creating a schedule for an agent with the ClickHouse tool kept asking to reconnect the MCP server), and the Agent API (not available). Ask the agent for the daily note and the weekly review.
- What changed and how each change was tested: [Releases](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases). Known problems and planned work: [Issues](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/issues).

## Development

Repository layout, how to build and test the zips, and the conventions every query follows: [docs/development.md](docs/development.md).
