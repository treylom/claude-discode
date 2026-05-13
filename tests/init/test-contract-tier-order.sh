#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/contracts/search-fallback-4tier.md"

# v2.0 순서 (GraphRAG → MCP → CLI → ripgrep) 명시
grep -E "Tier 2.*vault-search MCP|vault-search MCP.*Tier 2" "$F" >/dev/null || { echo "FAIL: Tier 2 = MCP 누락"; exit 1; }
grep -E "Tier 3.*Obsidian CLI|Tier 3.*obsidian-cli|Obsidian CLI.*Tier 3" "$F" >/dev/null || { echo "FAIL: Tier 3 = CLI 누락"; exit 1; }

# v1.0 잔재 (Tier 2 obsidian-cli / Tier 3 MCP) 없어야
! grep -E "Tier 2.*obsidian-cli|Tier 2.*Obsidian CLI" "$F" >/dev/null || { echo "FAIL: v1.0 잔재 Tier 2 = CLI"; exit 1; }
! grep -E "Tier 3.*vault-search MCP|Tier 3.*MCP \(embedding\)" "$F" >/dev/null || { echo "FAIL: v1.0 잔재 Tier 3 = MCP"; exit 1; }

echo "PASS contract tier order v2.0"
