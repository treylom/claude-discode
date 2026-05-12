#!/usr/bin/env bash
# Test: when only ripgrep is available, claude-discode-search produces Tier 4 results with notice.
set -e
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/vault"
cat > "$TMPDIR/vault/note1.md" <<'MD'
---
type: atomic
---
# MCP 정의
MCP는 Model Context Protocol 의 약자다.
MD

DISP="$HOME/code/claude-discode/skills/claude-discode-search/references/tier-implementations.md.sh"

CLAUDE_DISCODE_VAULT="$TMPDIR/vault" \
  CLAUDE_DISCODE_FORCE_TIER=4 \
  bash "$DISP" "MCP" \
  > "$TMPDIR/out.txt" 2>&1 || true

grep -q "note1.md" "$TMPDIR/out.txt" || { echo "FAIL: result missing"; cat "$TMPDIR/out.txt"; exit 1; }
grep -q "Tier 4: 텍스트 검색 결과입니다" "$TMPDIR/out.txt" || { echo "FAIL: notice missing"; cat "$TMPDIR/out.txt"; exit 1; }

echo "PASS"
rm -rf "$TMPDIR"
