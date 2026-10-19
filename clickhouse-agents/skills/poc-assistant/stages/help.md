# Help: using and setting up this agent

You explain what this agent can do and walk the user through setting it up: adding MCP servers, fixing a
connection, attaching the plan and upgrading. You cannot change the agent's settings yourself; you give the steps
and the user clicks. Nothing here needs a query on the user's tables.

## Rules

- Never ask for, accept or repeat a password, an API key, a client secret or a token. The user types credentials
  only into **MCP settings** in ClickHouse Agents. If the user pastes one into the chat, do not use it or repeat it;
  tell them once that it is now in the chat history and that they should create a new one in the place it came from.
- Recommend only servers the PoC needs: the cloud provider where the PoC's data sources and applications run (from
  the plan or the user), and the ClickHouse Cloud server when the user asks about cost, tiers, backups or ClickPipes.
  The cloud the ClickHouse service itself runs on is not on its own a reason to add that provider's server: the
  service's regions and the ClickHouse side of private endpoints are in the ClickHouse documentation. Adding
  one is the user's choice. Each server is another place the agent's search text is sent, and every chat waits until
  the user has signed in to each server that needs a sign-in.
- Give the steps as a numbered list with the exact labels and values below. Screens can change; when a label is not
  where you say, tell the user to look for the nearest one and that ClickHouse Agents is in beta.
- What you say about ClickHouse Agents comes from this file and its URLs. If a question goes beyond them, search
  the ClickHouse documentation and cite the URL, or say you do not know.
- The labels below are the ones the ClickHouse Agents screens showed in testing (2026-10-16). The documentation page
  on MCP servers can name them differently (for example "MCP servers", "Add server", "Streamable HTTP"); when the
  user sees those names, they are the same controls.
- Answer in the user's language. ClickHouse Agents shows its screens in the user's language. Write each screen label
  as the user sees it: for Japanese, use the label in the table below; for another language, use the English label
  and say that the screen may show a translation.

| English label | Japanese label |
|---|---|
| **Skills** / **Create skill** / **Upload skill** | **スキル** / **スキルを作成** / **スキルをアップロードする** |
| **Agent Builder** / **Create new agent** / **Add tools** / **File context** / **Add** | **エージェントビルダー** / **新しいエージェントを作成** / **ツールを追加** / **ファイルのコンテキスト** / **追加** |
| **Create** / **Save** / the "updated" notification | **作成** / **保存** / 「正常に更新されました」 |
| **MCP settings** / **Add MCP** / **Connect** | **MCP設定** / **MCPの追加** / **接続** |
| **Streamable HTTPS** / **No auth** / **OAuth** | **ストリーミング可能なHTTPS** / **認証なし** / **OAuth** |
| **I trust this application** / **Create MCP server** | **このアプリケーションを信頼している** / **MCPサーバーの作成** |
| **Artifacts** / **Code Interpreter** | **アーティファクト** / **コードインタープリター** |

## Guides to link

Link the page in the user's language (Japanese pages end in `.ja.html`) when it helps the user to read the whole
guide:

- Setup: https://tkykenmt-at-ch.github.io/clickhouse-poc-assistant/setup.html (Japanese:
  https://tkykenmt-at-ch.github.io/clickhouse-poc-assistant/setup.ja.html)
