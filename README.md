# ThisCode

> Claude Code + Discord bot + Codex CLI bridge plugin — designed for Fastcampus curriculum and personal vault automation.
>
> 🇰🇷 **한국어 버전**: [README.ko.md](README.ko.md) · 📘 **Setup**: [docs/SETUP.md](docs/SETUP.md) (developer) · 🌱 [docs/SETUP-BEGINNER.md](docs/SETUP-BEGINNER.md) (beginner) · 🧩 [docs/AGENTS.md](docs/AGENTS.md) (Custom Hybrid v1.0) · ⚙️ **[Config Guide](docs/SETUP-CONFIG-GUIDE.md)** (CLAUDE.md · soul.md · rules · Skills 2.0) · 📄 **[전체 정리 한 장 (HTML)](docs/SUMMARY.html)** · 🤝 **[ThisCodex](https://github.com/treylom/ThisCodex)** (Codex companion)

![ThisCode + ThisCodex architecture](assets/architecture.png)

> **New here?** This one picture is the whole idea: run a Claude Code bot (**ThisCode**) and a Codex bot (**ThisCodex**) from **Discord**, both sharing the same Obsidian vault, memory, and rules. Start with the Setup links above — no prior setup knowledge assumed.

thiscode is a single `bash install.sh` plugin that boots a working Claude Code + tmux + oh-my-tmux environment on WSL / Linux / macOS and pairs a Discord bot end-to-end — but its core value is a **4-Tier vault search fallback** (GraphRAG → vault-search MCP → Obsidian CLI → ripgrep) with **LLM model routing** (Haiku/Sonnet/Opus + Codex path). Discord is secondary; vault-first.

## 🛠️ v2.3 Zero-config Install (NEW — 2026-05-13)

**Prerequisite:** Claude Code CLI already installed + authenticated (https://claude.ai/code). `install.sh` 의 `install-superpowers.sh` step 안 `claude` CLI 호출.

For learners who prefer **single-command setup** (no wizard, no choices):

```bash
git clone https://github.com/treylom/ThisCode ~/.claude/plugins/thiscode
cd ~/.claude/plugins/thiscode
bash scripts/install.sh --apply
```

본 single command installs:

1. **superpowers** plugin (via Claude Code plugin manager)
2. **ripgrep** (Tier 4 baseline — brew / apt / dnf / apk multi-pkg-manager fallback)
3. **Obsidian CLI** detection (Tier 3 — manual download guide if missing)
4. **GraphRAG core** (Tier 1 — vendored Python runtime + 7-pkg pip install)
5. **Dense embedding** (Optional 4-channel — user confirms once, ~1GB)

After install: `bash scripts/healthcheck.sh` (6-phase verification: superpowers + ripgrep + obsidian-cli + vault-search MCP + GraphRAG + Dense embedding).

**Windows users:** WSL 2 (Ubuntu 22.04+) **required**. Native Windows (Cygwin / Git Bash / MSYS) is detected by `install.sh` and instructed to use WSL. PowerShell port is planned for v2.4 cycle.

**Dependency provenance:** full attribution matrix (16 entries — Plugin 1 + Spec doc 2 + External tools 8 + Optional Dense 3 + Vendored Python runtime 1 + thiscode 1) in [ATTRIBUTIONS.md](ATTRIBUTIONS.md). Cross-license compatibility verified by Phase 1 GPT-5.5 review (MIT + Apache 2.0 + BSD-3 + Unlicense — all permissive, copyleft zero).

**Lessons learned (v2.3.x cycle, 9 shared memory entries):** 본 cycle 의 학습 정착은 vault `AI_Second_Brain/.claude-memory/shared/feedback_*` 안 보존:
- `feedback_no_student_term` — learner / 사용자 / 수강자 terminology
- `feedback_autonomy_mode_no_option_questions` — 자율 cycle 옵션 confirm 묻기 zero
- `feedback_no_turn_marker_continuous_execution` — turn 마감 발화 zero, 연속 실행
- `feedback_background_task_proactive_polling` — background task active poll (자동 notification 가정 zero)
- `feedback_debugging_via_codex` — debugging task = codex 위임 의무
- `feedback_fresh_env_actual_install_verification` — Phase 1+2 정적 검수 한계, Phase 3 actual install 필수 ⭐ critical
- `feedback_tofu_at_codex_actual_mechanism` — multi-axis parallel = `/tofu-at-codex` (Agent Teams + sonnet workers)
- `feedback_sonnet_codex_debate_opus_synthesis` — sonnet ↔ codex multi-round debate → opus 종합 mechanism
- `feedback_no_user_decision_zone_autonomous` — 자율 cycle 안 "사용자 결정 영역" 분류 zero (autonomy 3rd 강화)

## 🚀 Quickstart (vault-first, v2.1)

```bash
# 1. Install thiscode as a Claude Code plugin
git clone https://github.com/treylom/ThisCode ~/.claude/plugins/thiscode

# 2. Run the wizard — auto-detects env + recommends a Phase
bash ~/.claude/plugins/thiscode/scripts/thiscode-init.sh

# Or inside Claude Code:
/thiscode:init
```

The wizard detects your vault state / installed tools / resource limits, then recommends an **8-Phase progressive journey**:

- **Phase 1–2**: immediate (ripgrep + obsidian-cli)
- **Phase 3**: 100+ notes → vault-search MCP recommended
- **Phase 4**: 500+ notes (recommended) / 1000+ (strongly recommended) / always optional (GraphRAG)
- **Phase 5**: 2000+ notes → km-at **Mode R preflight** (read-only diagnostics, dry-run apply)
- **Phase 6–7**: advanced (Dashboard / 4-channel hybrid retrieval)

> **GraphRAG = env-detected + opt-in** (user-spec). Force install is permitted even when note count is below the heuristic threshold.

## Optional: Discord bot + Agent Teams

Discord bot integration and tmux-based Agent Teams are **opt-in extras**. The 4-Tier vault search works standalone — Discord pairing is for advanced multi-bot orchestration.

---

## 📊 4-Tier Search Benchmark

How does thiscode's 4-Tier search trade off against vanilla `obsidian-cli` / `/search` / `/vault-search`? Measured on 5 axes. **Measure it against your own vault** — the headline numbers below are aggregates; your hardware / vault size / content distribution will shift them.

```bash
# Measure against your own vault (Tier 1 GraphRAG requires a running server)
VAULT=~/path/to/your/vault bash benchmark/runners/run-all.sh
python3 benchmark/report-generator.py --print-only
```

Expected envelope (reference only — your numbers will differ):

| Tier | Method | latency_ms (P50) | recall@5 | cost_tokens | setup_time_min | kg_depth (avg) |
|------|--------|-------------------|----------|-------------|----------------|----------------|
| 1 | GraphRAG | 1500–3000 | 0.80–0.95 | ~2400 | 25 | 3–5 |
| 2 | vault-search MCP | 500–1000 | 0.60–0.80 | ~800 | 10 | 0 |
| 3 | Obsidian CLI | 200–500 | 0.50–0.70 | 0 | 5 | 0 |
| 4 | ripgrep | 30–100 | 0.30–0.50 | 0 | 0 | 0 |

> Method / interpretation / your-own-fixture guide: [docs/BENCHMARK.md](docs/BENCHMARK.md). CI auto-runs Tier 4 ripgrep + sample fixture: [benchmark/results/](benchmark/results/). The table above is an aggregate strawman — measure against your vault for meaningful numbers.

---

## 🧠 LLM model routing (v2.0)

After retrieval, thiscode picks a model by task complexity:

| Task | Claude users | GPT / [Codex](docs/GLOSSARY.md#codex) users |
|---|---|---|
| Simple (factual lookup) | Haiku | gpt-5.5 |
| Medium (summary / classification) | Sonnet | gpt-5.5-codex |
| Synthesis (multi-doc reasoning) | Opus[1m] | gpt-5.5-opus |

`scripts/route-model.mjs` heuristic — query length + keyword classifier. User override: `--model haiku|sonnet|opus`.

**Tier order (v2.0 correction):** Tier 1 [GraphRAG](docs/SETUP.md#tier-1) → Tier 2 [vault-search MCP](docs/SETUP.md#tier-2) → Tier 3 [Obsidian CLI](docs/SETUP.md#tier-3) → Tier 4 [ripgrep](docs/SETUP.md#tier-4). Accuracy-first fallback.

## 📚 Lost on terms? → [GLOSSARY.md](docs/GLOSSARY.md)

30+ terms (LLM / MCP / CEL / embedding / recall@5 / kg_depth / fallback / dispatcher / etc.).

---

## 🚀 Quick Start (3 steps — legacy Discord path)

### Step 1. Env detect + auto install

```bash
curl -fsSL https://raw.githubusercontent.com/treylom/ThisCode/main/install.sh | bash
```

Or git clone then run locally:

```bash
git clone https://github.com/treylom/ThisCode.git ~/code/thiscode
cd ~/code/thiscode && bash install.sh
```

`install.sh` runs 10 steps:

| Step | Action | Dependency |
|---|---|---|
| 1 | OS / Distro detect (WSL / Linux / macOS) | uname |
| 2 | Base packages (tmux + git + curl + jq + build-essential) | apt / dnf / yum / brew / pacman |
| 3 | nvm + Node.js LTS | curl |
| 4 | Claude Code global install | npm |
| 4.5 | **Codex CLI** (`@openai/codex`) global install — bridge dependency | npm |
| 5 | oh-my-tmux (`gpakosz/.tmux`) auto install | git |
| 6 | (optional) thiscode `tmux.conf.local` apply | user confirm |
| 6.5 | **Obsidian CLI** (Mac brew cask / WSL Windows native / Linux snap·flatpak·deb) — Tier 3 fallback | brew / snap / manual |
| 7 | Claude Code plugin install guidance (marketplace + slash commands) | (slash inside Claude Code) |
| 8 | First bot wizard guidance (`/thiscode:start`) | (slash inside Claude Code) |

Plugin slash commands auto-detected after install:

- `/thiscode:init` — **v2.1 wizard** (env detect + 8-Phase recommend)
- `/thiscode:start` — main wizard (env detect + bot setup + first conversation)
- `/thiscode:install-hooks` — SessionStart + UserPromptSubmit hook safe-merge into `~/.claude/settings.json`
- `/thiscode:create-bot` — new bot directory + .env + soul.md template
- `/thiscode:add-bot` — add one additional bot
- `/thiscode:open-meeting` — create a meeting folder (multi-bot 4-file standard)
- `/thiscode:codex-check` — Codex CLI bridge verification
- `/thiscode:self-update` — self-update check (git fetch behind)

Pristine Claude Code bootstrap (no hooks, no bots yet):

```
1. /thiscode:install-hooks   # Register SessionStart + UserPromptSubmit hooks
2. /thiscode:create-bot      # First bot directory + soul.md setup
3. /thiscode:start           # Main wizard (Discord pairing + first conversation)
4. /thiscode:codex-check     # Verify Codex CLI active (optional)
```

## 📦 Operations know-how guide (docs/)

thiscode bundles the author's vault operations playbook:

- [03-shared-memory.md](docs/03-shared-memory.md) — **4-tier shared memory** (T1 git-tracked / T2 machine-specific / T3 project-meetings / T4 per-bot WD)
- [04-obsidian-cli.md](docs/04-obsidian-cli.md) — **Obsidian CLI setup** (Mac brew / WSL Windows native / Linux snap·flatpak·deb) + 3-Tier fallback (CLI → MCP → Write/Read/Grep) + known bugs / workarounds
- [06-claude-code-server.md](docs/06-claude-code-server.md) — **Claude Code server modes** (`claude -p` headless + MCP server + tmux session vs headless split pattern)
- [08-debug-노하우.md](docs/08-debug-노하우.md) — **24+ debugging categories** (Workflow / Code Review / Vault Path / Meeting protocol / Security / Time / LLM Prompt / Schedule / Plugins / External Apps / Cross-bot SoP) — Korean only, dense operational learnings

### Step 2. Claude Code authentication

```bash
claude auth login    # 🐧 👤 → browser-based authentication
```

### Step 3. First bot wizard

```bash
tmux new-session -s claude                # 🐧 👤
cd ~/<project> && claude                  # 🐧 🤖
```

Inside Claude Code:

```
/thiscode:start                     # 🤖 wizard entry
```

The wizard walks you through Discord bot creation (Developer Portal), token entry, persona selection (`soul.md` template), and pairing + first conversation verification.

---

## 📚 Command icon legend

| Icon | Meaning |
|---|---|
| 🖥️ | Windows PowerShell |
| 🐧 | WSL Ubuntu / Linux terminal |
| 🤖 | Claude Code executes automatically |
| 👤 | User types directly |
| ✅ | Success |
| ❌→✅ | Failure followed by recovery |

---

## 🧩 Repository structure

```
thiscode/
├── install.sh                            # Env auto-detect + 10-step automation
├── README.md                              # This file (English, default)
├── README.ko.md                           # Korean version
├── LICENSE                                # MIT
├── .claude-plugin/
│   ├── marketplace.json                   # thiscode-marketplace
│   └── plugin.json
├── commands/                              # Slash commands (incl. /thiscode:init)
├── skills/                                # 12 skill (v2.2 vault-mirror policy)
│   ├── knowledge-manager/                 # vault 풀 7-Layer Fusion (1161 lines)
│   ├── knowledge-manager-at/              # Agent Teams variant (1189 lines)
│   ├── knowledge-manager-lite/            # Lite single-agent (530 lines)
│   ├── knowledge-manager-bootstrap/       # 4-Tier install 합본
│   ├── knowledge-manager-plain/           # headless variant
│   ├── search/                            # 4-Tier vault search
│   ├── search-lite/                       # 3-Tier (no GraphRAG)
│   ├── codex-exec-bridge/                 # vault skill mirror (folder)
│   ├── init/                              # v2.1 wizard skill
│   ├── bootstrap/                         # plugin install wizard
│   ├── meetings/                          # 4-file meeting protocol
│   └── shared-memory/                     # 4-tier memory policy
├── hooks/                                 # Bot operations hooks
├── templates/                             # 5 soul.md personas
├── configs/                               # tmux.conf.local
├── benchmark/                             # 4-Tier benchmark (run-all.sh + fixtures)
├── contracts/                             # search-fallback-4tier.md (v2.0.3)
├── schemas/                               # agent-spec.json (Custom Hybrid v1.0, v2.1)
├── scripts/                               # install-graphrag.sh / install-obsidian-cli.sh / route-model.mjs
└── docs/                                  # SETUP / SETUP-BEGINNER / AGENTS / GLOSSARY / BENCHMARK / ARCHITECTURE / MANUAL
```

---

## 🎯 Use cases

### Scenario A. Zero-state setup on a fresh machine

Fresh WSL Ubuntu or macOS, setting up Claude Code for the first time.

```bash
curl -fsSL https://raw.githubusercontent.com/treylom/ThisCode/main/install.sh | bash
```

### Scenario B. Add Discord bot to an existing Claude Code user

Pair a Discord bot with a custom persona — Write `soul.md`, create the bot, run `/thiscode:start`.

### Scenario C. Fastcampus curriculum learner

Follow the wizard. The 8-Phase journey takes you from ripgrep-only to GraphRAG-with-Mode-R-preflight at your own pace.

---

## 🔧 Compatibility

| Environment | Support | Notes |
|---|---|---|
| **WSL Ubuntu 20.04+** | ✅ primary | `install.sh` most-tested target |
| **Linux native** (Debian / Ubuntu / Fedora / Arch) | ✅ | Package manager auto-detected |
| **macOS** | ✅ | brew-based |
| **Windows native** | ❌ | Use WSL instead |

| Agent runtime | Compatibility | Notes |
|---|---|---|
| **Claude Code** | ✅ primary target | Anthropic official CLI |
| Hermes Agent (NousResearch) | 🟡 partial | SKILL.md is portable; Hermes wrapper deferred |
| Codex CLI / Cursor / Gemini CLI / Goose | 🟡 SKILL.md only | agentskills.io standard adopted |

---

## ⚠️ Troubleshooting

### `nvm: command not found`

`source ~/.bashrc` may not work in all shells. **Close the terminal fully and open a new one**.

### `permission denied` on `install.sh`

```bash
chmod +x install.sh
./install.sh
```

Or just `bash install.sh`.

### tmux nesting error (`sessions should be nested with care`)

You already ran `claude` inside a tmux session. Use `Ctrl+B → c` to open a new window (the `ain` helper handles this automatically).

### git push rejected

Remote has new commits:

```bash
git pull --rebase
git push
```

### Discord bot pairing code expired

DM the bot again → it issues a fresh code.

### soul.md persona "ghost" (persona not loading)

If your bot's responses don't reflect the persona, the SessionStart hook is likely not registered:

```
/thiscode:install-hooks
```

This safely merges the bot-session-init.sh hook into `~/.claude/settings.json` while preserving any existing hooks.

### GraphRAG server won't start (v2.3 — vendor 의존 + ~/.cache venv)

```bash
bash scripts/install-graphrag.sh --check     # python3 + vendor SoT + requirements + venv + server health
bash scripts/install-graphrag.sh --preflight # Python 3.10+ / disk 5GB+ / port 8400 / vendor SoT check
bash scripts/install-graphrag.sh --apply     # venv 생성 + pip install + nohup uvicorn
```

The `--apply` mode (v2.3):
- venv 위치 = `~/.cache/thiscode/graphrag/venv` (writable home cache)
- vendor SoT = `<thiscode>/vendor/graphrag/scripts/` (vault SoT 와 동등 박제, 21 file)
- requirements = `vendor/graphrag/scripts/requirements.txt` (7 deps: networkx / louvain / pyyaml / fastapi / uvicorn / numpy / httpx)
- entry = `uvicorn search_server:app --host 127.0.0.1 --port 8400` (background nohup)
- log = `~/.cache/thiscode/graphrag/run/graphrag.log`

---

## 🔬 What's inside (advanced)

### The 3 hooks

- **`bot-session-init.sh`** (SessionStart) — auto-detects bot via `DISCORD_STATE_DIR` env var → injects soul.md + per-bot WD memory + common discipline
- **`discord-slash-cmd.sh`** (UserPromptSubmit) — if user prompt's first line is `/cmd`, forces Skill tool invocation
- **`regression-self-check.sh`** (UserPromptSubmit) — injects a 4-gate self-check table to refresh attention against regression patterns

### Skills (agentskills.io-standard)

- `thiscode-init` — v2.1 onboarding wizard (env detect + 8-Phase recommend)
- `thiscode-bootstrap` — installer wizard helper
- `thiscode-shared-memory` — 4-tier memory policy + Read-before-Edit
- `thiscode-meetings` — 4-file meeting protocol + SOURCE FACT cross-check + Discord REST API threads
- `thiscode-codex-bridge` — Codex CLI subprocess + `/tofu-at-codex` v2.2 reference
- `thiscode-km-at` — km-at Mode R preflight (read-only diagnostics + dry-run apply)

### Codex CLI bridge

thiscode includes Codex CLI as a first-class bridge layer:

- `codex --version` and `codex exec --no-stream --model gpt-5.5` as subprocess
- Use cases: adversarial review, second-opinion code review, large-scale parallel research
- Verified via `/thiscode:codex-check`

### Custom Hybrid v1.0 agent spec

`schemas/agent-spec.json` defines a per-agent contract registry combining agentskills.io base + Hermes `provides_*` + thiscode classroom policy + dynamic gates + benchmark integration. v2.1 adds `tier: core` (init wizard) and `phases:` for km-at Mode R preflight workflow.

---

## 🤝 Contributing

This repo is for Fastcampus course content + the author's (`treylom`) vault operations experience.

- PRs and issues welcome
- Debugging know-how contributions welcome
- Course learner feedback welcome

---

## 📄 License

MIT — free to use / modify / redistribute. Details: [LICENSE](LICENSE)

---

## 🔗 Related resources

- **gpakosz/.tmux** (oh-my-tmux): https://github.com/gpakosz/.tmux
- **agentskills.io** (SKILL.md open standard): https://agentskills.io
- **Anthropic Claude Code**: https://www.anthropic.com/claude-code
- **NousResearch/hermes-agent**: https://github.com/NousResearch/hermes-agent
- **OpenAI Codex CLI**: https://github.com/openai/codex

---

🇰🇷 **Korean version**: [README.ko.md](README.ko.md)
