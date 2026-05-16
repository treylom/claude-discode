# Setup → Config Guide — wiring your bot's brain

> After [SETUP.md](SETUP.md) installs thiscode, **this guide configures the bot's
> behavior**: the three config surfaces a bot reads, in what order, and how to
> author each one. It is a *hub* — it links to the existing templates/specs
> instead of repeating them (the same progressive-disclosure idea the rules
> system uses: load depth only when you need it).
>
> Hard English terms are glossed in parentheses on first use, for non-developer
> readers. 🇰🇷 Korean mirror at the bottom (`## 한국어`).

## The three config surfaces (and load order)

A thiscode bot composes its behavior from three files, loaded in this order:

```
1. CLAUDE.md / AGENTS.md / GEMINI.md   ← project + bot working-dir meta. Points
   (always loaded; harness-specific)     ONLY at rules/INDEX.md (not the rules).
        ↓
2. soul.md                              ← persona / voice / model meta.
   (SessionStart hook auto-injects it)    Pick a templates/soul-*.md, fill it.
        ↓
3. rules/INDEX.md                       ← progressive-disclosure (load only the
   (router; topical files on demand)      rule that the current situation needs)
        ↓
   memory / meetings                    ← run-time state, not config
```

**single source of truth** (단일 기준 출처 — one place each fact lives): each
surface owns a distinct concern. Do not copy rules into `CLAUDE.md` or `soul.md`
— that is the context-bloat failure the rules system exists to prevent.

