---
description: claude-discode vault 통합 검색 — 4-Tier (GraphRAG → Obsidian → MCP → grep)
allowedTools: Bash, Read, Glob, Grep, mcp__vault-search__*
---

# /claude-discode:search

$ARGUMENTS

Invokes the `claude-discode-search` skill which runs Tier 1→4 per `contracts/search-fallback-4tier.md`.

## Flags
- `--quick` / `-q` → 3-5줄 즉답
- `--deep` / `-d` → 상세 분석
- `--no-moc` → MOC 우선 라우팅 제외

## Examples

```
/claude-discode:search MCP란?
/claude-discode:search --deep "GraphRAG vs Obsidian search 차이"
/claude-discode:search --no-moc "specific note title"
```
