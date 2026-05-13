#!/usr/bin/env bash
# test-index-roundtrip.sh — generate agents.yaml then verify it matches .agents/*.yaml
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

node scripts/generate-agents-index.mjs --apply >/dev/null
node scripts/check-agents-index.mjs
echo "PASS index roundtrip"
