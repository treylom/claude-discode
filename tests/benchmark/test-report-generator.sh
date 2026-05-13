#!/usr/bin/env bash
# test-report-generator.sh — run-all + report-generator produce expected markdown table
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP: python3 not installed"
  exit 0
fi

VAULT="$ROOT/sample-vault" BENCHMARK_SKIP_TIER1=1 bash "$ROOT/benchmark/runners/run-all.sh"

TABLE=$(python3 "$ROOT/benchmark/report-generator.py" --print-only)

echo "$TABLE" | grep -q "| Tier |" || { echo "FAIL: missing header"; exit 1; }
echo "$TABLE" | grep -q "ripgrep" || { echo "FAIL: missing tier4 row"; exit 1; }
echo "$TABLE" | grep -q "Last updated:" || { echo "FAIL: missing timestamp"; exit 1; }
echo "PASS report-generator"
echo "---"
echo "$TABLE"
