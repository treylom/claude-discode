# claude-discode

> Claude Code + Discord bot + Codex CLI bridge — a Claude Code plugin for course curriculum and personal automation.

One-line setup for WSL / Linux native / macOS. Boots Claude Code + tmux + oh-my-tmux, pairs a Discord bot, and verifies the first conversation — all in a single `bash install.sh`.

---

## 🚀 Quick Start (3 steps)

### Step 1. Environment detection + auto install

```bash
curl -fsSL https://raw.githubusercontent.com/treylom/claude-discode/main/install.sh | bash
```

Or git clone then run locally:

```bash
git clone https://github.com/treylom/claude-discode.git ~/code/claude-discode
cd ~/code/claude-discode && bash install.sh
```

`install.sh` runs 10 steps:

| Step | Action | Dependency |
|---|---|---|
| 1 | OS / Distro detect (WSL / Linux / macOS) | uname |
| 2 | Base packages (tmux + git + curl + jq + build-essential) | apt / dnf / yum / brew / pacman |
| 3 | nvm + Node.js LTS | curl |
| 4 | Claude Code global install | npm |
| 4.5 | **Codex CLI** (`@openai/codex`) global install — bridge layer dependency | npm |
| 5 | oh-my-tmux (`gpakosz/.tmux`) auto install | git |
| 6 | (optional) claude-discode `tmux.conf.local` apply | user confirm |
| 6.5 | **Obsidian CLI** (Mac brew cask / WSL Windows native / Linux snap·flatpak·deb) — 3-Tier fallback tier 1 | brew / snap / manual |
| 7 | Claude Code plugin install guidance (marketplace + 7 slash commands) | (slash inside Claude Code) |
| 8 | First bot wizard guidance (`/claude-discode:start`) | (slash inside Claude Code) |

Plugin slash commands (7 total) auto-detected after install:
- `/claude-discode:start` — Main wizard (env detect + bot setup + first conversation)
- `/claude-discode:install-hooks` — SessionStart + UserPromptSubmit hook merge into `~/.claude/settings.json` (safe merge, preserves existing hooks)
- `/claude-discode:create-bot` — New bot directory + .env + soul.md template auto setup
- `/claude-discode:add-bot` — Add one additional bot
- `/claude-discode:open-meeting` — Create a meeting folder (multi-bot collaboration 4-file standard)
- `/claude-discode:codex-check` — Codex CLI verification (bridge layer activation check)
- `/claude-discode:self-update` — Self-update check (git fetch behind comparison)

Pristine Claude Code bootstrap (no hooks, no bots yet):

```
1. /claude-discode:install-hooks   # Register SessionStart + UserPromptSubmit hooks
2. /claude-discode:create-bot      # First bot directory + soul.md setup
3. /claude-discode:start           # Main wizard (Discord pairing + first conversation)
4. /claude-discode:codex-check     # Verify Codex CLI active (optional)
```

## 📦 Operations know-how guide (docs/)

claude-discode bundles the author's vault operations know-how:

- [03-shared-memory.md](docs/03-shared-memory.md) — **4-tier shared memory** (T1 git-tracked / T2 machine-specific / T3 project-meetings / T4 per-bot WD)
- [04-obsidian-cli.md](docs/04-obsidian-cli.md) — **Obsidian CLI setup** (Mac brew / WSL Windows native / Linux snap·flatpak·deb) + 3-Tier fallback (CLI → MCP → Write/Read/Grep) + known bugs / workarounds
- [06-claude-code-server.md](docs/06-claude-code-server.md) — **Claude Code server modes** (`claude -p` headless one-shot + MCP server + tmux session vs headless split pattern)
- [08-debug-노하우.md](docs/08-debug-노하우.md) — **24+ debugging categories** (Workflow / Code Review / Vault Path / Meeting protocol / Security / Time / LLM Prompt / Schedule / Plugins / External Apps / Cross-bot SoP) — Korean only, comprehensive operational learnings.
- (planned) `05-meeting-thread-protocol.md` — meeting creation SOURCE FACT cross-check + Discord REST API thread + audience direct mention + 3-channel parallel reporting
- (planned) `07-codex-call-layer.md` — `/tofu-at-codex` v2.2 + codex-exec-bridge pattern + Hermes-compatible subprocess plugin

### Step 2. Claude Code authentication

```bash
claude auth login    # 🐧 👤 → browser-based authentication
```

### Step 3. First bot wizard

```bash
tmux new-session -s claude                # 🐧 👤
cd ~/<project> && claude                  # 🐧 🤖
```

Inside Claude Code REPL:

```
/claude-discode:start                     # 🤖 wizard entry
```

The wizard walks you through:
- Discord bot creation (Developer Portal)
- Bot token entry
- First bot persona selection (`soul.md` template)
- Pairing + first conversation verification

---

## 📚 Command icon legend

