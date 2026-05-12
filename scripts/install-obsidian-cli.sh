#!/usr/bin/env bash
# install-obsidian-cli.sh — detect OS, install Obsidian CLI if available, skip with notice if not.
set -e

OS="$(uname -s)"
WSL=0
if [ -f /proc/version ] && grep -qi microsoft /proc/version; then WSL=1; fi

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

detect_obsidian() {
  if command -v obsidian >/dev/null 2>&1; then
    echo "obsidian: present ($(command -v obsidian))"
    return 0
  fi
  case "$OS" in
    Darwin)
      [ -d "/Applications/Obsidian.app" ] && { echo "obsidian: present (/Applications/Obsidian.app)"; return 0; }
      ;;
    Linux)
      [ "$WSL" = "1" ] && [ -f "/mnt/c/Program Files/Obsidian/Obsidian.exe" ] && \
        { echo "obsidian: present (/mnt/c/Program Files/Obsidian)"; return 0; }
      [ -x "$HOME/.local/bin/obsidian" ] && { echo "obsidian: present ($HOME/.local/bin/obsidian)"; return 0; }
      ;;
  esac
  echo "obsidian: missing — fallback to MCP/grep"
  return 1
}

install_obsidian() {
  case "$OS" in
    Darwin) brew install --cask obsidian ;;
    Linux)
      if [ "$WSL" = "1" ]; then
        echo "WSL detected — install Obsidian on Windows side: https://obsidian.md/download"
        echo "Skipping Linux install. Tier 3 (MCP) / Tier 4 (grep) will cover search."
        return 1
      fi
      if command -v apt-get >/dev/null; then
        echo "Obsidian Linux .deb: download manually from https://obsidian.md/download"
        return 1
      fi
      echo "Unknown package manager — manual install required" && return 1
      ;;
    *) echo "Unsupported OS: $OS" && return 1 ;;
  esac
}

detect_obsidian
RC=$?
if [ "$CHECK_ONLY" = "1" ]; then exit $RC; fi
if [ $RC -ne 0 ]; then
  read -r -p "Obsidian 미설치. install 시도할까요? [y/N] " ANS
  [ "${ANS:-N}" = "y" ] && install_obsidian
fi
