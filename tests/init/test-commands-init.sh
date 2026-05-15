#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/commands/init.md"

test -f "$F" || { echo "FAIL: commands/init.md missing"; exit 1; }
grep -q "thiscode-init.sh" "$F" || { echo "FAIL: script invocation missing"; exit 1; }
grep -q "Phase 0~7" "$F" || { echo "FAIL: phase reference missing"; exit 1; }
echo "PASS commands/init.md"
