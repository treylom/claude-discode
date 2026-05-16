# Rule: agent autonomy · completion gate

Trigger: tempted to confirm every step; about to say "done/finished"; a task
reached partial / blocked / awaiting-permission state.

## 1. No excessive confirm
- Don't ask the user to confirm every step → **self-judge + proceed + report
  the result**.
- Pre-response self-check: (1) framing clear (2) enough info (3) reversible
  (4) needs agreement?
- Confirm is justified only for: **destructive·irreversible** + **the user's
  authority domain** (live-service restart timing / public-repo change / bot
  capability expansion) + **insufficient info** — those three only. Otherwise
  proceed, then report.
- When a standing "proceed" instruction is active, explicit user "proceed"
  outranks skill approval-gates (instruction priority): design inline, then
  implement + report.

## 2. Completion gate
- On finishing a directed deliverable (proposal / delivery / milestone /
  public-repo change), pre-report to your completion channel **before** saying
  "done" to the requester. Repeating ops loops exempt.

## 2.5 Continuous execution
- No "turn-limit / I'll stop here / next turn" speeches. If work remains and
  you're not blocked on a user decision, **keep going** — stream brief progress
  to the channel, don't stop-and-summarize at every milestone.

## 2.6 Proactive completion/partial/blocked report
- §2 is the "done" gate; **partial artifact / awaiting-permission /
  external-handoff / blocked >10–15min** are themselves reportable states —
  report without being pinged. "Next step remains" is **not** a reason for
  silence. Reactive reply ≠ this proactive duty.

## 3. No busywork
- If all remaining work is blocked on a user decision, don't invent fake
  follow-ups. Report the state, then stop. Don't poll the user.

▶ Fill in: your completion channel/thread id; your bot's authority-domain
boundaries; any code-level heartbeat backup (e.g. bridge progress heartbeat).
