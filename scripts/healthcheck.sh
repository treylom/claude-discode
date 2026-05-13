#!/usr/bin/env bash
set -e

echo "claude-discode healthcheck v2.1 — Phase progress"
echo "─────────────────────────────────"

ok=0 fail=0 skip=0

phase_check() {
  local phase="$1" name="$2" cmd="$3" required="$4"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "%s %-40s : OK\n" "" "$phase $name"
    ok=$((ok + 1))
  elif [ "$required" = "required" ]; then
    printf "%s %-40s : FAIL\n" "" "$phase $name"
    fail=$((fail + 1))
  else
    printf "%s %-40s : NOT YET\n" "" "$phase $name"
    skip=$((skip + 1))
  fi
}

phase_check "Phase 1" "ripgrep (Tier 4)"              "command -v rg || command -v grep" "required"
phase_check "Phase 2" "obsidian-cli (Tier 3)"         "command -v obsidian-cli || command -v obsidian" "optional"
phase_check "Phase 3" "vault-search MCP (Tier 2)"     "jq -e '.mcpServers.\"vault-search\"' ${HOME}/.config/claude/claude_desktop_config.json 2>/dev/null" "optional"
phase_check "Phase 4" "GraphRAG (Tier 1)"             "curl -fsS http://localhost:8400/health 2>/dev/null" "optional"

echo "─────────────────────────────────"
printf "Summary: %d OK, %d FAIL, %d NOT YET\n" "$ok" "$fail" "$skip"