| Surface | Harness | What it owns | Author from |
|---|---|---|---|
| `CLAUDE.md` | Claude Code | project meta + bot-WD meta + INDEX pointer | §1 below |
| `AGENTS.md` | Codex (see [ThisCodex](https://github.com/treylom/ThisCodex)) | same role, Codex side | §1 below |
| `GEMINI.md` | Gemini CLI | same role, Gemini side | §1 below |
| `soul.md` | all (SessionStart inject) | persona, voice, signatures, model | §2 → `templates/` |
| `rules/` | all (on-demand) | situational operating rules | §3 → [rules-system.md](https://github.com/treylom/ThisCodex/blob/master/docs/rules-system.md) |

## §1 — CLAUDE.md / AGENTS.md / GEMINI.md (the meta file)

This file is **always in context**, so keep it thin. It carries: (a) what the
project is, (b) the bot's working-directory role, (c) the **load order above**,
and (d) a single pointer to `rules/INDEX.md` — never the rule bodies.

Minimal template (same shape for AGENTS.md / GEMINI.md — just the filename
differs per harness):

```markdown
# <Project> — bot working-dir meta

This dir is both the project root and **<BotName>'s working dir**. On a bot
session, load in order:

0. ./CLAUDE.md (this file — project + bot-WD meta)
1. <path>/soul.md (persona · voice · model)
2. rules/INDEX.md (situational rules — Read the matched topic file on demand)
3. meetings/<date>-<topic>/ (current task context)

**Bot meta**: <BotName> (`<@discord-id>`) · <one-line role> · model `<id>` ·
WD `<abs-path>`.

## Operating rules = rules/ (progressive disclosure)
Every turn: self-check rules/INDEX.md trigger table → Read the matched row's
file → apply. Conflict priority: **explicit user instruction > rule file >
inline default**.
```

Gotchas:
- The pointer block must be the *only* rules content here. If a rule starts
  growing inline, move it to `rules/<topic>.md` and leave one INDEX row.
- Tool-managed auto-blocks (e.g. an installer's marker block) stay where the
  tool regenerates them — moving them causes the tool to re-add and conflict.

## §2 — soul.md (persona / voice / model)

Do not write this from scratch. thiscode ships fillable templates:

| Template | For |
|---|---|
| [`templates/soul-custom.md`](../templates/soul-custom.md) | blank anatomy (11 sections, fill what fits) |
| [`templates/soul-general-assistant.md`](../templates/soul-general-assistant.md) | general helper |
| [`templates/soul-research-bot.md`](../templates/soul-research-bot.md) | research / source-tracing |
| [`templates/soul-writing-bot.md`](../templates/soul-writing-bot.md) | writing persona |
| [`templates/soul-schedule-bot.md`](../templates/soul-schedule-bot.md) | scheduling / reminders |

Steps:
1. Copy the closest template to your bot's working dir as `soul.md`.
2. Fill the **frontmatter** (문서 맨 위 `---` 메타 블록 — `name`, `description`,
   `version`, `triggers`). The SessionStart hook reads this to auto-inject.
3. Keep the **forced-persona self-check table** and the **completion signature**
   (`— <BotName>`) — signature absence is the #1 persona-regression symptom.
4. Set the model meta to a real model id your harness exposes.

The persona is enforced *per response*, not just declared — the self-check
table at the top of every template is what makes it stick.

## §3 — rules/ (progressive-disclosure operating rules)

Full convention (problem, pattern, how-to-add, Codex variant):
**[rules-system.md](https://github.com/treylom/ThisCodex/blob/master/docs/rules-system.md)**
— the canonical copy lives in the ThisCodex companion repo. Read it once; do
not duplicate it here.

회의 스레드·채널·대화기록 보관 거버넌스: [05-meeting-thread-protocol.md](05-meeting-thread-protocol.md) (정책 SoT = vault rules/channel-governance.md — 새 주제=새 스레드 / 보관=최종 산출만 / 기기간=멀티버스).

Minimal worked example — a bot that must always reply via a channel tool:

`rules/INDEX.md` (router — the only file the meta file points at):
```markdown
| Trigger (when this situation) | Rule file | One-line gist |
|---|---|---|
| Replying to an external channel | discord-comms.md | Use the reply tool; terminal text never reaches the user |
```
`rules/discord-comms.md` (loaded only when that row matches):
```markdown
# Rule: external-channel reply
- The user reads the channel, not your terminal transcript. Send via the
  channel reply tool. Terminal-only output = user never sees it.
```
Each turn: scan INDEX triggers → match → Read that one file → apply. No match →
proceed. Rules are paid for (in context) only when relevant.

## §4 — How to set up & how to ask (first run)

After install + the three files above:

```
/thiscode:setup            # (re)configure tiers
/thiscode:search "..."     # 4-Tier vault search
```

Example prompts and what to expect:

| You ask | The bot does |
|---|---|
| "Summarize my notes on attention mechanisms" | vault search (Tier 1→4 fallback) → grounded summary with source paths |
| "Set yourself up as a scheduling bot" | reads `templates/soul-schedule-bot.md`, helps you fill `soul.md` |
| "Why did you do X?" | answers from the loaded soul + the rule that applied (it tells you which) |

If a reply seems off-persona or ignores a rule: check (a) `soul.md` frontmatter
is valid, (b) the situation actually matches a `rules/INDEX.md` trigger row.

## §5 — Skills 2.0 conformance checklist

Any skill you add under `skills/<name>/SKILL.md` should pass these (the standard
that keeps skills discoverable + token-efficient):

- [ ] **Frontmatter present** — `---` block with `name` + `description`
- [ ] `name:` is **kebab-case**, matches the directory
- [ ] `description:` is **third-person** and uses a **"Use when …"** trigger phrase
- [ ] **SKILL.md ≤ 500 lines** — heavy detail goes to `references/` (progressive
      disclosure: load depth on demand)
- [ ] **Directory structure** — every skill dir has a `SKILL.md` (no orphan dirs)
- [ ] **No broken references** — every `references/` link resolves
- [ ] **Imperative form** — body says "Run", "Check" (not "you should …")
- [ ] **Reference-type skills** (guide/spec/templates/examples) set
      `disable-model-invocation: true` so they are not auto-triggered

This checklist **is** the conformance standard (Anthropic Skills 2.0 — the
12-check rubric: frontmatter, name, description, ≤500 lines, directory
structure, invocation control, no orphans/broken refs, progressive disclosure,
imperative form). Walk every box manually before a push. Also grep the diff
for hardcoded user paths / secrets before any push (see the privacy lesson in
this repo's history) — never publish without that scan.

## §6 — Force-invoke the `/prompt` skill

The bundled `skills/prompt/` skill must be **mandatorily invoked** for any
prompt-authoring work (writing/refining a prompt, GPTs/Gems instructions,
fact-check/research/image prompting) — never free-hand a prompt.

Wire the enforcement into the bot's config so it cannot be skipped:

- In `CLAUDE.md` / `AGENTS.md` (the always-loaded meta), add one line under the
  rules pointer: *"Prompt-authoring tasks → MUST invoke the `prompt` skill
  before producing any prompt (no ad-hoc prompts)."*
- Or add a `rules/INDEX.md` row: `Producing a prompt for a model | prompt-skill.md | Invoke skills/prompt first; never hand-roll`.
- In `soul.md`, the forced-persona self-check table is the right place for a
  hard rule (see `templates/soul-custom.md` — a `/prompt` enforcement line is
  included there).

Why a hard rule: prompt quality regresses to ad-hoc without enforced routing;
the skill's frameworks (IFCN fact-check base, 5-stage image, GPTs/Gems
structure) are only applied if the skill is actually entered.

## See also

- [SETUP.md](SETUP.md) — install (this guide is what comes *after*)
- [SETUP-BEGINNER.md](SETUP-BEGINNER.md) — non-developer install walkthrough
- [AGENTS.md](AGENTS.md) — the `.agents/*.yaml` skill/command spec (different layer)
- [ThisCodex](https://github.com/treylom/ThisCodex) — the Codex-side companion runtime

---

## 한국어

[SETUP.md](SETUP.md) 설치 **후**, 봇 행동을 설정하는 가이드입니다. 봇이 읽는
세 설정 표면과 **로딩 순서**, 각 작성법을 묶어 줍니다. 깊은 내용은 기존
템플릿·스펙 문서로 링크(필요할 때만 펼치는 progressive disclosure — 점진적
노출 — 방식, rules 시스템과 동일 철학). 어려운 영어 용어는 첫 등장에 풀이.

### 세 설정 표면 + 로딩 순서

`CLAUDE.md/AGENTS.md/GEMINI.md`(프로젝트+봇 WD 메타, 항상 로드 — **rules/INDEX.md
만 가리킴**) → `soul.md`(페르소나·말투·모델, SessionStart 훅이 자동 주입) →
`rules/INDEX.md`(라우터, 상황 매칭 시 해당 토픽 파일만 그때 Read) → 메모리/회의록.

**single source of truth(단일 기준 출처)**: 각 표면은 서로 다른 관심사를
소유합니다. 규칙을 CLAUDE.md/soul.md 에 복붙하지 마세요 — 그게 rules 시스템이
막으려는 context 비대화입니다.

### §1 메타 파일 (CLAUDE/AGENTS/GEMINI)
항상 context 에 있으므로 얇게. (a) 프로젝트 (b) 봇 WD 역할 (c) 위 로딩 순서
(d) `rules/INDEX.md` 포인터 1개 — 규칙 본문 금지. 템플릿은 위 영문 §1 코드블록
참고(파일명만 harness 별로 다름: Claude=CLAUDE.md, Codex=AGENTS.md, Gemini=GEMINI.md).

### §2 soul.md
직접 쓰지 말고 `templates/soul-*.md` 5종 중 가장 가까운 걸 봇 WD 에 `soul.md`
로 복사 → frontmatter(문서 맨 위 `---` 메타 블록) 채움 → 자가점검 표 + 완료
서명(`— <봇이름>`) 유지(서명 부재 = 페르소나 소실 1순위 신호) → 모델 메타를
harness 가 실제 노출하는 모델 id 로.

### §3 rules/
전체 컨벤션 = [rules-system.md](https://github.com/treylom/ThisCodex/blob/master/docs/rules-system.md)
(정본은 ThisCodex 동반 레포에 있음, 중복 작성 금지). 매 턴 INDEX 트리거 표
스캔 → 매칭 행 파일 그때 Read → 적용.
충돌 우선순위 = **사용자 명시 지시 > rule 파일 > inline 기본**.

### §4 설정·질문 방법
설치 후 `/thiscode:setup`, `/thiscode:search "질의"`. 예: "내 attention 노트
요약" → 4-Tier 검색 후 출처 경로 포함 요약. 응답이 페르소나/규칙을 벗어나면
soul.md frontmatter 유효성 + INDEX 트리거 매칭을 점검.

### §5 Skills 2.0 체크리스트
`skills/<name>/SKILL.md` 추가 시: frontmatter 존재 · `name` kebab-case ·
`description` 3인칭 + "Use when …" · SKILL.md ≤500줄(초과분 `references/`) ·
orphan 디렉토리 없음 · 깨진 reference 없음 · 명령형 어조 · reference형 스킬은
`disable-model-invocation: true`. **본 체크리스트가 곧 표준**(Anthropic
Skills 2.0 12-check 루브릭). push 전 매 항목 수동 확인 + diff 에서 하드코딩
경로·시크릿 grep 검사 필수(본 레포 history 의 privacy 교훈 — 미검사 publish 금지).
