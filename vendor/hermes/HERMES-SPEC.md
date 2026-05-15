# Hermes Agent — Vendored Spec

> **Origin:** github.com/NousResearch/hermes-agent
> **License:** MIT (see `LICENSE`)
> **Vendored at:** 2026-05-13 (latest upstream update 2026-05-13)
> **Vendored by:** thiscode v2.3
>
> 본 doc 은 Hermes Agent 의 agent spec 요약 — closed-loop learning platform architecture. full repo 는 origin 참조.

## 1. Core Architecture

Hermes Agent = Nous Research 의 self-improving AI system. 본 agent 가 **closed-loop learning platform** 으로 동작 — skill 을 experience 에서 만들고, 사용 중 improvement, persistent user model 을 session 간 유지.

본 agent loop 의 stage:
1. Context assembly
2. Tool invocation
3. Output generation
4. Memory persistence

State module:
- `hermes_state.py` — agent state 보존
- `hermes_logging.py` — log
- `hermes_bootstrap.py` — runtime init

## 2. Key Subsystems

### Skills Engine (`skills/`)
- Procedural memory system
- Autonomous skill creation + self-improvement support

### Tools Framework (`tools/`)
- 40+ integrated capabilities
- Terminal backends: local / Docker / SSH / Singularity / Modal / Daytona / Vercel Sandbox

### Memory Layer
- Full-text search + LLM summarization for cross-session recall
- Honcho-based user modeling

### Gateway System (`gateway/`)
- Multi-platform messaging: Telegram / Discord / Slack / WhatsApp / Signal

## 3. Deployment Flexibility

본 architecture = hardware constraint 분리. 본 agent 가 "$5 VPS, GPU clusters, or serverless infrastructure" 안 작동. Daytona + Modal = hibernation 지원 → session 간 environment 저렴하게 보존.

## 4. Usage Model

### CLI Mode
```bash
hermes      # 본 terminal UI — multiline editing + slash-command autocomplete + 대화 history + streaming tool output
```

### Messaging Gateway
```bash
hermes gateway   # remote infrastructure 안 agent 실행, messaging platforms 안 access
```

### Common commands
- `/new` — start conversation
- `/model` — switch LLM provider
- `/skills` — browse capabilities
- `/retry` — undo last turn

## 5. Model Agnostic

본 system = LLM endpoint 자유 — Nous Portal / OpenRouter (200+ models) / NVIDIA NIM / OpenAI / Anthropic Claude / custom endpoints. 본 model 전환 = `hermes model` 만, 코드 modification zero.

## 6. Learning Loop

본 agent 의 진정 learning:
- **Autonomous skill creation** after complex tasks
- **Skill self-improvement** during use
- **Persistent nudges** for knowledge consolidation
- **Session search** = FTS5 + LLM summarization
- **User modeling** = dialectic technique

## 7. Automation & Delegation

Built-in cron scheduling 안 unattended task ("daily reports, nightly backups, weekly audits") platform 자유 발송. 본 system 안 isolated subagents 분기 spawn (parallel workstream). Python script 안 RPC 실행 — "multi-step pipelines into zero-context-cost turns".

## 8. Research Integration

본 system 안:
- Batch trajectory generation
- Atropos RL environments
- Trajectory compression
→ 다음 tool-calling 모델 train 의 SoT.

## 9. Installation

Linux / macOS / WSL2 / Termux 안 unified single command 으로 작동. Windows native = early beta. Full docs: hermes-agent.nousresearch.com/docs.

## 10. thiscode 와의 관계

thiscode 의 agent spec design (agents.yaml + .agents/*.yaml hybrid) 의 reference 본 Hermes agent loop architecture. thiscode 본 vendor 본문 = agent spec 작성 / 검증 시 reference SoT.

본 spec 의 변경 추적 = pin version (vendored at 2026-05-13). 변경 시 manual sync (v2.4 cycle 안 평가).

---

*상세 hermes_state.py / hermes_logging.py / 모듈 spec 은 origin repo 참조.*
*upstream: github.com/NousResearch/hermes-agent*
