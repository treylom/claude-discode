#!/usr/bin/env bash
# Test: km-lite saves URL content as markdown when Obsidian is absent.
set -e
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/vault"

INPUT_CONTENT="# Sample Article\n\nThis is the article body about MCP."

CLAUDE_DISCODE_VAULT="$TMPDIR/vault" \
  CLAUDE_DISCODE_NO_OBSIDIAN=1 \
  bash "$HOME/code/claude-discode/skills/claude-discode-km-lite/references/extract-and-classify.md.sh" \
    --content "$INPUT_CONTENT" --source-url "https://example.com/x" --title "Sample"

NEW=$(find "$TMPDIR/vault" -name '*.md' 2>/dev/null | head -1)
[ -n "$NEW" ] || { echo "FAIL: no file written"; exit 1; }
grep -q "Sample Article" "$NEW" || { echo "FAIL: content missing"; cat "$NEW"; exit 1; }
grep -q "^source:" "$NEW" || { echo "FAIL: frontmatter source missing"; cat "$NEW"; exit 1; }

echo "PASS"
rm -rf "$TMPDIR"
