#!/usr/bin/env bash
# test-tier2-3-shape.sh — tier 2 + tier 3 produce either 20 results or skipped marker
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$ROOT/benchmark/results"

VAULT="$ROOT/sample-vault" bash "$ROOT/benchmark/runners/tier2.sh" --output "$ROOT/benchmark/results/tier2-test.json"
VAULT="$ROOT/sample-vault" bash "$ROOT/benchmark/runners/tier3.sh" --output "$ROOT/benchmark/results/tier3-test.json"

for t in 2 3; do
  f="$ROOT/benchmark/results/tier$t-test.json"
  if jq -e '.skipped == true' "$f" >/dev/null 2>&1; then
    echo "tier$t SKIPPED: $(jq -r '.reason' "$f")"
  else
    COUNT=$(jq '. | length' "$f")
    if [ "$COUNT" != "20" ]; then
      echo "FAIL tier$t: expected 20 or skipped, got $COUNT"
      exit 1
    fi
    echo "tier$t MEASURED: $COUNT results"
  fi
done
echo "PASS tier2 + tier3 shape"