Icons that appear in code blocks throughout this repo:

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
claude-discode/
├── install.sh                            # Env auto-detect + 10-step automation
├── README.md                              # Korean (primary)
├── README.en.md                           # English (this file)
├── LICENSE                                # MIT
├── CODEX_REVIEW.md                        # Codex 1st adversarial review (recovery plan)
├── CODEX_VERIFY.md                        # Codex 2nd verify (after recovery)
├── .claude-plugin/
│   ├── marketplace.json                   # claude-discode-marketplace
│   └── plugin.json                        # claude-discode v0.1.0
├── commands/                              # 7 slash commands
├── skills/                                # 4 agentskills.io-standard SKILL.md
├── hooks/                                 # 3 bot operations hooks
├── templates/                             # 5 soul.md personas + DISCORD_STATE_DIR
├── configs/                               # tmux.conf.local
└── docs/                                  # Korean curriculum-tone guides
```

---

## 🎯 Use cases

### Scenario A. Zero-state setup on a fresh machine

Fresh WSL Ubuntu or macOS install, setting up Claude Code environment for the first time.

```bash
curl -fsSL https://raw.githubusercontent.com/treylom/claude-discode/main/install.sh | bash
```

### Scenario B. Add Discord bot to an existing setup

Already using Claude Code, want to add a Discord bot with a custom persona.

- Write your first bot's `soul.md` (the wizard provides templates)
- Create the Discord bot + pair it
- Learn the tmux session operations pattern

### Scenario C. Fastcampus curriculum learner

Course learners can follow this repo step-by-step to set up Claude Code + bot environment on their own machine.

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
| Hermes Agent (NousResearch) | 🟡 partial | SKILL.md is portable; Hermes plugin wrapper deferred to L2 pack |
| Codex CLI / Cursor / Gemini CLI / Goose etc. | 🟡 SKILL.md only | agentskills.io standard adopted — `name + description` core 2 keys |

---

## 🧠 Bot persona templates

Choose one of 5 `soul.md` templates during `/claude-discode:create-bot`:

| Template | Best for |
|---|---|
| `general-assistant` | General-purpose assistant (default) |
| `research-bot` | Research / cross-validation / fact-checking |
| `writing-bot` | Writing / editing / persona-driven prose |
| `schedule-bot` | Calendar / Todo / reminders |
| `custom` | Free-form persona with anatomy guide |

Each template ships with frontmatter, persona enforcement rules, signature usage, team structure, and write-boundary tables.

---

## ⚠️ Troubleshooting

### `nvm: command not found`

`source ~/.bashrc` may not work in all shells. **Close the terminal fully and open a new one**.

### `permission denied` on `install.sh`

```bash
chmod +x install.sh
./install.sh
```

Or just `bash install.sh` to bypass the executable bit.

### tmux nesting error (`sessions should be nested with care`)

You already ran `claude` inside a tmux session. Use `Ctrl+B → c` to open a new window (the `ain` helper function handles this automatically).

### git push rejected

Remote has new commits — conflict:

```bash
git pull --rebase
git push
```

### Discord bot pairing code expired

DM the bot again → it issues a fresh code.

### soul.md persona "ghost" (persona not loading)

If your bot's responses don't reflect the persona, the SessionStart hook is likely not registered. Run:

```
/claude-discode:install-hooks
```

This safely merges the bot-session-init.sh hook into `~/.claude/settings.json` while preserving any existing hooks.

---

## 🔬 What's inside (advanced)

### The 3 hooks

The plugin ships 3 portable hook scripts in `hooks/`:

- **`bot-session-init.sh`** (SessionStart) — Auto-detects bot via `DISCORD_STATE_DIR` env var → injects soul.md + per-bot WD memory + common discipline at session start
- **`discord-slash-cmd.sh`** (UserPromptSubmit) — If user prompt's first line is `/cmd`, forces Skill tool invocation (Discord/CLI common slash command pattern)
- **`regression-self-check.sh`** (UserPromptSubmit) — Injects a 4-gate self-check table into stdout to refresh attention against regression patterns

### 4 skills (agentskills.io standard)

- `claude-discode-bootstrap` — installer wizard helper
- `claude-discode-shared-memory` — 4-tier memory policy + Read-before-Edit
- `claude-discode-meetings` — 4-file meeting standard + SOURCE FACT cross-check + Discord REST API threads
- `claude-discode-codex-bridge` — Codex CLI subprocess pattern + `/tofu-at-codex` v2.2 reference

### Codex CLI bridge

claude-discode includes Codex CLI as a first-class bridge layer:

- `codex --version` and `codex exec --no-stream --model gpt-5.5` as subprocess
- Use cases: adversarial review, second-opinion code review, large-scale parallel research
- Verified via `/claude-discode:codex-check`

---

## 🤝 Contributing

This repo is for fastcampus course content + the author's (treylom) vault operations experience.

- PRs and issues welcome
- Debugging know-how contributions welcome
- Course learner feedback welcome

---

## 📄 License

MIT — free to use / modify / redistribute.

Details: [LICENSE](LICENSE)

---

## 🔗 Related resources

- **gpakosz/.tmux** (oh-my-tmux): https://github.com/gpakosz/.tmux
- **agentskills.io** (SKILL.md open standard): https://agentskills.io
- **Anthropic Claude Code**: https://www.anthropic.com/claude-code
- **NousResearch/hermes-agent**: https://github.com/NousResearch/hermes-agent
- **OpenAI Codex CLI**: https://github.com/openai/codex

---

**Korean primary documentation**: [README.md](README.md)
