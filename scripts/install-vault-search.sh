#!/usr/bin/env bash
# install-vault-search.sh — install vault-search MCP server + register in Claude config.
set -e

DRY=0; APPLY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  --apply) APPLY=1 ;;
  *) DRY=1 ;;
esac

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/claude_desktop_config.json"
REPO_DIR="${CLAUDE_DISCODE_HOME:-$HOME/code/claude-discode}/vendor/vault-search-mcp"
SKIP_BUILD="${CLAUDE_DISCODE_SKIP_BUILD:-0}"

# Stage 1: clone or update the MCP source (vendored from agent-office/vault-search-mcp)
if [ "$APPLY" = "1" ] && [ "$SKIP_BUILD" = "0" ]; then
  if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/treylom/vault-search-mcp "$REPO_DIR" 2>/dev/null || {
      echo "TODO: vendor vault-search-mcp into claude-discode/vendor/ first" >&2
      exit 3
    }
  fi
  (cd "$REPO_DIR" && npm install --silent && npm run build --silent)
fi

# Stage 2: merge into Claude config (preserve other servers)
mkdir -p "$(dirname "$CFG")"
[ -f "$CFG" ] || echo '{"mcpServers":{}}' > "$CFG"

NEW_ENTRY=$(jq -n --arg cmd "node" --arg path "$REPO_DIR/dist/index.js" \
  '{ command: $cmd, args: [$path] }')

if [ "$DRY" = "1" ]; then
  echo "would add: vault-search → $REPO_DIR/dist/index.js"
  exit 0
fi

TMP=$(mktemp)
jq --argjson entry "$NEW_ENTRY" '.mcpServers["vault-search"] = $entry' "$CFG" > "$TMP"
mv "$TMP" "$CFG"
echo "installed: vault-search MCP registered in $CFG"
