---
name: claude-discode-km-lite
description: Lite knowledge manager — Mode I (ingestion) only, single-agent, no Python state machine. Use for Phase 1·2 students or when user runs /claude-discode:km without --variant flag.
allowedTools: Read, Write, WebFetch, AskUserQuestion, Bash, Glob, Grep, mcp__vault-search__*
---

# claude-discode-km-lite

> Implements Mode I from `contracts/km-mode-spec.md` v0.1.0. Lite variant per `contracts/km-variant-matrix.md`.

## Trigger
- `/claude-discode:km <URL or file or text>` (default variant)
- User says "정리해줘" + content

## Workflow

1. Read `~/.claude-discode-config` for vault_root and current variant. If missing, escalate to `claude-discode-km-bootstrap`.
2. Detect input type:
   - URL → WebFetch
   - file path → Read
   - inline text → use directly
3. Extract title + body + meta. Generate frontmatter:
   ```yaml
   ---
   title: <extracted>
   source: <URL or file path>
   captured: <YYYY-MM-DD>
   type: atomic
   tags: <auto-suggested 1-3>
   ---
   ```
4. AskUserQuestion 1회: 저장 위치 (vault sub-folder candidates + "Other") — skip when $CLAUDE_DISCODE_HEADLESS=1.
5. Write file:
   - Obsidian present + CLI ready → `obsidian write <path>` (Tier 2-like)
   - Obsidian present + MCP ready → `mcp__obsidian__create_note`
   - Else → direct `Write` tool to plain folder
6. Print stored path + frontmatter preview + next-step ("/claude-discode:search 으로 확인").

## Out of scope
- Mode R (use km-at)
- Mode G build (use km-at)
- Mode G read-only is supported via `claude-discode-search` Tier 1
