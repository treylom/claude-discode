#!/usr/bin/env bash
# Test: km-version.sh detects drift when contract versions differ.
set -e

TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/plugin/contracts" "$TMPDIR/vault/.claude/reference/contracts"

# Same version both sides
echo "version: 0.1.0" > "$TMPDIR/plugin/contracts/search-fallback-4tier.md"
echo "version: 0.1.0" > "$TMPDIR/vault/.claude/reference/contracts/search-fallback-4tier.md"

OUTPUT=$(CLAUDE_DISCODE_HOME="$TMPDIR/plugin" CLAUDE_DISCODE_VAULT="$TMPDIR/vault" \
  bash "$HOME/code/claude-discode/scripts/km-version.sh" 2>&1)
echo "$OUTPUT" | grep -q "ok: 0.1.0 == 0.1.0" || { echo "FAIL: same version check"; exit 1; }

# Drift case
echo "version: 0.2.0" > "$TMPDIR/vault/.claude/reference/contracts/search-fallback-4tier.md"
OUTPUT=$(CLAUDE_DISCODE_HOME="$TMPDIR/plugin" CLAUDE_DISCODE_VAULT="$TMPDIR/vault" \
  bash "$HOME/code/claude-discode/scripts/km-version.sh" 2>&1 || true)
echo "$OUTPUT" | grep -q "WARNING: drift" || { echo "FAIL: drift detection"; exit 1; }

echo "PASS"
rm -rf "$TMPDIR"
