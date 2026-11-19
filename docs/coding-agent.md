# Using the skill in a coding agent

The skill is a folder of Markdown files, SQL files and one Python script, so an agent other than ClickHouse Agents can follow it too. This page shows how to run it in a coding agent on your own machine, with the ClickHouse Cloud remote MCP server for the queries.

Use this path when you want to choose the model provider and where inference runs yourself, or when ClickHouse Agents is not available in your organization. With [ClickHouse Agents](setup.md) you get the same stages without installing anything locally.

It was checked with Claude Code (2026-11-17). Other agents that load skills in the Agent Skills format (a folder with a `SKILL.md`) and connect to remote MCP servers should work the same way, but have not been checked.

## What you need

- A coding agent that loads skills from a folder and can connect to a remote MCP server over HTTP with OAuth.
- A ClickHouse Cloud service with the Remote MCP server enabled ([setup, step 1](setup.md#1-enable-the-remote-mcp-server-on-the-service)).
- Python 3 on your machine, for the price list in the cost projection. Without it, the skill uses the copy of the price list it ships with.

## 1. Install the skill

Download [poc-assistant-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-assistant-skill.zip) and unpack it into the agent's skills folder. The zip holds one folder, `poc-assistant/`. Keep the folder as it is: the stage files refer to `queries/`, `reference/`, `tools/` and `vendor/` next to `SKILL.md`.

For Claude Code, a skill in the project folder applies to that project only:

```bash
mkdir -p .claude/skills
unzip poc-assistant-skill.zip -d .claude/skills/
```

To upgrade, delete `.claude/skills/poc-assistant/` and unpack the new zip.

## 2. Connect the ClickHouse Cloud remote MCP server

Add `https://mcp.clickhouse.cloud/mcp` as a remote MCP server and sign in with your ClickHouse Cloud account when the agent asks. For Claude Code:

```bash
claude mcp add --transport http clickhouse-cloud https://mcp.clickhouse.cloud/mcp
```

The connection is read-only. It runs as you, so it sees every organization and service your account can see; the skill asks once which service the PoC runs on and stays on it.

Reference: https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp

## 3. Keep one folder per PoC

Start the agent in a folder you use for this PoC only. The skill reads the plan (`poc-plan-<name>.md`) and the design (`poc-design-<name>.md`) from that folder and writes its files there: the plan, the design, CSV files and the share report. There is nothing to attach.

Paste the daily note's result lines and your own measurements into the plan's `## Results`, as in [setup, step 5](setup.md#5-plan-the-poc-and-attach-the-plan).

## 4. Use it

Ask in plain words and name the skill the first time, for example:

- "Use the poc-assistant skill. I want to plan a PoC. The service is `<name>`, from `<start>` to `<end>`. We need to decide whether ..."
- "Check the service against the design."
- "Write today's daily note."

The stages are the same as in ClickHouse Agents; see the [walkthrough](walkthrough.md) for what each one returns.

## Differences from ClickHouse Agents

| | ClickHouse Agents | Coding agent |
|---|---|---|
| Plan and design | Attached to the agent as file context | Files in the working folder |
| Files the skill hands over | Artifacts to download | Files written to the working folder |
| Service | The service the agent is connected to | You name it once per conversation |
| `clickhouse-best-practices` | Built in | Install it yourself from [ClickHouse/agent-skills](https://github.com/ClickHouse/agent-skills); without it the skill cites documentation URLs instead |
| Documentation search | Built in | Used when a ClickHouse documentation search tool is connected; otherwise the skill cites only the URLs in its reference files |
| Price list | The copy shipped with the skill (the code sandbox has no network) | Fetched from clickhouse.com when Python can reach the network |
| Scheduled chats, memory, sharing the agent | Available as ClickHouse Agents offers them | Not available; ask for the daily note each day |
| Setup help from the `help` stage | Step-by-step for the ClickHouse Agents screens | Points to this page |

## Limitations

- **The agent's own queries show up in the results.** The remote MCP server runs a few housekeeping queries on system tables as a different database user, and the skill's queries cannot leave those out. The daily note can list them as new query patterns, and they appear in the query counts. They are small `SELECT`s on `system.roles`, `system.role_grants` and `system.databases`.
- **Cost for the whole organization.** The Cloud cost tool returns every service in the organization. The skill uses only the PoC service's rows, but the other rows pass through the conversation.
- **Approval is still yours.** Before a query on your own tables, the skill shows the query with its `EXPLAIN ESTIMATE` and waits for your approval. Do not configure the agent to skip that step.
- **What you send where.** Your prompts, the query results and the plan go to the model provider your coding agent uses. Check that provider's terms for your PoC data.
