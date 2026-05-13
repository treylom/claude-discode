#!/usr/bin/env bash
# claude-discode init — env detect + Phase 추천 + y/n wizard
set -e

DETECT_ONLY=0
JSON_OUT=0
NON_INTERACTIVE=0
AUTO_PHASES="${CLAUDE_DISCODE_INIT_AUTO:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --detect-only) DETECT_ONLY=1; shift;;
    --json) JSON_OUT=1; shift;;
    --non-interactive) NON_INTERACTIVE=1; shift;;
    *) shift;;
  esac
done

detect_env() {
  local os vault_path note_count
  case "$(uname -s)" in
    Darwin) os="darwin";;
    Linux)
      if [ -f /proc/version ] && grep -qi microsoft /proc/version; then os="wsl"; else os="linux"; fi
      ;;
    *) os="unknown";;
  esac

  # vault autodiscover
  vault_path="${CLAUDE_DISCODE_VAULT:-}"
  if [ -z "$vault_path" ]; then
    for candidate in "$HOME/Documents/Obsidian" "$HOME/Documents/Second_Brain" "$HOME/obsidian-ai-vault"; do
      [ -d "$candidate" ] && vault_path="$candidate" && break
    done
  fi
  vault_path="${vault_path:-}"
  if [ -n "$vault_path" ] && [ -d "$vault_path" ]; then
    note_count=$(find "$vault_path" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  else
    note_count=0
  fi

  # tools
  local obs_cli py docker rg
  obs_cli=$(command -v obsidian-cli 2>/dev/null || command -v obsidian 2>/dev/null || command -v notesmd-cli 2>/dev/null || echo "")
  py=$(command -v python3 2>/dev/null || echo "")
  if [ -n "$py" ]; then
    py_version=$("$py" --version 2>&1 | awk '{print $2}')
  else
    py_version=""
  fi
  docker=$(command -v docker 2>/dev/null || echo "")
  rg=$(command -v rg 2>/dev/null || echo "")

  # resources
  local ram_gb disk_free_gb
  if [ "$os" = "darwin" ]; then
    ram_gb=$(($(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024))
  else
    ram_gb=$(free -g 2>/dev/null | awk '/^Mem:/{print $2}' || echo 0)
  fi
  disk_free_gb=$(df -BG "$HOME" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G' || echo 0)

  jq -n \
    --arg os "$os" \
    --arg vault_path "$vault_path" \
    --argjson note_count "${note_count:-0}" \
    --arg obs_cli "$obs_cli" \
    --arg py "$py" \
    --arg py_version "$py_version" \
    --arg docker "$docker" \
    --arg rg "$rg" \
    --argjson ram_gb "${ram_gb:-0}" \
    --argjson disk_free_gb "${disk_free_gb:-0}" \
    '{
      os: $os,
      vault: { path: $vault_path, note_count: $note_count },
      tools: {
        obsidian_cli: $obs_cli,
        python: $py,
        python_version: $py_version,
        docker: $docker,
        ripgrep: $rg
      },
      resources: { ram_gb: $ram_gb, disk_free_gb: $disk_free_gb }
    }'
}

if [ "$DETECT_ONLY" = "1" ]; then
  detect_env
  exit 0
fi

echo "claude-discode init — Phase recommend + wizard (Task 2~3 에서 구현)"
detect_env
