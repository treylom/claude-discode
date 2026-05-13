---
name: claude-discode-km-at
description: Agent Teams knowledge manager — supports Mode R (reorganization) + Mode G full build, with Category Lead + RALPH workers + DA verifier. Requires km-tools.py + jq + Agent Teams environment. Use when user runs /claude-discode:km --variant at or requests "아카이브 정리" / "GraphRAG build".
allowedTools: Read, Write, Bash, Glob, Grep, AskUserQuestion, mcp__vault-search__*
---

# claude-discode-km-at

> Implements Mode I + R + G full from `contracts/km-mode-spec.md`. At variant per `contracts/km-variant-matrix.md`.

## Mode R Preflight (read-only, Phase 5)

claude-discode init wizard 가 vault 2000+ 노트 detect 시 자동 호출. 진단만, 어떤 이동/rename 도 안 함:

1. **broken_wikilinks** — vault 전체 scan, `[[link]]` 의 target 부재 시 list
2. **folder_entropy** — 폴더당 노트 분포 + 진입 marker (어떤 폴더가 과밀, 어떤 게 비어있나)
3. **orphan_notes** — 다른 노트에서 link 안 된 고립 노트

결과: `meetings/{date}-km-at-preflight-report.md` (dry-run report). 사용자 검토 후 명시 동의 시 Mode R apply 진입 (dry_run_required: true).

자세: references/mode-r-preflight.md

## Prereq check

Before any workflow:
1. `command -v jq` exists.
2. `python3 -c 'import sys; sys.exit(0)'` works.
3. Optional: `~/code/claude-discode/vendor/km-tools/km-tools.py` exists (vendored from agent-office/km-tools).
4. tmux session available (Agent Teams routing).

If any check fails → output "km-at prereq missing — falling back to km-lite for Mode I, abort for Mode R/G".

## Mode dispatch

| User intent | Mode |
|---|---|
| URL / file / "정리해줘" | I (same as km-lite but with optional Agent Teams parallel extraction) |
| "아카이브 정리", "카테고리 재편" | R (see references/mode-r-workflow.md) |
| "그래프 구축", "GraphRAG build" | G (call `install-graphrag.sh --apply` + scripts/build_index.py) |

## Agent Teams pattern

For Mode R/G, dispatch via the `superpowers:dispatching-parallel-agents` skill:
- **Category Lead** (Opus): designs the new taxonomy
- **RALPH workers** (Sonnet ×N, parallel): re-tags batches of notes
- **DA verifier** (Codex / Opus): adversarial check before commit

See `references/mode-r-workflow.md` for the exact 5-phase R0→R5 cycle.
