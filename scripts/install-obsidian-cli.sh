#!/usr/bin/env bash
set -e

OS=$(uname -s)
WSL=0
[ -f /proc/version ] && grep -qi microsoft /proc/version && WSL=1

CHECK_ONLY=0
JSON_OUT=0

for arg in "$@"; do
  [ "$arg" = "--check" ] && CHECK_ONLY=1
  [ "$arg" = "--json" ] && JSON_OUT=1
done

if [ "$JSON_OUT" = "1" ] && [ "$CHECK_ONLY" = "1" ]; then
  local_cli=""
  for c in obsidian-cli obsidian notesmd-cli; do
    if command -v "$c" >/dev/null 2>&1; then
      local_cli="$(command -v "$c")"
      break
    fi
  done

  local_app=""
  case "$OS" in
    Darwin) 
      [ -d "/Applications/Obsidian.app" ] && local_app="/Applications/Obsidian.app"
      ;;
    Linux)
      if [ "$WSL" = "1" ] && [ -f "/mnt/c/Program Files/Obsidian/Obsidian.exe" ]; then
        local_app="/mnt/c/Program Files/Obsidian"
      fi
      [ -x "$HOME/.local/bin/obsidian" ] && local_app="$HOME/.local/bin/obsidian"
      ;;
  esac

  jq -n \
    --arg cli "$local_cli" \
    --arg app "$local_app" \
    --arg os "$OS" \
    '{ obsidian_cli: $cli, obsidian_app: $app, os: $os }'
  exit 0
fi
