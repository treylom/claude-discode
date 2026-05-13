# SKILL.md Standard — Vendored Spec

> **Origin:** github.com/agentskills-io/agent-skills-in-action
> **License:** Apache 2.0 (see `LICENSE`)
> **Vendored at:** 2026-05-13 (Manning book companion, last upstream update 2026-04-22)
> **Vendored by:** claude-discode v2.3
>
> 본 doc 은 SKILL.md open standard 의 핵심 spec 요약. full repo 는 origin 참조.

## 1. Architectural Principles

**Agent Skill** = 본 SKILL.md standard 의 "fundamental unit of deployment: an isolated, versionable package". 본 단위 안 3 element 캡슐화:

1. **Interface Contracts** — SKILL.md file 자체
2. **Stateless Execution Logic** — `scripts/`
3. **Data Schemas** — explicit schema 분리

## 2. Design Philosophy

- **Separation of Concerns** — credentials hardcoded 금지, 환경 변수 / `.env` 안 injection
- **Laptop Test** — 본 skill 디렉토리 단독 추출 + 로컬 실행 가능 (host-agnostic)
- **Stateless** — execution logic 안 state 보존 zero, data schema 안 별도

## 3. Practical Implementation

- Installation: `npx skills add agentskills-io/agent-skills-in-action --skill <skill-name>`
- Credentials: `.env` 안 환경 변수 → host agent runtime 안 injection
- Repository structure: skills located in `skills/` directories, organized by chapter

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

## 5. Repository Source (Manning book)

본 repo 은 Manning book "Agent Skills in Action" 의 official codebase. 본 book 의 "systems-engineering handbook for building, deploying, and governing deterministic AI capabilities using the SKILL.md open standard" frame 이 spec 의 SoT.

## 6. claude-discode 와의 관계

claude-discode 자체 12 skill 은 본 SKILL.md standard frontmatter 형식 따름 (name + description + allowedTools 필드). 본 standard 의 vendor 본문 = claude-discode 안 skill 작성 / 검증 시 reference SoT.

본 spec 의 변경 추적 = pin version (vendored at 2026-05-13). 변경 시 manual sync (v2.4 cycle 안 평가).

---

*상세 frontmatter spec / 추가 필드 / chapter 별 예제 는 origin repo 참조.*
*upstream: github.com/agentskills-io/agent-skills-in-action*
