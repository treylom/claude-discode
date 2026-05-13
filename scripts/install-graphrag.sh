#!/usr/bin/env bash
# install-graphrag.sh — set up GraphRAG FastAPI server (port 8400) for Tier 1.
# v2.1.1: v1.0.0 install logic + v2.1 preflight 통합. vault `.team-os/graphrag/` SoT
# 호출 (RRF 가중치 α=0.3 / β=0.4 / γ=0.15 / δ=0.15 자동 동등).
set -e

VAULT="${CLAUDE_DISCODE_VAULT:-$HOME/obsidian-ai-vault}"
GRAPHRAG_DIR="$VAULT/.team-os/graphrag"
ENTRY_MODULE="search_server:app"
PORT=8400

usage() {
  cat <<EOF >&2
Usage: $0 [--check | --apply | --preflight]
  --check      (default) health probe + venv/requirements report
  --apply      preflight → venv → pip install → uvicorn nohup
  --preflight  preflight only (Python / disk / port / Docker)
EOF
}

MODE=check
case "${1:-}" in
  --check)     MODE=check ;;
  --apply)     MODE=apply ;;
  --preflight) MODE=preflight ;;
  -h|--help)   usage; exit 0 ;;
  "")          MODE=check ;;
  *)           echo "unknown arg: $1" >&2; usage; exit 2 ;;
esac

preflight() {
  local fail=0
  echo "[preflight] Python 3.10+ check..."
  if ! python3 --version 2>&1 | grep -qE "3\.(1[0-9]|[2-9])"; then
    echo "  ✗ Python 3.10+ 필요" >&2; fail=1
  else
    echo "  ✓ $(python3 --version 2>&1)"
  fi
  echo "[preflight] disk 5GB+ check..."
  # POSIX df -k (1KB blocks) for cross-platform (macOS BSD / Linux GNU)
  local free_kb free_gb
  free_kb=$(df -k "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')
  free_gb=$(( ${free_kb:-0} / 1024 / 1024 ))
  if [ "$free_gb" -lt 5 ]; then
    echo "  ✗ disk 5GB+ 필요 (현재 ${free_gb}GB)" >&2; fail=1
  else
    echo "  ✓ ${free_gb}GB free"
  fi
  echo "[preflight] port $PORT check..."
  if nc -z localhost "$PORT" 2>/dev/null; then
    echo "  ⚠ port $PORT in use (may be existing GraphRAG — apply will skip start)" >&2
  else
    echo "  ✓ port $PORT free"
  fi
  echo "[preflight] Docker check (warn only)..."
  if ! command -v docker >/dev/null 2>&1; then
    echo "  ⚠ Docker not found (optional)" >&2
  else
    echo "  ✓ docker OK"
  fi
  return $fail
}

if [ "$MODE" = "preflight" ]; then
  preflight
  exit $?
fi

if [ "$MODE" = "check" ]; then
  echo "python3: $(command -v python3 2>/dev/null || echo MISSING)"
  echo "vault: $VAULT $([ -d "$VAULT" ] && echo present || echo missing)"
  echo "graphrag dir: $GRAPHRAG_DIR $([ -d "$GRAPHRAG_DIR" ] && echo present || echo missing)"
  echo "venv: $GRAPHRAG_DIR/.venv $([ -d "$GRAPHRAG_DIR/.venv" ] && echo present || echo missing)"
  echo "requirements: $GRAPHRAG_DIR/scripts/requirements.txt $([ -f "$GRAPHRAG_DIR/scripts/requirements.txt" ] && echo present || echo missing)"
  if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
    echo "GraphRAG server: running on port $PORT"
  else
    echo "GraphRAG server: not running (Tier 1 will fall through)"
  fi
  exit 0
fi

# MODE=apply
if ! command -v python3 >/dev/null; then
  echo "python3 missing — install python3 first" >&2
  exit 4
fi

preflight || { echo "[apply] preflight FAILED — fix issues above" >&2; exit 1; }

if [ ! -d "$GRAPHRAG_DIR" ]; then
  echo "GraphRAG SoT missing at $GRAPHRAG_DIR" >&2
  echo "  Expected: vault '.team-os/graphrag/' (set CLAUDE_DISCODE_VAULT to your vault root)" >&2
  echo "  See: docs/SETUP.md#tier-1 for manual setup" >&2
  exit 5
fi

if [ ! -f "$GRAPHRAG_DIR/scripts/requirements.txt" ]; then
  echo "requirements.txt missing at $GRAPHRAG_DIR/scripts/" >&2
  exit 5
fi

cd "$GRAPHRAG_DIR"
[ -d .venv ] || { echo "[apply] creating venv..."; python3 -m venv .venv; }
echo "[apply] pip install requirements (quiet)..."
.venv/bin/pip install --quiet --upgrade pip
.venv/bin/pip install --quiet -r scripts/requirements.txt

if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
  echo "[apply] GraphRAG server already running on port $PORT — skip start"
  exit 0
fi

echo "[apply] starting GraphRAG server (uvicorn, background)..."
nohup .venv/bin/python -m uvicorn --app-dir scripts "$ENTRY_MODULE" \
  --host 127.0.0.1 --port "$PORT" >graphrag.log 2>&1 &
PID=$!
echo "[apply] pid=$PID — waiting for health (10s)..."

for _ in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
    echo "[apply] ✓ GraphRAG server running on port $PORT (pid=$PID)"
    exit 0
  fi
done

echo "[apply] ⚠ server not responding after 10s — check $GRAPHRAG_DIR/graphrag.log" >&2
echo "[apply] last 5 lines of graphrag.log:" >&2
tail -5 "$GRAPHRAG_DIR/graphrag.log" 2>/dev/null >&2 || true
exit 6
