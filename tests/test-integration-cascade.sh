#!/usr/bin/env bash
# Integration test: 4-Tier cascade behavior end-to-end.
set -e
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/vault"
cat > "$TMPDIR/vault/n.md" <<'MD'
---
type: atomic
---
# Test
MCP details here.
MD

DISP="$HOME/code/claude-discode/skills/claude-discode-search/references/tier-implementations.md.sh"

# T2.1 — cascade must produce a non-empty response (Tier 1 if GraphRAG server is up, else Tier 4)
CLAUDE_DISCODE_VAULT="$TMPDIR/vault" bash "$DISP" "MCP" > "$TMPDIR/out.txt" 2>&1 || true
[ -s "$TMPDIR/out.txt" ] || { echo "FAIL T2.1: empty cascade response"; exit 1; }

# T2.2 — Force Tier 4 explicitly
CLAUDE_DISCODE_VAULT="$TMPDIR/vault" CLAUDE_DISCODE_FORCE_TIER=4 bash "$DISP" "MCP" > "$TMPDIR/out2.txt"
grep -q "Tier 4: 텍스트 검색 결과입니다" "$TMPDIR/out2.txt" || { echo "FAIL T2.2"; cat "$TMPDIR/out2.txt"; exit 1; }

echo "PASS"
rm -rf "$TMPDIR"
