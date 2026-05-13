#!/usr/bin/env bash
# claude-discode healthcheck v1.0
# Exit codes (Round 2 outcome 표준): 0 = all required OK / 1 = required FAIL / 2 = intentional SKIP only

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${HOME}/.claude-discode-setup.log"

# Redact user-specific path in log entries (Round 2 outcome)
redact() {
  echo "$1" | sed -E "s|$HOME|/HOME|g; s|/Users/[^/]+|/Users/REDACTED|g; s|/home/[^/]+|/home/REDACTED|g"
}

echo "[$(date)] healthcheck start" >> "$LOG"

green() { printf "\033[32m✓\033[0m"; }
red()   { printf "\033[31m✗\033[0m"; }
gray()  { printf "\033[90m○\033[0m"; }

fail=0; skip=0; ok=0

check() {
  local name="$1" cmd="$2" required="$3"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "%s %-20s : OK\n" "$(green)" "$name"
    ok=$((ok + 1))
  elif [ "$required" = "required" ]; then
    printf "%s %-20s : FAIL\n" "$(red)" "$name"
    echo "[$(date)] FAIL $name ($(redact "$cmd"))" >> "$LOG"
    fail=$((fail + 1))
  else
    printf "%s %-20s : SKIP\n" "$(gray)" "$name"
    skip=$((skip + 1))
  fi
}

echo "claude-discode healthcheck v1.0"
echo "─────────────────────────────────"

check "Tier 4 (ripgrep)"  "command -v rg || command -v grep" required
check "Tier 3 (MCP)"      "jq -e '.mcpServers.\"vault-search\"' ${HOME}/.config/claude/claude_desktop_config.json" optional
check "Tier 2 (CLI)"      "command -v obsidian-cli" optional
check "Tier 1 (GraphRAG)" "curl -fsS http://localhost:8400/health" optional

echo "─────────────────────────────────"
if [ "$fail" -eq 0 ]; then
  echo "all required checks passed ✅ (ok=$ok, skip=$skip)"
  echo "[$(date)] healthcheck PASS" >> "$LOG"
  [ "$skip" -gt 0 ] && exit 2 || exit 0
else
  echo "some required checks failed ❌ (ok=$ok, fail=$fail, skip=$skip)"
  echo "see log: $LOG"
  echo "[$(date)] healthcheck FAIL" >> "$LOG"
  exit 1
fi
