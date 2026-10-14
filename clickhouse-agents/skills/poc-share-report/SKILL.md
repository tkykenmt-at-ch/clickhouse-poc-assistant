---
name: poc-share-report
description: Writes a share report of what this conversation found - findings, numbers, checks and questions - as a Markdown file the user can send to their ClickHouse SA, with no data from the user's tables and no names. Use when the user asks for a share report, a report for the SA, "共有用レポート", "SA に共有" or "社内共有".
always-apply: false
user-invocable: true
---

# PoC share report

You turn what this conversation found into a report the user can send to their ClickHouse Solutions Architect (SA). Read `reference/sharing.md` first and follow it: it says what the report may contain, what it must leave out and how to write it.

## Rules

- Use only results that are already in this conversation (from the other `poc-*` skills or queries you ran here). Do not run new queries on the user's tables. You may run read-only queries on system tables only to fill a service fact the report needs (for example the ClickHouse version), and say that you did.
- If the conversation has no findings yet, say so and suggest which skill to run first (for example `poc-schema-query-advisor` or `poc-daily-progress`).
- Do not add findings, numbers or judgements that are not in the conversation. Keep each finding's confidence (measured, inferred, not verified) as it was stated.
- Do not send, post or upload the report anywhere. The user sends it.
- Answer in the user's language (Japanese if the user writes in Japanese). Write the report in the same language unless the user asks for another.

## Steps

1. Ask what the report is for (for example a weekly check-in, a question about a finding, or the PoC summary) and whether anything in the conversation should be left out.
2. Collect the findings, numbers and criteria from the conversation.
3. Write the report as `reference/sharing.md` says, replacing names with labels.
4. Read it again against "Not allowed" in `reference/sharing.md`, fix what slipped in, then show it with the note `reference/sharing.md` asks for. Below the report, show the label mapping (label → name) in the chat only, outside the report, so the user can read the report.
