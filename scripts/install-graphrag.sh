#!/usr/bin/env bash
# install-graphrag.sh — claude-discode v2.3
# GraphRAG FastAPI server (port 8400) — Tier 1 search 백엔드
# v2.3: v2.1.1 backbone + vault SoT 의존 → claude-discode vendor/graphrag/ 의존 정정
#       venv 위치 = ~/.cache/claude-discode/graphrag/venv (writable home cache)
# 출처: claude-discode/vendor/graphrag/ ← obsidian-ai-vault `.team-os/graphrag/` vendor 박제
# RRF 가중치: α=0.3 (Dense) / β=0.4 (Sparse) / γ=0.15 (Decomposed) / δ=0.15 (Entity)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DISCODE_HOME="${CLAUDE_DISCODE_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"
GRAPHRAG_VENDOR="$CLAUDE_DISCODE_HOME/vendor/graphrag"
GRAPHRAG_VENV="${HOME}/.cache/claude-discode/graphrag/venv"
GRAPHRAG_RUN="${HOME}/.cache/claude-discode/graphrag/run"
ENTRY_MODULE="search_server:app"
PORT=8400

usage() {
  cat <<EOF >&2
Usage: $0 [--check | --apply | --preflight]
  --check      (default) health probe + venv/requirements report
  --apply      preflight → venv → pip install → uvicorn nohup
  --preflight  preflight only (Python / disk / port / vendor SoT)
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
  echo "[preflight] vendor SoT check..."
  if [ ! -d "$GRAPHRAG_VENDOR/scripts" ]; then
    echo "  ✗ vendor/graphrag/scripts/ missing at $GRAPHRAG_VENDOR" >&2; fail=1
  else
    local n
    n=$(find "$GRAPHRAG_VENDOR/scripts" -maxdepth 1 -name "*.py" 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ vendor SoT present ($n Python files)"
  fi
  return $fail
}

if [ "$MODE" = "preflight" ]; then
  preflight
  exit $?
fi

if [ "$MODE" = "check" ]; then
  echo "python3: $(command -v python3 2>/dev/null || echo MISSING)"
  echo "vendor SoT: $GRAPHRAG_VENDOR/scripts $([ -d "$GRAPHRAG_VENDOR/scripts" ] && echo present || echo missing)"
  echo "venv: $GRAPHRAG_VENV $([ -d "$GRAPHRAG_VENV" ] && echo present || echo missing)"
  echo "requirements: $GRAPHRAG_VENDOR/scripts/requirements.txt $([ -f "$GRAPHRAG_VENDOR/scripts/requirements.txt" ] && echo present || echo missing)"
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

if [ ! -d "$GRAPHRAG_VENDOR/scripts" ]; then
  echo "vendor/graphrag/scripts/ missing — claude-discode repo corrupted?" >&2
  echo "  Expected: $GRAPHRAG_VENDOR/scripts/ (vendored from vault SoT)" >&2
  exit 5
fi

mkdir -p "$GRAPHRAG_RUN"
[ -d "$GRAPHRAG_VENV" ] || { echo "[apply] creating venv at $GRAPHRAG_VENV..."; python3 -m venv "$GRAPHRAG_VENV"; }
echo "[apply] pip install requirements (quiet)..."
"$GRAPHRAG_VENV/bin/pip" install --quiet --upgrade pip
"$GRAPHRAG_VENV/bin/pip" install --quiet -r "$GRAPHRAG_VENDOR/scripts/requirements.txt"

if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
  echo "[apply] GraphRAG server already running on port $PORT — skip start"
  exit 0
fi

echo "[apply] starting GraphRAG server (uvicorn, background)..."
nohup "$GRAPHRAG_VENV/bin/python" -m uvicorn --app-dir "$GRAPHRAG_VENDOR/scripts" "$ENTRY_MODULE" \
  --host 127.0.0.1 --port "$PORT" >"$GRAPHRAG_RUN/graphrag.log" 2>&1 &
PID=$!
echo "[apply] pid=$PID — waiting for health (10s)..."

for _ in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
    echo "[apply] ✓ GraphRAG server running on port $PORT (pid=$PID)"
    exit 0
  fi
done

echo "[apply] ⚠ server not responding after 10s — check $GRAPHRAG_RUN/graphrag.log" >&2
echo "[apply] last 5 lines of graphrag.log:" >&2
tail -5 "$GRAPHRAG_RUN/graphrag.log" 2>/dev/null >&2 || true
exit 6
