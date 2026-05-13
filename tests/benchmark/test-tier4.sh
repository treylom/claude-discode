#!/usr/bin/env bash
# test-tier4.sh — Tier 4 ripgrep runner produces 20 results with required fields
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v rg >/dev/null 2>&1; then
  echo "SKIP: ripgrep not installed"
  exit 0
fi
if ! command -v yq >/dev/null 2>&1; then
  echo "SKIP: yq not installed"
  exit 0
fi

OUT="$ROOT/benchmark/results/tier4-test.json"
mkdir -p "$ROOT/benchmark/results"
rm -f "$OUT"

VAULT="$ROOT/sample-vault" bash "$ROOT/benchmark/runners/tier4.sh" --output "$OUT"

COUNT=$(jq '. | length' "$OUT")
if [ "$COUNT" != "20" ]; then
  echo "FAIL: expected 20 results, got $COUNT"
  exit 1
fi

jq -e '.[0] | (.query_id != null and .latency_ms != null and .recall_at_5 != null)' "$OUT" >/dev/null
echo "PASS tier4 runner ($COUNT results)"
