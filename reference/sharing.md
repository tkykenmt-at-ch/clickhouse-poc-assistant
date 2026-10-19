# Sharing results with ClickHouse

Rules every stage follows, so that what the assistant finds does not stay only with the user and can be checked by the ClickHouse team, without customer data leaving the conversation.

## When to show the notice

- **Rule**: show this one-line notice, translated into the user's language, only (1) at the end of the first answer in a conversation, and (2) at the end of a `summary`, `cost-projection` or `share-report` stage output, because those are used for decisions. Do not repeat it on other answers. Show it once per output: when the output is a file (an artifact or a code block, such as the `summary` stage's document), put it at the end of the file and not again in the chat message around it. Text: "This assistant can make mistakes; check findings with your ClickHouse SA before you decide." In Japanese: 「このアシスタントは誤ることがあります。判断の前に、必要に応じて担当 SA に確認してください。」
- **Rule**: mention the share report (the `share-report` stage) only when the user wants to share results with ClickHouse or asks how to, not as part of the notice.

## What a share report may contain

- **Allowed**: the stage that produced each finding and the period it covered; the service's cloud, region, ClickHouse version, tier (from `organizationTier` only; never another label from the service list, and no comparison with one), replica count and memory per replica; numbers that are aggregates (counts, bytes, ratios, percentiles, CPU seconds, CHC); `query_hash` values; error codes and their counts; the names of the checks used and their URLs; each success criterion's metric, pass threshold, result and status; questions for the SA.
- **Not allowed**: row values from any table; query text, `sample_query` or any literal value taken from a query; database, table, column, view, dictionary and ClickPipe names (replace each with a label such as `table A`, `column A.1`, the same label for the same name throughout); user names, e-mail addresses, IP addresses, hostnames, endpoints, IAM roles, organization and service IDs, access key IDs; ClickPipes source details; the text of the PoC plan beyond the criteria's metric, threshold and status; file names the user attached.
- **Rule**: when a finding cannot be stated without a not-allowed item (for example, it is about a specific value), describe it in general terms ("a filter on a high-cardinality string column") or leave it out and list it as left out. When you describe what a label stands for, use its role ("a fact table", "a dimension table"), not a word that is part of its real name (for example, not "an orders table" for a table named `orders`).

## How to write it

- **Rule**: write one Markdown document named `poc-share-<YYYY-MM-DD>.md`, as an artifact or a code block the user can download. Sections: **Context** (service facts allowed above, period, the stages used); **Findings** (at most ten, each with the numbers, the check and its URL, and how confident the finding is: measured, inferred or not verified); **Success criteria** (if a plan was used); **Questions for the SA**; **Left out** (what was replaced by labels or removed, as counts by kind, not the names). Write the section headings and the confidence words in the report's language (in Japanese: 前提、発見事項、成功基準、SA への質問、外したもの; 実測、推定、未確認).
- **Rule**: before showing it, read it again against "Not allowed" and fix anything that slipped in. Then tell the user that the report has no data from their tables and no names, that the label mapping stays only in this chat, and that they should read it before sending. The user sends it; the assistant does not send, post or upload it anywhere.
