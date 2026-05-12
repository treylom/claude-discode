#!/usr/bin/env bash
# T4 — vault regression: existing /knowledge-manager + /search still work after mirror align.
set -e

VAULT=/Users/tofu_mac/obsidian-ai-vault

# T4.1 — /knowledge-manager.md still references 7-Layer + Mode I/R/G
grep -qE "7-Layer|Mode I|Mode R|Mode G" "$VAULT/.claude/commands/knowledge-manager.md" || \
  { echo "FAIL T4.1: 7-Layer / Mode markers missing"; exit 1; }

# T4.2 — /search.md Tier 1 references GraphRAG FastAPI 8400
grep -qE "8400|GraphRAG" "$VAULT/.claude/commands/search.md" || \
  { echo "FAIL T4.2: Tier 1 GraphRAG ref missing"; exit 1; }

# T4.3 — Contract banner added (mirror align indicator)
grep -qE "Contract|contracts/" "$VAULT/.claude/commands/search.md" || \
  { echo "FAIL T4.3: contract banner missing in search.md"; exit 1; }

grep -qE "Contracts|contracts/" "$VAULT/.claude/commands/knowledge-manager.md" || \
  { echo "FAIL T4.3b: contract banner missing in knowledge-manager.md"; exit 1; }

# T4.4 — Karpathy Pipeline reference still in km
grep -qE "Karpathy Pipeline|km-karpathy-pipeline" "$VAULT/.claude/commands/knowledge-manager.md" || \
  { echo "FAIL T4.4: Karpathy Pipeline ref missing"; exit 1; }

echo "PASS"
