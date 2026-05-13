#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/skills/claude-discode-km-at/references/mode-r-preflight.md" || { echo "FAIL: preflight doc missing"; exit 1; }
grep -q "read-only" "$ROOT/skills/claude-discode-km-at/SKILL.md" || { echo "FAIL: SKILL.md read-only 안내 누락"; exit 1; }
grep -q "broken_wikilinks" "$ROOT/skills/claude-discode-km-at/references/mode-r-preflight.md" || { echo "FAIL: preflight checks 누락"; exit 1; }

echo "PASS km-at preflight doc"
