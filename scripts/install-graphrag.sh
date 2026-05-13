#!/usr/bin/env bash
set -e

preflight() {
  local fail=0
  echo "[preflight] Python 3.10+ check..."
  if ! python3 --version 2>&1 | grep -qE "3\.(1[0-9]|[2-9])"; then
    echo "  ✗ Python 3.10+ 필요" >&2; fail=1
  else
    echo "  ✓ $(python3 --version 2>&1)"
  fi
  echo "[preflight] disk 5GB+ check..."
  local free_gb=$(df -BG "$HOME" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
  if [ "${free_gb:-0}" -lt 5 ]; then
    echo "  ✗ disk 5GB+ 필요" >&2; fail=1
  else
    echo "  ✓ ${free_gb}GB free"
  fi
  echo "[preflight] port 8400 check..."
  if nc -z localhost 8400 2>/dev/null; then
    echo "  ✗ port 8400 in use" >&2; fail=1
  else
    echo "  ✓ port 8400 free"
  fi
  echo "[preflight] Docker check (warn only)..."
  if ! command -v docker >/dev/null 2>&1; then
    echo "  ⚠ Docker not found" >&2
  else
    echo "  ✓ docker OK"
  fi
  return $fail
}

PREFLIGHT_ONLY=0
for arg in "$@"; do
  [ "$arg" = "--preflight" ] && PREFLIGHT_ONLY=1
done

if [ "$PREFLIGHT_ONLY" = "1" ]; then
  preflight
  exit $?
fi

preflight || { echo "preflight FAILED" >&2; exit 1; }
