#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT=$(bash "$ROOT/scripts/healthcheck.sh" 2>&1)
echo "$OUT" | grep -q "Phase" || { echo "FAIL: Phase output missing"; exit 1; }
echo "$OUT" | grep -qE "(Phase 1|Phase 2|Phase 3|Phase 4)" || { echo "FAIL: Phase numbers missing"; exit 1; }
echo "PASS healthcheck phase output"
