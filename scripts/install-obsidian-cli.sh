#!/usr/bin/env bash
# install-obsidian-cli.sh — detect OS, install Obsidian CLI if available, skip with notice if not.
set -e

OS="$(uname -s)"
WSL=0
if [ -f /proc/version ] && grep -qi microsoft /proc/version; then WSL=1; fi

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# v2.0.2 — CLI 자체 detect 우선 (codex review: 앱 detect 만으로 부족)
# 공식 Obsidian CLI: obsidian-cli (Mac homebrew symlink) / obsidian (Linux PATH)
# Yakitrak/notesmd-cli: 별도 binary 이름
detect_obsidian_cli() {
  if command -v obsidian-cli >/dev/null 2>&1; then
    echo "obsidian-cli: present ($(command -v obsidian-cli))"
    return 0
  fi
  if command -v obsidian >/dev/null 2>&1; then
    echo "obsidian (CLI): present ($(command -v obsidian))"
    return 0
  fi
  if command -v notesmd-cli >/dev/null 2>&1; then
    echo "notesmd-cli (Yakitrak): present ($(command -v notesmd-cli))"
    return 0
  fi
  echo "Obsidian CLI: missing — 공식 binary (obsidian-cli/obsidian) 또는 Yakitrak notesmd-cli 중 하나 install 필요"
  return 1
}

detect_obsidian() {
  case "$OS" in
    Darwin)
      [ -d "/Applications/Obsidian.app" ] && { echo "obsidian app: present (/Applications/Obsidian.app)"; return 0; }
      ;;
    Linux)
      [ "$WSL" = "1" ] && [ -f "/mnt/c/Program Files/Obsidian/Obsidian.exe" ] && \
        { echo "obsidian app: present (/mnt/c/Program Files/Obsidian)"; return 0; }
      [ -x "$HOME/.local/bin/obsidian" ] && { echo "obsidian app: present ($HOME/.local/bin/obsidian)"; return 0; }
      ;;
  esac
  echo "obsidian app: missing — fallback to MCP/grep"
  return 1
}

install_obsidian() {
  case "$OS" in
    Darwin) brew install --cask obsidian ;;
    Linux)
      if [ "$WSL" = "1" ]; then
        echo "WSL detected — install Obsidian on Windows side: https://obsidian.md/download"
        echo "Skipping Linux install. Tier 2 (MCP) / Tier 4 (grep) will cover search."
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

# v2.0.2 — CLI detect 우선 + app fallback
detect_obsidian_cli
CLI_RC=$?
detect_obsidian
APP_RC=$?
# CLI 있거나 앱 있으면 OK
[ $CLI_RC -eq 0 ] || [ $APP_RC -eq 0 ]
RC=$?
if [ "$CHECK_ONLY" = "1" ]; then exit $RC; fi
if [ $RC -ne 0 ]; then
  read -r -p "Obsidian CLI/앱 미설치. install 시도할까요? [y/N] " ANS
  [ "${ANS:-N}" = "y" ] && install_obsidian
fi
