#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

grep -q '2: "vault-search MCP"' "$ROOT/benchmark/report-generator.py" || { echo "FAIL: tier 2 should be MCP"; exit 1; }
grep -q '3: "Obsidian CLI"' "$ROOT/benchmark/report-generator.py" || { echo "FAIL: tier 3 should be CLI"; exit 1; }
echo "PASS tier label v2"
