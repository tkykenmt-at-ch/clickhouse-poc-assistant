# Sharing results with ClickHouse

Rules every skill follows at the end of its output, so that what the assistant finds does not stay only with the user and can be checked by the ClickHouse team, without customer data leaving the conversation.

## Notice at the end of every output

- **Rule**: end every output with this notice, translated into the user's language: "This assistant can make mistakes. Before you decide on design, sizing or cost, check the findings with your ClickHouse Solutions Architect (SA) as needed. To share them, ask for a share report (`poc-share-report`): it leaves out your data." In Japanese: 「このアシスタントは誤ることがあります。設計・サイジング・費用を決める前に、必要に応じて ClickHouse の担当 SA に確認してください。共有するときは、データを含めない共有用レポート（`poc-share-report`）を頼んでください。」

## What a share report may contain

- **Allowed**: the skill that produced each finding and the period it covered; the service's cloud, region, ClickHouse version, tier, replica count and memory per replica; numbers that are aggregates (counts, bytes, ratios, percentiles, CPU seconds, CHC); `query_hash` values; error codes and their counts; the names of the checks used and their URLs; each success criterion's metric, pass threshold, result and status; questions for the SA.
- **Not allowed**: row values from any table; query text, `sample_query` or any literal value taken from a query; database, table, column, view, dictionary and ClickPipe names (replace each with a label such as `table A`, `column A.1`, the same label for the same name throughout); user names, e-mail addresses, IP addresses, hostnames, endpoints, IAM roles, organization and service IDs, access key IDs; ClickPipes source details; the text of the PoC plan beyond the criteria's metric, threshold and status; file names the user attached.
- **Rule**: when a finding cannot be stated without a not-allowed item (for example, it is about a specific value), describe it in general terms ("a filter on a high-cardinality string column") or leave it out and list it as left out.

## How to write it

- **Rule**: write one Markdown document named `poc-share-<YYYY-MM-DD>.md`, as an artifact or a code block the user can download. Sections: **Context** (service facts allowed above, period, the skills used); **Findings** (at most ten, each with the numbers, the check and its URL, and how confident the finding is: measured, inferred or not verified); **Success criteria** (if a plan was used); **Questions for the SA**; **Left out** (what was replaced by labels or removed, as counts by kind, not the names).
- **Rule**: before showing it, read it again against "Not allowed" and fix anything that slipped in. Then tell the user that the report has no data from their tables and no names, that the label mapping stays only in this chat, and that they should read it before sending. The user sends it; the assistant does not send, post or upload it anywhere.
