#!/usr/bin/env bash
# tier-implementations.md.sh — Tier 1-4 dispatcher used by claude-discode-search skill.
# Honors $CLAUDE_DISCODE_FORCE_TIER for testing.
set -e

QUERY="$1"
VAULT="${CLAUDE_DISCODE_VAULT:-$HOME/obsidian-ai-vault}"
TOP_K=5
FORCE="${CLAUDE_DISCODE_FORCE_TIER:-0}"

try_tier1() {
  curl -s --connect-timeout 3 "http://127.0.0.1:8400/health" | grep -q ok || return 1
  QE=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$QUERY")
  curl -s --connect-timeout 3 \
    "http://127.0.0.1:8400/api/search?q=${QE}&top_k=${TOP_K}&mode=hybrid&dense_weight=0.3&sparse_weight=0.4&decomposed_weight=0.15&entity_weight=0.15"
}

try_tier2() {
  command -v obsidian >/dev/null || return 1
  obsidian search --vault "$VAULT" --query "$QUERY" --json 2>/dev/null
}

try_tier3() {
  # MCP cannot be called from bash; the skill harness routes here via mcp__vault-search__search.
  # In standalone bash test, this is treated as unavailable.
  return 1
}

try_tier4() {
  if command -v rg >/dev/null; then
    rg --type md --max-count 5 -l "$QUERY" "$VAULT" 2>/dev/null
  else
    grep -r -l --include='*.md' "$QUERY" "$VAULT"
  fi
}

case "$FORCE" in
  1) try_tier1 ;;
  2) try_tier2 ;;
  3) try_tier3 ;;
  4) try_tier4 && echo "[Tier 4: 텍스트 검색 결과입니다]" ;;
  *)
    try_tier1 || try_tier2 || try_tier3 || { try_tier4 && echo "[Tier 4: 텍스트 검색 결과입니다]"; }
    ;;
esac
