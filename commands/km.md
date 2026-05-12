---
description: claude-discode knowledge-manager 진입점 — variant 자동 라우팅 (lite/at/plain)
allowedTools: Read, Write, Bash, AskUserQuestion, WebFetch, Glob, Grep
---

# /claude-discode:km

$ARGUMENTS

## Variant routing

1. Parse `$ARGUMENTS` for `--variant lite|at|plain` flag.
2. If absent:
   - $CLAUDE_DISCODE_HEADLESS=1 → variant = plain
   - "아카이브 정리" / "카테고리 재편" / "그래프 구축" keywords → variant = at
   - else → variant = lite (Phase 1·2 default)
3. Invoke the matching skill via `Skill` tool:
   - `claude-discode-km-lite` / `claude-discode-km-at` / `claude-discode-km-plain`
4. If skill emits "config missing" → invoke `claude-discode-km-bootstrap`.

## Examples

```
/claude-discode:km https://example.com/article
/claude-discode:km --variant at "아카이브 정리: 020-Library/Research"
/claude-discode:km --variant plain "이 텍스트 저장: ..."
```
