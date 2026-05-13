#!/usr/bin/env bash
# v2.0.2 — tier3.sh binary 이름 detection (obsidian-cli / obsidian / notesmd-cli) + stdin redirect
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# v2.0.2 — binary 이름 detection (3 binary)
grep -q "search_obsidian()" "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: search_obsidian function missing"; exit 1; }

# 공식 Obsidian CLI (obsidian-cli + obsidian) — KEY=VALUE syntax
grep -q 'command -v obsidian-cli' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: obsidian-cli detection missing"; exit 1; }
grep -q 'command -v obsidian ' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: obsidian (no suffix) detection missing"; exit 1; }
grep -q '"query=\$qtext" "limit=5" "format=text"' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: KEY=VALUE syntax missing"; exit 1; }

# Yakitrak/notesmd-cli — search-content syntax
grep -q 'command -v notesmd-cli' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: notesmd-cli detection missing"; exit 1; }
grep -q 'notesmd-cli search-content' "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: Yakitrak search-content syntax missing"; exit 1; }

# stdin redirect 3건 (3 binary 각각)
grep -c "</dev/null" "$ROOT/benchmark/runners/tier3.sh" | xargs -I{} test {} -ge 3 || { echo "FAIL: </dev/null not in all 3 syntax branches"; exit 1; }

# yq output capture (mktemp + cleanup)
grep -q "QIDS_TMP" "$ROOT/benchmark/runners/tier3.sh" || { echo "FAIL: tempfile capture missing"; exit 1; }

echo "PASS tier3 syntax v2.0.2"
