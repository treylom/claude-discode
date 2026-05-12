---
name: claude-discode-km-bootstrap
description: One-shot environment installer for the 4-Tier search stack — installs Obsidian CLI (optional), vault-search MCP, GraphRAG server (optional), and records vault_root. Use on first run or when user reports "search Tier X 실패".
allowedTools: Bash, AskUserQuestion, Write, Read
---

# claude-discode-km-bootstrap

## Trigger
- Slash: `/claude-discode:km-bootstrap`
- Failure escalation from `claude-discode-search` when all 4 Tiers fail

## Workflow

1. Detect environment: OS (uname -s), WSL (/proc/version), shell, claude version.
2. Detect existing assets:
   - Obsidian (`scripts/install-obsidian-cli.sh --check`)
   - vault-search MCP (`scripts/install-vault-search.sh --dry-run`)
   - GraphRAG server (`scripts/install-graphrag.sh --check`)
3. Detect vault_root candidates (cwd / $CLAUDE_DISCODE_VAULT env / `~/.claude-discode-config` / `~/obsidian-ai-vault` / `~/Documents/Obsidian`).
4. AskUserQuestion 1회: vault_root 확정 (multiple choice from candidates + Other).
5. Write `~/.claude-discode-config` with selected vault_root.
6. AskUserQuestion 1회: install matrix (Obsidian only / +vault-search MCP / +GraphRAG (full)).
7. Run corresponding `install-*.sh --apply` scripts in order.
8. Verify by calling `claude-discode-search` with sample query.
9. Print install summary + next-step suggestions.

## Config file format

`~/.claude-discode-config`:
```yaml
vault_root: /Users/tofu_mac/obsidian-ai-vault
search:
  tiers:
    - graphrag
    - obsidian
    - mcp
    - grep
  graphrag_endpoint: http://127.0.0.1:8400
km:
  variant: lite   # default Phase 1·2
  mode_r: false   # at variant only
```

See `references/setup-wizard.md` for exact AskUserQuestion prompts.
