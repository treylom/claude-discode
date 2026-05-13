#!/usr/bin/env bash
# test-tier1-skip.sh — Tier 1 runner honors BENCHMARK_SKIP_TIER1 env
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$ROOT/benchmark/results"

VAULT="$ROOT/sample-vault" BENCHMARK_SKIP_TIER1=1 bash "$ROOT/benchmark/runners/tier1.sh" --output "$ROOT/benchmark/results/tier1-test.json"
if ! jq -e '.skipped == true' "$ROOT/benchmark/results/tier1-test.json" >/dev/null; then
  echo "FAIL: BENCHMARK_SKIP_TIER1=1 did not produce skipped marker"
  exit 1
fi
echo "PASS tier1 skip ($(jq -r '.reason' "$ROOT/benchmark/results/tier1-test.json"))"
