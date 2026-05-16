---
description: thiscode knowledge-manager 진입점 — variant 자동 라우팅 (lite/at/plain)
allowedTools: Read, Write, Bash, AskUserQuestion, WebFetch, Glob, Grep
---

# /thiscode:km

$ARGUMENTS

## Variant routing

1. Parse `$ARGUMENTS` for `--variant lite|at|plain` flag.
2. If absent:
   - $CLAUDE_DISCODE_HEADLESS=1 → variant = plain
   - "아카이브 정리" / "카테고리 재편" / "그래프 구축" keywords → variant = at
   - else → variant = lite (Phase 1·2 default)
3. Invoke the matching skill via `Skill` tool:
   - `knowledge-manager-lite` / `knowledge-manager-at` / `knowledge-manager-plain`
4. If skill emits "config missing" → invoke the `knowledge-manager-bootstrap` skill.

## Examples

```
/thiscode:km https://example.com/article
/thiscode:km --variant at "아카이브 정리: 020-Library/Research"
/thiscode:km --variant plain "이 텍스트 저장: ..."
```
