---
name: claude-discode-search
description: 4-Tier vault search (GraphRAG → Obsidian CLI → vault-search MCP → ripgrep) per contracts/search-fallback-4tier.md. Use when student invokes /claude-discode:search or any vault question.
allowedTools: Bash, Read, Glob, Grep, mcp__vault-search__*
---

# claude-discode-search

> Implements `contracts/search-fallback-4tier.md` v0.1.0.

## Trigger
- Slash: `/claude-discode:search <query>` (`--quick` / `--deep` / `--no-moc` flags)
- Programmatic call from `claude-discode-km-*` skills

## Workflow

1. Parse `$ARGUMENTS` for flags + extract `query`.
2. Determine `vault_root` (env $CLAUDE_DISCODE_VAULT > config > cwd-detect).
3. Try Tier 1 — GraphRAG FastAPI (3s timeout). If success, format results + MOC priority.
4. Else Tier 2 — Obsidian CLI. If success, format results.
5. Else Tier 3 — vault-search MCP. If success, format results.
6. Else Tier 4 — ripgrep. Output MUST include "Tier 4: 텍스트 검색 결과입니다" notice.
7. Apply MOC priority routing across all Tiers.
8. Print results.

## Output format

```
**답변:** [QUICK: 3-5줄 / DEEP: 분석]
📌 상위 MOC (N) — Phase 0.5 재정렬
1. **[[MOC 제목]]** — [한 줄] (`경로`)
📄 원자 노트 (N)
1. **[제목]** — [한 줄] (`경로`)

[Tier 4: 텍스트 검색 결과입니다]   ← Tier 4 일 때만
```

See `references/tier-implementations.md` for each Tier's exact call signature.
