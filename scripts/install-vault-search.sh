#!/usr/bin/env bash
# install-vault-search.sh — vault-search MCP server install + Claude config register (Tier 2).
# v2.1.1: v1.0.0 install 로직 + v2.1 note_count_check preflight 통합
set -e

VAULT_DEFAULT="${VAULT:-$HOME/obsidian-ai-vault}"

usage() {
  cat <<EOF >&2
Usage: $0 [--dry-run | --apply | --recommend-only]
  --dry-run         (default) 변경 없이 install 시뮬레이션
  --apply           실제 install (clone + npm install + npm run build + jq merge config)
  --recommend-only  note_count_check 만 (preflight 단계)

Env:
  VAULT                  vault root (default: \$HOME/obsidian-ai-vault)
  CLAUDE_CONFIG_DIR      Claude config dir (default: \$HOME/.config/claude)
  CLAUDE_DISCODE_HOME    thiscode repo root (default: \$HOME/code/thiscode)
  CLAUDE_DISCODE_SKIP_BUILD  1 = skip clone + npm (use existing vendor dir)
EOF
}

MODE=dry-run
case "${1:-}" in
  --dry-run)        MODE=dry-run ;;
  --apply)          MODE=apply ;;
  --recommend-only) MODE=recommend ;;
  -h|--help)        usage; exit 0 ;;
  "")               MODE=dry-run ;;
  *)                echo "unknown arg: $1" >&2; usage; exit 2 ;;
esac

note_count_check() {
  local vault="${VAULT:-${VAULT_DEFAULT}}"
  if [ -z "$vault" ] || [ ! -d "$vault" ]; then
    echo "[note_count] vault path missing or invalid: $vault" >&2
    return 0
  fi
  local n
  n=$(find "$vault" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -lt 100 ]; then
    echo "[note_count] warn — currently $n notes, 100+ recommended for vault-search MCP" >&2
    return 0
  fi
  echo "[note_count] $n notes found — OK"
  return 0
}

if [ "$MODE" = "recommend" ]; then
  note_count_check
  exit 0
fi

# preflight (note_count warn only)
note_count_check || true

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/claude_desktop_config.json"
REPO_DIR="${CLAUDE_DISCODE_HOME:-$HOME/code/thiscode}/vendor/vault-search-mcp"
SKIP_BUILD="${CLAUDE_DISCODE_SKIP_BUILD:-0}"

# Stage 1: clone or update the MCP source
if [ "$MODE" = "apply" ] && [ "$SKIP_BUILD" = "0" ]; then
  if [ ! -d "$REPO_DIR" ]; then
    echo "[stage1] cloning vault-search-mcp → $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    if ! git clone https://github.com/treylom/vault-search-mcp "$REPO_DIR" 2>/dev/null; then
      echo "[stage1] clone failed — TODO: vendor vault-search-mcp into thiscode/vendor/ first" >&2
      echo "         See: docs/SETUP.md#tier-2 for manual install" >&2
      exit 3
    fi
  else
    echo "[stage1] $REPO_DIR exists — skip clone"
  fi
  echo "[stage1] npm install + build..."
  (cd "$REPO_DIR" && npm install --silent && npm run build --silent)
fi

# Stage 2: merge into Claude config (preserve other servers)
mkdir -p "$(dirname "$CFG")"
[ -f "$CFG" ] || echo '{"mcpServers":{}}' > "$CFG"

if ! command -v jq >/dev/null 2>&1; then
  echo "[stage2] jq missing — install jq first (brew install jq / apt install jq)" >&2
  exit 4
fi

NEW_ENTRY=$(jq -n --arg cmd "node" --arg path "$REPO_DIR/dist/index.js" \
  '{ command: $cmd, args: [$path] }')

if [ "$MODE" = "dry-run" ]; then
  echo "[dry-run] would add: vault-search → $REPO_DIR/dist/index.js"
  echo "[dry-run] would modify: $CFG"
  echo "[dry-run] run with --apply to commit"
  exit 0
fi

# MODE=apply: actually write
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq --argjson entry "$NEW_ENTRY" '.mcpServers["vault-search"] = $entry' "$CFG" > "$TMP"
mv "$TMP" "$CFG"
trap - EXIT
echo "[apply] ✓ vault-search MCP registered in $CFG"
echo "[apply] restart Claude Code to load the new MCP server"
