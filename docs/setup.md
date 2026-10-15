# Setup: install the skills and create the agent

[日本語](setup.ja.md)

This guide sets up the "PoC assistant" agent in [ClickHouse Agents](https://clickhouse.com/docs/products/cloud/features/ai-ml/agents). You need a ClickHouse Cloud organization where ClickHouse Agents is available (it is in beta) and a service to evaluate.

## Quick start

1. Enable the Remote MCP server on the service ([step 1](#1-enable-the-remote-mcp-server-on-the-service)).
2. Download the nine skill zips ([step 2](#2-download-the-skills)).
3. Upload each zip as a skill in ClickHouse Agents ([step 3](#3-upload-the-skills)).
4. Create the agent and paste the instructions ([step 4](#4-create-the-agent)).
5. Build the PoC plan with the agent and attach it ([step 5](#5-plan-the-poc-and-attach-the-plan)).
6. Ask for statistics, a review or the daily note ([step 6](#6-use-it)).

## 1. Enable the Remote MCP server on the service

The agent queries the service through the ClickHouse Remote MCP server, which must be enabled per service.

1. In the Cloud console, open the service.
2. Click **Connect**, choose **MCP** under **Connect with**, and turn on **Enable Model Context Protocol**.

Reference: https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp

In testing (2026-10-15), the agent's queries on a new service also failed with "Generative AI features are not enabled for service …" until **Enable Generative AI features** was turned on in the service's **Settings**. Turning it on asks an organization admin to accept the terms for AI features on behalf of the organization.

## 2. Download the skills

Download from the latest release, one by one:

| Skill | Download |
|---|---|
| `poc-plan-builder` | [poc-plan-builder-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-plan-builder-skill.zip) |
| `poc-sizing-stats` | [poc-sizing-stats-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-sizing-stats-skill.zip) |
| `poc-schema-query-advisor` | [poc-schema-query-advisor-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-schema-query-advisor-skill.zip) |
| `poc-load-test-review` | [poc-load-test-review-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-load-test-review-skill.zip) |
| `poc-daily-progress` | [poc-daily-progress-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-daily-progress-skill.zip) |
| `poc-summary` | [poc-summary-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-summary-skill.zip) |
| `poc-cost-projection` | [poc-cost-projection-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-cost-projection-skill.zip) |
| `poc-share-report` | [poc-share-report-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-share-report-skill.zip) |
| `clickhouse-architecture-advisor` (public skill, unmodified) | [clickhouse-architecture-advisor-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/clickhouse-architecture-advisor-skill.zip) |

Or get all nine at once as [poc-assistant-skills.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-assistant-skills.zip) (unzip it to get the nine skill zips), or with the GitHub CLI:

```bash
gh release download -R tkykenmt-at-ch/clickhouse-poc-assistant -p '*-skill.zip'
```

`clickhouse-best-practices` is built into ClickHouse Agents and needs no download. `ch-sizing-export.zip` in the release is the export kit for users who run the queries themselves; the agent does not need it. To build the zips from source instead, see [Build in docs/development.md](development.md#build).

## 3. Upload the skills

1. In the Cloud console, open **ClickHouse agents** in the left navigation.
2. Open **Skills** in the left bar of ClickHouse Agents.
3. For each skill zip: **Create skill** (+) → **Upload skill** → choose the zip. ClickHouse Agents takes one skill per upload.
4. Check that the nine skills are listed.

Reference: https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/skills

## 4. Create the agent

Open **Agent Builder**, choose **Create new agent**, and set:

| Field | Value |
|---|---|
| Name | PoC assistant |
| Description | Helps run a ClickHouse Cloud PoC: plans, sizing statistics, table and query review, daily progress (read-only) |
| Model | provider **Claude**, model `claude-sonnet-5-5` (other listed models should work; this is the one tested) |
| Instructions | the text below |
| Tools | **Add tools** → **ClickHouse** (MCP server), **Artifacts** and **Code Interpreter** |
| Skills | **Selected**, then add all `poc-*` skills, `clickhouse-best-practices` and `clickhouse-architecture-advisor` |

Instructions:

```text
You are an assistant that helps run a ClickHouse Cloud PoC. Pick the skill for each request: poc-plan-builder to plan the PoC and its success criteria, poc-sizing-stats for sizing statistics, poc-schema-query-advisor to review table design and queries (judge with clickhouse-best-practices and clickhouse-architecture-advisor), poc-load-test-review to explain one load test (latency, CPU, reads, autoscaling) or compare two runs, poc-daily-progress for progress, the daily note and next actions, poc-summary for a weekly or final PoC summary, poc-cost-projection for a list-price cost projection from the user's production assumptions, and poc-share-report for a report the user can send to their ClickHouse SA. The PoC target and success criteria are in the PoC plan file (a file starting with poc-plan) in the file context. For every request, read system tables. Query the user's own tables only to confirm a finding, after showing the queries with their EXPLAIN ESTIMATE and getting the user's approval; return aggregates, not rows. Write numbers only from query results; do not guess. When you state how ClickHouse behaves, confirm it with documentation search and attach the URL. Do not recommend a service size, a tier or a price; a cost projection uses the user's assumptions and is not a quote. Do not output user names or e-mail addresses. Present improvements as candidates to verify, not as decisions. Once per conversation, and at the end of a summary, cost projection or share report, add one line saying the assistant can make mistakes and findings should be checked with the ClickHouse SA. Answer in the user's language.
```

Add only these tools. Code Interpreter lets `poc-cost-projection` run its bundled script; its sandbox had no network in testing, so the skill reads the daily copy of the price list it ships with. A tool for another MCP server (for example ClickStack) makes every chat wait until you have signed in to that server too. Use this agent, not the built-in ClickHouse Agent, whose skills are off: the answer should start by loading a `poc-*` skill.

Click **Create**. When you change the agent later, click **Save** and wait for the "updated" notification; otherwise the change can be lost.

The first time the agent calls the ClickHouse tool, it asks you to connect. If it does not, open **MCP settings** in the left bar, find **ClickHouse**, and click **Connect**. The agent sees only the organizations and services your Cloud user can access.

Optional: cost, tier, backups and ClickPipes. The built-in **ClickHouse** server in Agents does not offer the Cloud tools for these (`get_organization_cost`, `list_service_backups`, `list_clickpipes` and others). To let the agent read them, add the ClickHouse Cloud remote MCP server as your own server in **MCP settings** (URL `https://mcp.clickhouse.cloud/mcp`, Streamable HTTP, sign in with OAuth), then add these of its tools to the agent: `get_organizations`, `get_services_list`, `get_service_details`, `get_organization_cost`, `list_service_backups`, `get_service_backup_configuration`, `list_clickpipes`, `get_clickpipe`. Its query tools duplicate the built-in ones and are not needed. Like any other server, every chat then waits until you have signed in to it. Without it, the agent points to the Cloud console for these.

The queries leave out the connection's own reads of system tables but keep every other query of the same database user, so the PoC workload is counted even if it runs as the same user as the agent or an export. Queries that the agent runs on user tables carry `log_comment = 'poc-assistant'` and are left out; if the connection cannot change settings, they are counted and the agent says so.

References: https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/quickstart , https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/mcp-servers

## 5. Plan the PoC and attach the plan

1. Start a chat with the agent and ask, for example: "I want to plan a PoC. The service is <name>, from <start> to <end>. We need to decide whether ..." The agent asks about data, queries and targets, proposes criteria with sources, and asks you for each pass threshold.
2. The agent outputs the plan as `poc-plan-<name>.md`. Download it.
3. In Agent Builder, open the agent, and under **File context** click **Add** and upload the file. Click **Save**.

The plan needs the sections `## Target` and `## Success criteria`, and optionally `## Results` and `## Log` (the Japanese headings `## 対象`, `## 成功基準`, `## 結果` and `## 経緯` also work). Paste the daily note's result lines and your own measurements into `## Results`, and re-attach the file. Everyone who can use the agent can read this file, so create one agent per PoC.

## 6. Use it

| Request | Skill |
|---|---|
| "Show the sizing statistics for the last 7 days." | `poc-sizing-stats` |
| "Review the table design and queries of the PoC service using the last 7 days." | `poc-schema-query-advisor` |
| "Review the load test from 10:00 to 10:20 JST today. It used Locust with 10, 25, 50 and 100 users." | `poc-load-test-review` |
| "Write today's PoC note with poc-daily-progress." | `poc-daily-progress` |
| "Compare the load tests from 10:00 to 10:20 and 14:00 to 14:20 JST today; the sorting key changed in between." | `poc-load-test-review` |
| "Write the PoC summary for this week's review." | `poc-summary` |
| "Project the monthly cost in production: Enterprise, AWS ap-northeast-1, 2 replicas × 32 GiB, 24 hours a day, 5 TB compressed." | `poc-cost-projection` |
| "Write a share report for our SA about today's findings." | `poc-share-report` |

Suggested rhythm: the daily note every morning (paste its result lines into the plan's `## Results`), the full review and `poc-summary` once a week, and `poc-summary` again at the end.

For one PoC followed through every step with screenshots, see the [walkthrough](walkthrough.md).

## Upgrading to a new release

Skills cannot be replaced in place, and deleting a skill removes it from the agent. For each skill that changed:

1. Download the new zip.
2. In **Skills**, open the skill and delete it.
3. Upload the new zip.
4. In Agent Builder, open the agent, add the skill again under **Skills**, and click **Save**. Wait for the "updated" notification.

## Limitations (as of 2026-10-08)

- **Scheduled chats**: the feature is available, but creating a schedule for an agent with the ClickHouse tool keeps showing "Reconnect this MCP server before enabling the schedule." even after reconnecting. Until this changes, ask the agent for the daily note and the weekly review.
- **Memory**: memories created by hand in the Memory panel did not reach the agent in testing, so the plan is passed as file context instead.
- **Agent API**: not available, so the agent cannot be called from outside.
- ClickHouse Agents is in beta; screens and behaviour may change.
