#!/usr/bin/env bash
# Dog-1: Obsidian absent + ripgrep only. Expect Tier 4 notice on search.
set -e

ROOT="${CLAUDE_DISCODE_HOME:-/thiscode}"
VAULT="${CLAUDE_DISCODE_VAULT:-$ROOT/sample-vault}"
DISP="$ROOT/skills/search/references/tier-implementations.md.sh"

if [ ! -d "$VAULT" ]; then
  echo "scenario-1 SKIP: sample-vault not present at $VAULT (run Phase A first)"
  exit 0
fi

echo "[Dog-1] Tier 4 (ripgrep) only — forcing CLAUDE_DISCODE_FORCE_TIER=4"
OUT=$(CLAUDE_DISCODE_VAULT="$VAULT" CLAUDE_DISCODE_FORCE_TIER=4 bash "$DISP" "회사" 2>&1 || true)
echo "$OUT" | head -5
echo "$OUT" | grep -q "Tier 4: 텍스트 검색 결과입니다" \
  || { echo "FAIL Dog-1: Tier 4 notice missing"; exit 1; }

echo "PASS Dog-1"
