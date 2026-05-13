#!/usr/bin/env bash
# tier2.sh — Tier 2 vault-search MCP runner (skip — MCP requires Claude Code runtime)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/_lib.sh"

VAULT="${VAULT:?VAULT env required}"
OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$OUT" ] || { echo "FAIL: --output required"; exit 1; }

CFG="${HOME}/.config/claude/claude_desktop_config.json"
if ! jq -e '.mcpServers."vault-search"' "$CFG" >/dev/null 2>&1; then
  jq -n '{ "skipped": true, "reason": "vault-search MCP not configured" }' > "$OUT"
  echo "tier2 SKIPPED: vault-search MCP missing"
  exit 0
fi

# vault-search MCP must be invoked from Claude Code runtime (host process).
# Bash cannot call MCP tools. Emit skip with note for docs/BENCHMARK.md.
jq -n '{ "skipped": true, "reason": "MCP requires Claude Code runtime — run benchmark from inside `claude code` session" }' > "$OUT"
echo "tier2 SKIPPED: MCP runtime not available in shell"
exit 0
