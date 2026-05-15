#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/thiscode-init/SKILL.md"
YAML="$ROOT/.agents/thiscode-init.yaml"

test -f "$SKILL" || { echo "FAIL: SKILL.md missing"; exit 1; }
test -f "$YAML" || { echo "FAIL: agent yaml missing"; exit 1; }
yq -e '.name == "thiscode-init"' "$YAML" >/dev/null
yq -e '.provides_commands | contains(["/thiscode:init"])' "$YAML" >/dev/null
grep -q "8 Phase" "$SKILL"
echo "PASS skill init"
