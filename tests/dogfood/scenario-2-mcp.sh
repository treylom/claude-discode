#!/usr/bin/env bash
# Dog-2: vault-search MCP installed but no GraphRAG / Obsidian CLI. Tier 3 path.
# Note: MCP cannot be called from bash; this scenario covers config installation only.
set -e

ROOT="${CLAUDE_DISCODE_HOME:-/claude-discode}"

echo "[Dog-2] install-vault-search.sh dry-run + apply (build skipped for sandbox)"
HOME_DIR=$(mktemp -d)
HOME="$HOME_DIR" bash "$ROOT/scripts/install-vault-search.sh" --dry-run | \
  grep -q "would add: vault-search" || { echo "FAIL Dog-2 dry-run"; exit 1; }

HOME="$HOME_DIR" CLAUDE_DISCODE_SKIP_BUILD=1 bash "$ROOT/scripts/install-vault-search.sh" --apply >/dev/null
jq -e '.mcpServers."vault-search"' "$HOME_DIR/.config/claude/claude_desktop_config.json" >/dev/null \
  || { echo "FAIL Dog-2 merge"; exit 1; }

rm -rf "$HOME_DIR"
echo "PASS Dog-2"
