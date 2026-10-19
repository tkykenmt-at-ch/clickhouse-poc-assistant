#!/usr/bin/env bash
# Usage: fetch-public-skills.sh <dest>
# Download public ClickHouse skills (ClickHouse/agent-skills, Apache-2.0) unmodified, pinned to a commit,
# into <dest>/<skill>/ with their license. build.sh bundles them into the poc-assistant skill under vendor/.
set -euo pipefail
DEST="${1:?usage: fetch-public-skills.sh <dest>}"
REPO="ClickHouse/agent-skills"
# Pinned commit; override with AGENT_SKILLS_SHA only to test a newer upstream version.
SHA="${AGENT_SKILLS_SHA:-356a8c1b9a7392adb389a132f5ad3fec38532a03}"
SKILLS=(clickhouse-architecture-advisor)
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$DEST"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$SHA" | tar -xz -C "$TMP"
src="$(ls -d "$TMP"/agent-skills-*)"
for s in "${SKILLS[@]}"; do
  rm -rf "${DEST:?}/$s"
  cp -R "$src/skills/$s" "$DEST/$s"
  # Apache-2.0 requires a copy of the license with redistributed files.
  cp "$src/LICENSE" "$DEST/$s/LICENSE"
  echo "$DEST/$s from $REPO@${SHA:0:12}"
done
