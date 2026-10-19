# PoC Assistant

[GitHub repository](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant) · [Latest release](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest)

An agent for [ClickHouse Agents](https://clickhouse.com/docs/products/cloud/features/ai-ml/agents) that helps run a ClickHouse Cloud proof of concept. It reads the service's system tables and the official documentation, and answers with the numbers and the sources behind them. It is an open-source project (Apache-2.0), not a supported ClickHouse product.

| Page | What it covers |
|---|---|
| [Setup](setup.md) | Install the skill, create the agent, and the optional MCP servers |
| [Walkthrough](walkthrough.md) | One PoC on synthetic data, from the plan to the share report, with screenshots |
| [Development](development.md) | Repository layout, build and test, query conventions |

Once the agent exists, it explains its own setup: ask it "What can you do?" or "How do I add an MCP server?".
