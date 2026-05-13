#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/claude-discode-init/SKILL.md"
YAML="$ROOT/.agents/claude-discode-init.yaml"

test -f "$SKILL" || { echo "FAIL: SKILL.md missing"; exit 1; }
test -f "$YAML" || { echo "FAIL: agent yaml missing"; exit 1; }
yq -e '.name == "claude-discode-init"' "$YAML" >/dev/null
yq -e '.provides_commands | contains(["/claude-discode:init"])' "$YAML" >/dev/null
grep -q "8 Phase" "$SKILL"
echo "PASS skill init"
