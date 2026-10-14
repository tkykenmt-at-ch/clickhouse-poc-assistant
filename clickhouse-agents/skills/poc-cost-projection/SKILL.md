---
name: poc-cost-projection
description: Projects the monthly list-price cost of a production ClickHouse Cloud service from the PoC - from the PoC's own bill scaled to the user's production assumptions, and from the public price list - with every formula, rate and its date shown. Use when the user asks for a cost estimate, cost projection, monthly cost, "費用試算", "コスト試算", "本番の費用" or "月額".
always-apply: false
user-invocable: true
---

# PoC cost projection

You project what a production service would cost per month at list price, from what the PoC measured and from public prices. You read **system tables**, the Cloud tools for this service's bill when they are available, and the public price list, read live with `tools/fetch_url.py` or from its daily copy in `reference/pricing-snapshot.md`. Never select rows from the user's own tables.

## Rules

- Read `reference/cost-projection.md` first and follow it. It says which rates to use, both methods and what every projection must state.
- The result is a list-price projection, not a quote. Say so at the top, with the date of the rates, and point to the calculator on https://clickhouse.com/pricing for a quotable figure.
- Do not recommend a size, a tier or a price. The production assumptions are the user's; for measured sizing inputs, point to the `poc-sizing-stats` skill.
- Every number comes from a query or tool result in this conversation, from the price list fetched in this conversation, or from the user. Label each with where it came from. If a query or tool fails, say which and why; do not fill the gap.
- Before the first query, ask whether a load test or another measured run is going on now. If it is, wait until it ends.
- Reading system tables wakes an idled service and keeps it awake. Read `reference/checks-cloud-service.md` for this, for services in a warehouse and for the Cloud tools.
- Do not output user names or e-mail addresses, and do not output endpoints, the IP access list, the IAM role or ClickPipes source details.
- Answer in the user's language (Japanese if the user writes in Japanese).

## Steps

1. Ask for the production assumptions in one message, and say that any can be left blank: tier, cloud and region; replicas and memory per replica; hours active per day; data kept (compressed TB, or uncompressed volume per day and days kept); backup retention; egress per month (public internet and inter-region); ClickPipes (type, replicas and size, GB per month). Say that the PoC's measured values will be shown next to them.
2. Read and run these files with `30 /*days*/` replaced by 7. The paths are exact. If a query fails because settings cannot be changed, remove the final `SETTINGS skip_unavailable_shards = 1` line and run it again.
   - `queries/01_service.sql`
   - `queries/02_tables.sql`
   - `queries/04_ingest_daily.sql`
   - `queries/08_resources_hourly.sql`
3. If a `get_services_list` tool is available, read this service's entry (memory range, replicas, idling). If the Cloud tools are available, read the last 7 full days of this service's cost, one or two days per call, as `reference/cost-projection.md` says. Without them, say method A needs the daily cost from the console's usage breakdown and ask the user whether to paste it.
4. Read the price list as "Reading the price list" in `reference/cost-projection.md` says. With the code tool, this skill's files are under `/mnt/data/skills/poc-cost-projection/`, so run `python3 /mnt/data/skills/poc-cost-projection/tools/fetch_url.py https://clickhouse.com/pricing.md --section ...`. Then pick the rates by the rules in "Where the rates come from".
5. Write the projection below.

## Projection format

- **Summary**: two or three sentences: total per month by method A and by method B, the tier, cloud and region, the rate date, and that these are list prices, not a quote.
- **Assumptions**: a table with one row per production assumption: the user's value (or "not given"), and the PoC's measured value with its source.
- **Rates**: compute and storage rates with tier, cloud, region and source (the price list with its fetch time, or the copy with its "Copied on" date; derived from the bill with the day used, or read by the user with the date), plus the egress and ClickPipes rates used.
- **Method A**: a table per line item: PoC actual per day and per month, production projection per month, ratio, formula with inputs. Name days left out or unusual.
- **Method B**: a table per line item with the formula and inputs filled in, then the total.
- **Not included**: line items without an input, and anything the price list does not cover (discounts, commitments, Postgres CDC ClickPipes, support).
- **Evidence**: the queries and tool calls you ran.
