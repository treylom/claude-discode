#!/usr/bin/env bash
# test-fixtures-shape.sh — verify queries.yaml shape (count + distribution + required fields)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$ROOT/benchmark/fixtures/queries.yaml"

if ! command -v yq >/dev/null 2>&1; then
  echo "SKIP: yq not installed"
  exit 0
fi

COUNT=$(yq '.queries | length' "$FIX")
if [ "$COUNT" != "20" ]; then
  echo "FAIL: expected 20 queries, got $COUNT"
  exit 1
fi

# Each query has id, text, expected_hits, category
if yq '.queries[] | select(.id == null or .text == null or .expected_hits == null or .category == null)' "$FIX" | grep -q .; then
  echo "FAIL: query missing required field"
  exit 1
fi

# Category distribution: factual 8 / concept 6 / cross-doc 4 / temporal 2
CAT_FACT=$(yq '[.queries[] | select(.category == "factual")] | length' "$FIX")
CAT_CON=$(yq '[.queries[] | select(.category == "concept")] | length' "$FIX")
CAT_CROSS=$(yq '[.queries[] | select(.category == "cross-doc")] | length' "$FIX")
CAT_TEMP=$(yq '[.queries[] | select(.category == "temporal")] | length' "$FIX")

if [ "$CAT_FACT" = "8" ] && [ "$CAT_CON" = "6" ] && [ "$CAT_CROSS" = "4" ] && [ "$CAT_TEMP" = "2" ]; then
  echo "PASS fixture shape (count=$COUNT, dist=$CAT_FACT/$CAT_CON/$CAT_CROSS/$CAT_TEMP)"
else
  echo "FAIL: category distribution $CAT_FACT/$CAT_CON/$CAT_CROSS/$CAT_TEMP (expected 8/6/4/2)"
  exit 1
fi
