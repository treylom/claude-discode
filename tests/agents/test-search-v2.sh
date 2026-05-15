#!/usr/bin/env bash
set -e
F=/Users/tofu_mac/code/thiscode/.agents/thiscode-search.yaml
grep -q "Tier 2 vault-search MCP" "$F" || { echo "FAIL: search description Tier 2 = MCP"; exit 1; }
grep -q "Tier 3 Obsidian CLI" "$F" || { echo "FAIL: search description Tier 3 = CLI"; exit 1; }
echo "PASS search v2"
