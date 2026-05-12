#!/usr/bin/env bash
# install-graphrag.sh — set up GraphRAG FastAPI server (port 8400) for Tier 1.
set -e

CHECK=0; APPLY=0
case "${1:-}" in
  --check) CHECK=1 ;;
  --apply) APPLY=1 ;;
  *) CHECK=1 ;;
esac

VAULT="${CLAUDE_DISCODE_VAULT:-$HOME/obsidian-ai-vault}"
GRAPHRAG_DIR="$VAULT/.team-os/graphrag"

echo "python3: $(command -v python3 2>/dev/null || echo MISSING)"
echo "venv: $GRAPHRAG_DIR/.venv $([ -d "$GRAPHRAG_DIR/.venv" ] && echo present || echo missing)"
echo "requirements: $GRAPHRAG_DIR/requirements.txt $([ -f "$GRAPHRAG_DIR/requirements.txt" ] && echo present || echo missing)"

if ! command -v python3 >/dev/null; then
  echo "python3 missing — install python3 first" >&2
  exit 4
fi

if [ "$CHECK" = "1" ]; then
  if curl -s --connect-timeout 1 http://127.0.0.1:8400/health 2>/dev/null | grep -q ok; then
    echo "GraphRAG server: running on port 8400"
  else
    echo "GraphRAG server: not running (Tier 1 will fall through)"
  fi
  exit 0
fi

# APPLY path
if [ ! -d "$GRAPHRAG_DIR" ]; then
  echo "GraphRAG repo missing at $GRAPHRAG_DIR" >&2
  echo "  See: ~/code/claude-discode/docs/06-graphrag-setup.md for manual setup" >&2
  exit 5
fi

cd "$GRAPHRAG_DIR"
[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install --quiet -r requirements.txt
echo "Starting GraphRAG server (background)..."
nohup .venv/bin/python scripts/serve.py >graphrag.log 2>&1 &
sleep 2
curl -s --connect-timeout 3 http://127.0.0.1:8400/health
