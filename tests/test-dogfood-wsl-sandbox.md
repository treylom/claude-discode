# Dogfood Test Scenario — WSL Sandbox

> Run manually on a fresh WSL Ubuntu 20.04+ instance OR a Docker container with no Obsidian preinstalled.

## Setup

```bash
# 1. Install Claude Code
curl -fsSL https://claude.ai/install | bash

# 2. Install claude-discode plugin
cd ~ && git clone https://github.com/treylom/claude-discode-marketplace
claude marketplace add ~/claude-discode-marketplace
claude plugin install claude-discode
```

## Scenarios

### Dog-1: Obsidian absent + grep only
- Run `/claude-discode:km-bootstrap`
- Select "Obsidian + grep only" install matrix
- Run `/claude-discode:search "test"` → expect "Tier 4: 텍스트 검색 결과입니다" notice
- Run `/claude-discode:km <URL>` → expect file in `~/Inbox/` (or chosen vault_root)
- Pass criteria: no error, files written, search returns the new file

### Dog-2: Obsidian + vault-search MCP
- After Dog-1, run `/claude-discode:km-bootstrap` again
- Choose "+vault-search MCP"
- Run `/claude-discode:search "test"` → expect MCP results (no Tier 4 notice)
- Pass criteria: Tier 3 succeeds, MCP server visible in `claude --list-mcp`

### Dog-3: Full GraphRAG
- Run `/claude-discode:km-bootstrap` → "+GraphRAG server"
- Run `/claude-discode:search "test"` → expect Tier 1 JSON results
- Pass criteria: FastAPI 8400 up, score-ranked results

## Hand-off
Each scenario takes ~10 min. Record results in `~/code/claude-discode/tests/dogfood-results-<date>.md`.
