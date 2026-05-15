# Session ↔ Channel UX (borrowed pattern)

> **Adopted from** [joungminsung/codex-discord-connector](https://github.com/joungminsung/codex-discord-connector) (see [ATTRIBUTIONS.md](../ATTRIBUTIONS.md)). We borrow the **UX shape** (channel-mode routing, session lifecycle commands), not its code. ThisCode keeps its own bridge architecture (see [docs/AGENTS.md](AGENTS.md)).

## Why borrow this

ThisCode runs Codex/Claude bots that hold long-lived conversations. A single Discord channel quickly becomes a mess of unrelated sessions. The connector's insight: **map one Codex session to one Discord channel, and gate commands by the channel's *mode*.** That makes "which conversation am I in" a property of *where you're typing*, not something the user has to track.

## The pattern (3 channel modes)

| Mode | Role | What runs here |
|---|---|---|
| **Admin** | control plane | bot lifecycle, slash re-register, cross-session ops, scheduling. No per-session Codex chat. |
| **Main** | entry / dispatch | start a new session → bot creates a **Session channel** and replies with its link |
| **Session** | one Codex thread | natural-language `/codex` turns, `/shell`, `/codex-command` shortcuts, `model`/`compact`/`mcp` — scoped to *this* session only |

A command issued in the wrong mode is **blocked with a guiding message** (e.g. a sync/admin command typed in a Session channel) instead of silently doing the wrong thing.

## Lifecycle commands (UX vocabulary to mirror)

| Command | Effect |
|---|---|
| `/codex prompt:<…>` | natural-language turn to the session's Codex thread |
| `/shell command:<…>` (or `!<cmd>`) | run in the session cwd |
| `/codex-command command:<name> prompt:<…>` | shortcut router: `model`, `review`, `compact`, `mcp`, `diff` |
| `/sync-delete mode:preview/all/channels/session session_id:<id> confirm:<bool>` | preview-then-confirm channel cleanup; **never** deletes local Codex session files |
| `/sync-archive session_id:<id> confirm:<bool>` | exclude a session from the next sync (bridge archive list) |
| `/schedule action:create mode:once/every/daily/weekly command:<…> at:<…>` | re-run a chat-style command on a schedule |
| `/reload mode:commands` | re-register Discord slash commands |

Two UX guarantees worth keeping: **destructive ops are preview→confirm** (a card with an explicit `confirm:true`), and **local session state is never destroyed by a Discord-side delete** (channel cleanup ≠ session deletion).

## How ThisCode maps this onto its own runtime

ThisCode already has the bridge + `bot-roster.yaml` + per-bot WD. The borrowed bits:

- **Session = a bot WD + its Codex `thread-id`** (ThisCode persists `.codex-thread-id`; resume re-applies sandbox — see ThisCodex `docs/skill-portability.md` §3). A "Session channel" binds to one `thread-id`.
- **Channel-mode gating** layers on top of the existing cross-bot mention rule: Admin channel = roster/lifecycle, Session channel = `require_mention:false` direct turns (mirrors the existing direct-channel exemption in §4 of the README).
- **Preview→confirm + state-safe delete** become the contract for any ThisCode sync/cleanup command (do not delete `~/.codex/sessions/**`; only the Discord-side mapping).

This is a documented convention + roadmap item, not yet a shipped command set in ThisCode. Implement incrementally; the connector repo is the reference UX.
