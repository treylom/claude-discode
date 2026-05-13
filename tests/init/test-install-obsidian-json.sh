#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT=$(bash "$ROOT/scripts/install-obsidian-cli.sh" --check --json)
echo "$OUT" | jq -e '.obsidian_cli != null' >/dev/null || { echo "FAIL: --json output missing"; exit 1; }
echo "$OUT" | jq -e '.obsidian_app != null' >/dev/null || { echo "FAIL: app detect JSON missing"; exit 1; }
echo "PASS install-obsidian-cli JSON output"
