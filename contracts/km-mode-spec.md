---
contract: km-mode-spec
version: 0.1.0
date: 2026-05-13
---

# KM Mode Specification

## Mode I — Ingestion

**Trigger**: URL / file path / Threads link / 카톡 export / keywords ("정리해줘", "저장해줘").
**Workflow**:
1. Extract content (Read tool / WebFetch / playwright if browser-required)
2. Classify (frontmatter generation: tags, type, source)
3. Determine vault root (env $CLAUDE_DISCODE_VAULT > config > cwd-detect > AskUserQuestion)
4. Write file (Obsidian CLI / MCP / plain Write fallback)
5. Print stored path + frontmatter summary.

**Supported variants**: lite, at, plain.

## Mode R — Reorganization

**Trigger**: "아카이브 정리" / "카테고리 재편" / 50+ files referenced.
**Workflow**:
1. List vault folder (target scope: specific folder or whole vault).
2. Progressive read + analysis.
3. Category design + DA verification (2 rounds).
4. Rule-book generation + DA verification.
5. Python batch execute (`km-tools.py mode-r`).
6. Verification + report.

**Supported variants**: at only. lite/plain SKIP with notice "Mode R requires km-at variant".

## Mode G — GraphRAG

**Trigger**: "그래프 구축" / "지식그래프" / "GraphRAG" / "프론트매터 동기화".
**Workflow**:
1. Call vault-search MCP `vault_graph({})` for current state.
2. Extract entities + relationships via batch script.
3. Update GraphRAG index (FastAPI POST /api/update or CLI `graph_build.py`).
4. Print delta summary.

**Supported variants**: lite (Tier-1 read-only), at (full build cycle), plain (skip).