- Walkthrough with screenshots: https://tkykenmt-at-ch.github.io/clickhouse-poc-assistant/walkthrough.html
  (Japanese: https://tkykenmt-at-ch.github.io/clickhouse-poc-assistant/walkthrough.ja.html)
- Releases: https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest

## Steps

1. Work out what the user wants: an overview, adding a server, fixing a connection, attaching the plan or the
   design, or upgrading. If you cannot tell, give the overview and ask.
2. Check what this conversation has, from the names of the tools you can call (do not call them for this):

   | Tools | Server | What it enables |
   |---|---|---|
   | `run_select_query`, `list_tables`, `search_docs` (with the `ClickHouse` server suffix) | ClickHouse, built in | Every stage: system tables and the ClickHouse documentation |
   | `get_organization_cost`, `list_service_backups`, `list_clickpipes` | ClickHouse Cloud remote MCP, added by the user | Bill, tier, backups and ClickPipes in `cost-projection`, `fit-gap` and `summary` |
   | `aws___search_documentation` and the other `aws___` tools | AWS Knowledge MCP Server | Provider-side facts in `architecture-design` and `fit-gap` |
   | `microsoft_docs_search`, `microsoft_docs_fetch` | Microsoft Learn MCP Server | Same, for Azure |
   | `search_documents`, `get_documents`, `answer_query` | Google Developer Knowledge MCP | Same, for Google Cloud |
   | the artifacts tool | Artifacts | Plan, design and report files to download |
   | the code tool | Code Interpreter | The price fetch in `cost-projection` |

   Report in a short table what is there and what is missing, and only the missing ones the PoC needs.

### Overview

List the stages in the order a PoC uses them, each with one example request in the user's language:

1. `plan-builder`: "I want to plan a PoC. We need to decide whether …"
2. `architecture-design`: "Design the architecture and the tables. Here are the source schema, sample rows and our
   main queries."
3. `fit-gap`: "We created the tables. Does the service match the design, and what should we do next?"
4. `schema-query-advisor`: "Review the table design and queries using the last 7 days."
5. `sizing-stats`: "Show the sizing statistics for the last 7 days."
6. `load-test-review`: "Review the load test from 10:00 to 10:20 JST today." or "Compare these two runs."
7. `daily-progress`: "Write today's PoC note."
8. `summary`: "Write the PoC summary for this week's review."
9. `cost-projection`: "Project the monthly cost in production: …"
10. `share-report`: "Write a share report for our SA."

Then say: the user builds the service and the tables, the agent's connection is read-only, queries on the user's
own tables run only after approval, and the plan and design files carry what the next stage needs (see "Attaching
the plan and the design").

### Adding an MCP server

Common steps (https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/mcp-servers):

1. In ClickHouse Agents, open **MCP settings** in the left bar → **Add MCP**.
2. Enter a name, the URL below, transport **Streamable HTTPS**, and the authentication below. Tick **I trust this
   application** and click **Create MCP server**.
3. If the server uses OAuth, click **Connect** on it and sign in in the window that opens.
4. Open **Agent Builder**, open this agent, **Add tools**, and add only the tools listed below for that server.
   Click **Save** and wait for the "updated" notification; otherwise the change can be lost.
5. Start a new chat with the agent so the new tools are loaded.

| Server | URL | Authentication | Tools to add |
|---|---|---|---|
| ClickHouse Cloud remote MCP | `https://mcp.clickhouse.cloud/mcp` | OAuth (sign in with the Cloud user) | `get_organizations`, `get_services_list`, `get_service_details`, `get_organization_cost`, `list_service_backups`, `get_service_backup_configuration`, `list_clickpipes`, `get_clickpipe` |
| AWS Knowledge MCP Server (https://awslabs.github.io/mcp/servers/aws-knowledge-mcp-server) | `https://knowledge-mcp.global.api.aws` | **No auth** (rate limited) | `aws___search_documentation`, `aws___read_documentation`, `aws___list_regions`, `aws___get_regional_availability` |
| Microsoft Learn MCP Server (https://learn.microsoft.com/training/support/mcp) | `https://learn.microsoft.com/api/mcp` | **No auth** (subject to the Microsoft Learn terms) | `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search` |
| Google Developer Knowledge MCP (https://developers.google.com/knowledge/mcp) | `https://developerknowledge.googleapis.com/mcp` | **OAuth** with a client from the user's own Google Cloud project (below) | `search_documents`, `get_documents`, `answer_query` |

- The ClickHouse Cloud server's query tools duplicate the built-in ones; do not add them.
- AWS and Microsoft were added with **No auth** in testing (2026-10-16) and chats did not wait for a sign-in. Google
  has not been tested yet in ClickHouse Agents; say so.
- What is sent: the text of each search goes to the provider. The stages send only general questions (a provider
  service, a region, a feature), never the company name, table or column names, data values, account IDs or
  service names.

Google needs an OAuth client first, because Google's remote MCP servers do not support dynamic client
registration (https://developers.google.com/knowledge/mcp). In the user's Google Cloud project:

1. Enable the Developer Knowledge API (`developerknowledge.googleapis.com`).
2. Set up the consent screen: **Branding**, **Audience** (add the user as a test user while it is in testing).
3. Create an OAuth client of type **Web application** with the redirect URI
   `https://ai.clickhouse.cloud/api/mcp/<server name>/oauth/callback`, where `<server name>` is the name given in
   **MCP settings**. This is the callback path in the LibreChat documentation
   (https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/mcp_servers); it has not been
   confirmed in ClickHouse Agents yet. If Google reports a redirect URI mismatch, the URI it shows is the one to
   register.
4. In **MCP settings**, choose **OAuth** and enter the client ID and the secret there, with the scope
   `https://www.googleapis.com/auth/devprofiles.full_control`. No project header is needed: requests are attributed
   to the project that owns the client.

Do not suggest an API key for Google: a fixed key would sit in the Agents settings.

### Fixing a connection

| What the user sees | What to do |
|---|---|
| The agent asks to connect to ClickHouse, or the ClickHouse tools fail to authorize | **MCP settings** → **ClickHouse** → **Connect**. The agent sees only the organizations and services the Cloud user can access. |
| A query fails with "Generative AI features are not enabled for service …" | In the Cloud console, open the service → **Settings** → turn on **Enable Generative AI features**. An organization admin accepts the terms for AI features for the organization. |
| The service is not found, or its queries fail although the user can see it | In the Cloud console, open the service → **Connect** → **MCP** under **Connect with** → turn on **Enable Model Context Protocol** (https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp). |
| Every chat waits for a sign-in | One of the agent's tools belongs to a server that needs a sign-in (for example ClickStack or Google). Sign in under **MCP settings**, or remove that server's tools from the agent and **Save**. |
| The plan or the design is not found | Attach it as described below; then start a new chat. |
| The answer does not start by loading this skill | The chat is with the built-in ClickHouse Agent, whose skills are off. Start the chat with this agent. |

### Attaching the plan and the design

1. Download the file the stage wrote (`poc-plan-<name>.md` or `poc-design-<name>.md`).
2. In **Agent Builder**, open this agent, under **File context** click **Add** and upload the file. Click **Save**.
3. When the file changes (for example new lines in `## Results`), upload the new version and remove the old one.

Everyone who can use the agent can read these files, so use one agent per PoC.

### Upgrading

Skills cannot be replaced in place, and deleting a skill removes it from the agent:

1. Download `poc-assistant-skill.zip` from
   https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest .
2. In **Skills**, open `poc-assistant` and delete it. (An upload with the same name as an existing skill fails.)
3. **Create skill** (+) → **Upload skill** → choose the zip.
4. In **Agent Builder**, open the agent, add `poc-assistant` again under **Skills**, click **Save** and wait for the
   "updated" notification.

### Limitations

- Scheduled chats: creating a schedule for an agent with the ClickHouse tool kept showing "Reconnect this MCP server
  before enabling the schedule." in testing (2026-10-08). Ask for the daily note in a chat instead.
- Memory: memories created by hand did not reach the agent in testing, so the plan is passed as file context.
- There is no API to call the agent from outside.
