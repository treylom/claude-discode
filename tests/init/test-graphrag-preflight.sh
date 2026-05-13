#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
grep -q "^preflight()" "$ROOT/scripts/install-graphrag.sh" || { echo "FAIL: preflight function missing"; exit 1; }
grep -q "python3 --version" "$ROOT/scripts/install-graphrag.sh" || { echo "FAIL: python check missing"; exit 1; }
grep -q "5.*GB" "$ROOT/scripts/install-graphrag.sh" || { echo "FAIL: disk check missing"; exit 1; }
grep -q "8400" "$ROOT/scripts/install-graphrag.sh" || { echo "FAIL: port check missing"; exit 1; }
bash "$ROOT/scripts/install-graphrag.sh" --preflight 2>&1 | grep -qE "Python|disk|port" || { echo "FAIL: --preflight output missing"; exit 1; }
echo "PASS graphrag preflight"
