#!/usr/bin/env bash
# validate-agents.sh — JSON Schema validate all .agents/*.yaml against schemas/agent-spec.json
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$ROOT/schemas/agent-spec.json"

if ! command -v ajv >/dev/null 2>&1; then
  echo "FAIL: ajv-cli not installed. Run: npm install -g ajv-cli ajv-formats"
  exit 1
fi

FAIL=0
COUNT=0
for f in "$ROOT"/.agents/*.yaml; do
  [ -e "$f" ] || continue
  COUNT=$((COUNT + 1))
  if ! ajv validate -s "$SCHEMA" -d "$f" --spec=draft2019 --strict=false -c ajv-formats >/dev/null 2>&1; then
    echo "FAIL schema: $f"
    ajv validate -s "$SCHEMA" -d "$f" --spec=draft2019 --strict=false -c ajv-formats 2>&1 | sed 's/^/  /'
    FAIL=1
  fi
done

if [ "$FAIL" = "0" ]; then
  echo "PASS validate-agents (count=$COUNT)"
fi
exit "$FAIL"
