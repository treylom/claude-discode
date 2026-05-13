#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/docs/SETUP-BEGINNER.md"

grep -q "claude-discode init\|wizard\|init.sh" "$F" || { echo "FAIL: wizard 안내 누락"; exit 1; }
grep -q "8 Phase\|Phase progressive" "$F" || { echo "FAIL: 8 Phase 안내 누락"; exit 1; }
echo "PASS setup-beginner wizard"
