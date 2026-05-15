#!/usr/bin/env bash
# Test: install-vault-search.sh creates MCP config entry without overwriting other servers.
# Uses CLAUDE_DISCODE_SKIP_BUILD=1 to skip git clone + npm install (heavy steps covered by dogfood T3.2).
set -e

TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.config/claude"
cat > "$TMPDIR/.config/claude/claude_desktop_config.json" <<'JSON'
{ "mcpServers": { "other-mcp": { "command": "node", "args": ["/some/path"] } } }
JSON

SCRIPT="$HOME/code/thiscode/scripts/install-vault-search.sh"

# Dry-run: verify output mentions adding vault-search
HOME="$TMPDIR" bash "$SCRIPT" --dry-run | \
  grep -q "would add: vault-search" || { echo "FAIL: dry-run output"; exit 1; }

# Apply (build skipped): verify merge into existing config
HOME="$TMPDIR" CLAUDE_DISCODE_SKIP_BUILD=1 bash "$SCRIPT" --apply >/dev/null

jq -e '.mcpServers."vault-search" and .mcpServers."other-mcp"' \
  "$TMPDIR/.config/claude/claude_desktop_config.json" >/dev/null \
  || { echo "FAIL: merge"; exit 1; }

echo "PASS"
rm -rf "$TMPDIR"
