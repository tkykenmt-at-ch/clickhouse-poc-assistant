#!/usr/bin/env bash
# Refresh reference/pricing-snapshot.md from the Markdown version of the pricing page
# (https://clickhouse.com/pricing.md). Keeps the parts about ClickHouse services and drops the
# ClickStack, Postgres and BYOC sections. The skills read this copy when they cannot fetch the
# page live (the code sandbox in ClickHouse Agents has no network). The pricing workflow runs
# this every day and releases when the copied content changed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/reference/pricing-snapshot.md"
src="$(curl -fsSL https://clickhouse.com/pricing.md)"
grep -q '^## Compute & storage rates by region' <<<"$src" || { echo "pricing.md has no rate table; the page changed" >&2; exit 1; }
{
  echo "# Pricing snapshot"
  echo
  echo "Copied on $(date -u +%Y-%m-%d) from https://clickhouse.com/pricing.md by \`scripts/fetch-pricing.sh\`. Rates change; state this date with every figure taken from here and point to https://clickhouse.com/pricing for a current one."
  echo
  # Drop the front matter, the page title, and sections that are not about ClickHouse services.
  awk '
    NR == 1 && /^---$/ { fm = 1; next }
    fm { if (/^---$/) fm = 0; next }
    /^# / { next }
    /^## / { skip = ($0 ~ /^## (ClickStack|ClickHouse Cloud for Postgres|Bring Your Own Cloud|Pricing philosophy)/) }
    !skip { print }
  ' <<<"$src"
} > "$OUT"
echo "$OUT: $(grep -c '^| .* | enterprise |' "$OUT") rate rows"
