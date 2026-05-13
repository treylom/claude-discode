#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# v2.0: tier2.sh = MCP runner, tier3.sh = CLI runner
grep -q "vault-search MCP" "$ROOT/benchmark/runners/tier2.sh" || { echo "FAIL: tier2 should be MCP"; exit 1; }
grep -q "obsidian-cli" "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: tier3 should be CLI"; exit 1; }

# tier label consistency
grep -q 'emit_result "$qid" 2' "$ROOT/benchmark/runners/tier2.sh" || \
  grep -q '"tier":2' "$ROOT/benchmark/runners/tier2.sh" || \
  echo "INFO: tier2.sh has no emit_result (MCP skip-only — OK)"
grep -q 'emit_result "$qid" 3' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: tier3 emit_result tier=3"; exit 1; }

echo "PASS tier swap"
