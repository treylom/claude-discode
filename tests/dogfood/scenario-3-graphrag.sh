#!/usr/bin/env bash
# Dog-3: GraphRAG check (server probably down in sandbox — script must exit ≤4).
set -e

ROOT="${CLAUDE_DISCODE_HOME:-/claude-discode}"

echo "[Dog-3] install-graphrag.sh --check (server expected down)"
set +e
bash "$ROOT/scripts/install-graphrag.sh" --check
RC=$?
set -e
[ "$RC" -le 4 ] || { echo "FAIL Dog-3: rc=$RC"; exit 1; }

echo "PASS Dog-3"
