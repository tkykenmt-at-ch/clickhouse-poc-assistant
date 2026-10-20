# Setup: install the skill and create the agent

This guide sets up the "PoC assistant" agent in [ClickHouse Agents](https://clickhouse.com/docs/products/cloud/features/ai-ml/agents). You need a ClickHouse Cloud organization where ClickHouse Agents is available (it is in beta) and a service to evaluate.

## Quick start

1. Enable the Remote MCP server on the service ([step 1](#1-enable-the-remote-mcp-server-on-the-service)).
2. Download `poc-assistant-skill.zip` ([step 2](#2-download-the-skill)).
3. Upload it as a skill in ClickHouse Agents ([step 3](#3-upload-the-skill)).
4. Create the agent and paste the instructions ([step 4](#4-create-the-agent)).
5. Build the PoC plan with the agent and attach it ([step 5](#5-plan-the-poc-and-attach-the-plan)).
6. Ask for the design, a check against it, statistics, a review or the daily note ([step 6](#6-use-it)).

Once the agent exists, it explains the rest itself: ask it "What can you do?" or "How do I add an MCP server?".

## 1. Enable the Remote MCP server on the service

The agent queries the service through the ClickHouse Remote MCP server, which must be enabled per service.

1. In the Cloud console, open the service.
2. Click **Connect**, choose **MCP** under **Connect with**, and turn on **Enable Model Context Protocol**.

Reference: https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp

In testing (2026-10-15), the agent's queries on a new service also failed with "Generative AI features are not enabled for service …" until **Enable Generative AI features** was turned on in the service's **Settings**. Turning it on asks an organization admin to accept the terms for AI features on behalf of the organization.

## 2. Download the skill

Download [poc-assistant-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-assistant-skill.zip) from the latest release, or with the GitHub CLI:

```bash
gh release download -R tkykenmt-at-ch/clickhouse-poc-assistant -p poc-assistant-skill.zip
```

It is one skill with a stage for each step of a PoC, and it bundles the public skill `clickhouse-architecture-advisor` ([ClickHouse/agent-skills](https://github.com/ClickHouse/agent-skills), Apache-2.0, unmodified). `clickhouse-best-practices` is built into ClickHouse Agents and needs no download. `ch-sizing-export.zip` in the release is the export kit for users who run the queries themselves; the agent does not need it. To build the zip from source instead, see [Build in docs/development.md](development.md#build).

## 3. Upload the skill

1. In the Cloud console, open **ClickHouse agents** in the left navigation.
2. Open **Skills** in the left bar of ClickHouse Agents.
3. **Create skill** (+) → **Upload skill** → choose `poc-assistant-skill.zip`.
4. Check that `poc-assistant` is listed.

Reference: https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/skills

## 4. Create the agent

Open **Agent Builder**, choose **Create new agent**, and set:

| Field | Value |
|---|---|
| Name | PoC assistant |
| Description | Helps run a ClickHouse Cloud PoC: plans, design, checks against the design, sizing statistics, table and query review, daily progress (read-only) |
| Model | provider **Claude**, model `claude-sonnet-5-5` (other listed models should work; this is the one tested) |
| Instructions | the text below |
| Tools | **Add tools** → **ClickHouse** (MCP server), **Artifacts** and **Code Interpreter** |
| Skills | **Selected**, then add `poc-assistant` and `clickhouse-best-practices` |

Instructions:

```text
You are an assistant that helps run a ClickHouse Cloud PoC. For every request, load the poc-assistant skill first and follow the stage it points to; this includes questions about what you can do and how to set up or use this agent. You run in ClickHouse Agents: MCP servers are added in its MCP settings and Agent Builder screens, never in a configuration file, so do not give steps for other MCP clients. The PoC target and success criteria are in the PoC plan file (a file starting with poc-plan) and the design in the design file (a file starting with poc-design), both in the file context. The user builds the service, tables and ingest; you do not run DDL or loads. For every PoC request, read system tables. Query the user's own tables only to confirm a finding, after showing the queries with their EXPLAIN ESTIMATE and getting the user's approval; return aggregates, not rows. Write numbers only from query results, the plan's ## Results or the sources the skill names; do not guess. When you state how ClickHouse behaves, confirm it with documentation search and attach the URL. Do not recommend a service size, a tier or a price; a cost projection uses the user's assumptions and is not a quote. Do not output user names or e-mail addresses. Never ask for or accept passwords, API keys, client secrets or tokens. Present improvements as candidates to verify, not as decisions. Once per conversation, and at the end of a summary, cost projection or share report, add one line saying the assistant can make mistakes and findings should be checked with the ClickHouse SA. Answer in the user's language.
```

Add only these tools. Code Interpreter lets the cost projection run its bundled script; its sandbox had no network in testing, so the skill reads the daily copy of the price list it ships with. Use this agent, not the built-in ClickHouse Agent, whose skills are off: the answer should start by loading `poc-assistant`.

Click **Create**. When you change the agent later, click **Save** and wait for the "updated" notification; otherwise the change can be lost.

The first time the agent calls the ClickHouse tool, it asks you to connect. If it does not, open **MCP settings** in the left bar, find **ClickHouse**, and click **Connect**. The agent sees only the organizations and services your Cloud user can access.

### Optional MCP servers

Two kinds of server can be added later, and the agent walks you through both when you ask (for example "How do I add the AWS documentation?"); the steps and values it uses are in [stages/help.md](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/blob/main/clickhouse-agents/skills/poc-assistant/stages/help.md#adding-an-mcp-server):

- **ClickHouse Cloud remote MCP** (`https://mcp.clickhouse.cloud/mcp`, OAuth): lets the agent read cost, tier, backups and ClickPipes, which the built-in **ClickHouse** server does not offer. Without it, the agent points to the Cloud console for these.
- **The cloud provider's documentation** (AWS Knowledge, Microsoft Learn or Google Developer Knowledge): facts on the provider's side for the design stage, such as private endpoints, regional availability and IAM on the sources. Add only the one for the PoC's cloud. Without one, the agent gives the provider's documentation URLs. The Google server needs an OAuth client from your own Google Cloud project and has not been tested in ClickHouse Agents yet.

Each server is another place the agent's search text is sent; the agent sends only general questions (a provider service, a region, a feature), never company, table or column names, data values, account IDs or service names. Every chat waits until you have signed in to each server that needs a sign-in. Enter credentials only in **MCP settings**; keep client IDs and secrets out of the chat, the repository and the instructions.

The queries leave out the connection's own reads of system tables but keep every other query of the same database user, so the PoC workload is counted even if it runs as the same user as the agent or an export. Queries that the agent runs on user tables carry `log_comment = 'poc-assistant'` and are left out; if the connection cannot change settings, they are counted and the agent says so.

References: https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/quickstart , https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/mcp-servers

## 5. Plan the PoC and attach the plan

1. Start a chat with the agent and ask, for example: "I want to plan a PoC. The service is <name>, from <start> to <end>. We need to decide whether ..." The agent asks about data, queries and targets, proposes criteria with sources, and asks you for each pass threshold.
2. The agent outputs the plan as `poc-plan-<name>.md`. Download it.
3. In Agent Builder, open the agent, and under **File context** click **Add** and upload the file. Click **Save**.

The plan needs the sections `## Target` and `## Success criteria`, and optionally `## Setup`, `## Results` and `## Log` (the Japanese headings `## 対象`, `## 成功基準`, `## 準備`, `## 結果` and `## 経緯` also work). `## Setup` lists what is connected and which MCP servers this PoC needs. Paste the daily note's result lines and your own measurements into `## Results`, and re-attach the file. Everyone who can use the agent can read this file, so create one agent per PoC.

## 6. Use it

| Request | Stage |
|---|---|
| "What can you do?" or "How do I add an MCP server?" | `help` |
| "Design the architecture and the tables for the PoC. Here are the source schema, sample rows and our main queries." | `architecture-design` |
| "We created the tables. Does the service match the design, and what should we do next?" | `fit-gap` |
| "Show the sizing statistics for the last 7 days." | `sizing-stats` |
| "Review the table design and queries of the PoC service using the last 7 days." | `schema-query-advisor` |
| "Review the load test from 10:00 to 10:20 JST today. It used Locust with 10, 25, 50 and 100 users." | `load-test-review` |
| "Write today's PoC note." | `daily-progress` |
| "Compare the load tests from 10:00 to 10:20 and 14:00 to 14:20 JST today; the sorting key changed in between." | `load-test-review` |
| "Write the PoC summary for this week's review." | `summary` |
| "Project the monthly cost in production: Enterprise, AWS ap-northeast-1, 2 replicas × 32 GiB, 24 hours a day, 5 TB compressed." | `cost-projection` |
| "Write a share report for our SA about today's findings." | `share-report` |

Suggested rhythm: the daily note every morning (paste its result lines into the plan's `## Results`), the full review and the summary once a week, and the summary again at the end.

For one PoC followed through every step with screenshots, see the [walkthrough](walkthrough.md).

## Upgrading to a new release

Skills cannot be replaced in place, and deleting a skill removes it from the agent:

1. Download the new `poc-assistant-skill.zip`.
2. In **Skills**, open `poc-assistant` and delete it. An upload with the name of an existing skill fails.
3. Upload the new zip.
4. In Agent Builder, open the agent, add `poc-assistant` again under **Skills**, and click **Save**. Wait for the "updated" notification.

Upgrading from v0.5.0 or earlier: delete every `poc-*` skill and `clickhouse-architecture-advisor`, upload `poc-assistant-skill.zip`, replace the agent's instructions with the text in [step 4](#4-create-the-agent), and select `poc-assistant` and `clickhouse-best-practices` under **Skills**.

## Limitations (as of 2026-10-08)

- **Scheduled chats**: the feature is available, but creating a schedule for an agent with the ClickHouse tool keeps showing "Reconnect this MCP server before enabling the schedule." even after reconnecting. Until this changes, ask the agent for the daily note and the weekly review.
- **Memory**: memories created by hand in the Memory panel did not reach the agent in testing, so the plan is passed as file context instead.
- **Agent API**: not available, so the agent cannot be called from outside.
- ClickHouse Agents is in beta; screens and behaviour may change.
