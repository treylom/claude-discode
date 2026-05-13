#!/usr/bin/env bash
# v2.0.1 — tier3.sh syntax + stdin redirect fix verification
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Mac binary KEY=VALUE syntax 시도 함수 존재
grep -q "search_obsidian()" "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: search_obsidian fallback function missing"; exit 1; }

# KEY=VALUE syntax (Mac) 호출
grep -q '"query=\$qtext" "limit=5" "format=text"' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: Mac KEY=VALUE syntax missing"; exit 1; }

# stdin redirect (</dev/null)
grep -c "</dev/null" "$ROOT/benchmark/runners/tier3.sh" | xargs -I{} test {} -ge 2 || { echo "FAIL: </dev/null not in both syntax branches"; exit 1; }

# yq output capture (mktemp + cleanup)
grep -q "QIDS_TMP" "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: tempfile capture missing"; exit 1; }

echo "PASS tier3 syntax v2.0.1"
