#!/usr/bin/env bash
# Build the distributable zips into dist/:
#   ch-sizing-export.zip     export kit for users (README in English and Japanese, setup_user.sql, export.sh, queries/)
#   poc-assistant-skill.zip  the one skill for ClickHouse Agents: SKILL.md, stages/, exactly the files they
#                            reference (queries/.../*.sql, reference/*.md, tools/*.py), and the public skills it
#                            bundles under vendor/ (downloaded by fetch-public-skills.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"; TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
rm -rf "$DIST"; mkdir -p "$DIST"

kit="$TMP/ch-sizing-export"
mkdir -p "$kit/queries/optional"
cp "$ROOT"/export/{README.md,README.ja.md,setup_user.sql,export.sh} "$ROOT/LICENSE" "$kit/"
cp "$ROOT"/queries/*.sql "$kit/queries/"
cp "$ROOT"/queries/optional/*.sql "$kit/queries/optional/"
(cd "$TMP" && zip -qr "$DIST/ch-sizing-export.zip" ch-sizing-export)

name=poc-assistant
src="$ROOT/clickhouse-agents/skills/$name"
out="$TMP/skills/$name"
mkdir -p "$out/stages"
cp "$src/SKILL.md" "$ROOT/LICENSE" "$out/"
cp "$src"/stages/*.md "$out/stages/"

# The agent cannot list folders, so SKILL.md names every stage file, and every stage file is listed there.
for f in "$src"/stages/*.md; do
  grep -q "stages/$(basename "$f")" "$src/SKILL.md" || { echo "SKILL.md does not list stages/$(basename "$f")" >&2; exit 1; }
done
# Stage files named anywhere (SKILL.md, stages, reference files) must exist.
{ cat "$src/SKILL.md" "$src"/stages/*.md "$ROOT"/reference/*.md | grep -oE 'stages/[A-Za-z0-9_-]+\.md' || true; } | sort -u | while read -r s; do
  [ -f "$src/$s" ] || { echo "$s is named but does not exist" >&2; exit 1; }
done

# Ship exactly the files SKILL.md and the stage files name. Reference files can point to other reference files
# and to queries; ship those too (until nothing new is found).
pat='(queries/[A-Za-z0-9_/]+\.sql|reference/[A-Za-z0-9_-]+\.md|tools/[A-Za-z0-9_-]+\.py)'
refs="$(cat "$src/SKILL.md" "$src"/stages/*.md | grep -oE "$pat" | sort -u)"
while :; do
  more="$(for r in $refs; do case "$r" in reference/*) if [ -f "$ROOT/$r" ]; then grep -oE "$pat" "$ROOT/$r" || true; fi;; esac; done | sort -u)"
  all="$(printf '%s\n%s\n' "$refs" "$more" | grep -v '^$' | sort -u)"
  [ "$all" = "$refs" ] && break
  refs="$all"
done
for ref in $refs; do
  [ -f "$ROOT/$ref" ] || { echo "$ref does not exist" >&2; exit 1; }
  mkdir -p "$out/$(dirname "$ref")"
  cp "$ROOT/$ref" "$out/$ref"
done

# Public skills, unmodified, under vendor/. Every vendor file SKILL.md or a stage names must exist.
"$ROOT/scripts/fetch-public-skills.sh" "$out/vendor"
{ cat "$src/SKILL.md" "$src"/stages/*.md | grep -oE 'vendor/[A-Za-z0-9_./-]+\.(md|yaml)' || true; } | sort -u | while read -r v; do
  [ -f "$out/$v" ] || { echo "$v is named but the vendored skill does not have it" >&2; exit 1; }
done

# Every core query must be listed by the sizing stage.
for f in "$ROOT"/queries/*.sql; do
  grep -q "queries/$(basename "$f")" "$src/stages/sizing-stats.md" \
    || { echo "stages/sizing-stats.md does not list queries/$(basename "$f")" >&2; exit 1; }
done

(cd "$TMP/skills" && zip -qr "$DIST/$name-skill.zip" "$name")
unzip -l "$DIST/$name-skill.zip" | tail -1
ls -l "$DIST"
