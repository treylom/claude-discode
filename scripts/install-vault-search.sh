#!/usr/bin/env bash
set -e

note_count_check() {
  local vault="${VAULT:-${1:-}}"
  if [ -z "$vault" ] || [ ! -d "$vault" ]; then
    echo "[note_count] vault path missing" >&2
    return 0
  fi
  local n=$(find "$vault" -name "*.md" 2>/dev/null | wc -l)
  if [ "${n:-0}" -lt 100 ]; then
    echo "[note_count] warn — currently $n notes, recommend 100+" >&2
    return 0
  fi
  echo "[note_count] $n notes found OK"
  return 0
}

for arg in "$@"; do
  case "$arg" in
    --recommend-only)
      note_count_check
      exit 0
      ;;
  esac
done

note_count_check
