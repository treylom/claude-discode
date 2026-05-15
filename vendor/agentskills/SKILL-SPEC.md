# SKILL.md Standard — Vendored Spec

> **Origin:** github.com/agentskills/agentskills (primary SoT, 18.5k stars)
> **License:** Apache-2.0 (code) + CC-BY-4.0 (documentation) dual
> **Vendored at:** 2026-05-13 (latest upstream update 2026-05-13)
> **Vendored by:** thiscode v2.3
>
> 본 doc 은 SKILL.md open standard 의 핵심 spec 요약 (docs portion). full repo 는 origin 참조.
> 본 vendored 본문 = docs portion → **CC-BY-4.0 attribution 의무**: derived from github.com/agentskills/agentskills documentation.

## 1. Architectural Principles

**Agent Skill** = 본 SKILL.md standard 의 "fundamental unit of deployment: an isolated, versionable package". 본 단위 안 3 element 캡슐화:

1. **Interface Contracts** — SKILL.md file 자체 (frontmatter + content)
2. **Stateless Execution Logic** — `scripts/`
3. **Data Schemas** — explicit schema 분리

## 2. Design Philosophy

- **Separation of Concerns** — credentials hardcoded 금지, 환경 변수 / `.env` 안 injection
- **Laptop Test** — 본 skill 디렉토리 단독 추출 + 로컬 실행 가능 (host-agnostic)
- **Stateless** — execution logic 안 state 보존 zero, data schema 안 별도

## 3. Repository Structure

agentskills/agentskills (primary SoT):
- `/skills-ref` — reference skill examples
- specification documentation at `agentskills.io`
- multiple format spec: SKILL.md frontmatter + JSON schema

## 4. SKILL.md Frontmatter (표준 필드)

```yaml
---
name: <skill-slug>
description: <one-line description for activation routing>
version: <semver>
license: <SPDX ID>
allowedTools: <tool list>
---
```

본 frontmatter 가 host agent (Claude Code 등) 의 routing decision 기반.

## 5. Related Resources

- **Manning book companion** = `agentskills-io/agent-skills-in-action` (별도 repo, Apache-2.0) — 본 spec 의 도서 예제
- **Documentation site** = agentskills.io
- **Reference skills** = `/skills-ref` 폴더 안 primary repo

## 6. thiscode 와의 관계

thiscode 자체 12 skill 은 본 SKILL.md standard frontmatter 형식 따름 (name + description + allowedTools 필드). 본 standard 의 vendor 본문 = thiscode 안 skill 작성 / 검증 시 reference SoT.

본 spec 의 변경 추적 = pin version (vendored at 2026-05-13). 변경 시 manual sync (v2.4 cycle 안 평가).

---

*상세 SKILL.md frontmatter spec / 추가 필드 / reference skill 별 예제 는 origin repo 참조.*
*upstream: github.com/agentskills/agentskills*
*documentation: agentskills.io*
