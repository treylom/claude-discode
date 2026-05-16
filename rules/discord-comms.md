# Rule: external-channel communication

Trigger: any moment you respond/report/notify to an external channel
(Discord etc.).

## 1. Reply gate (critical)
- The user reads the channel, **not** your terminal transcript. Send via the
  channel reply tool. Terminal-only output = the user never sees it.
- In a channel session, do not use terminal-only UI prompts — present choices
  as plain channel text.
- Inbound arrives as a `<channel chat_id=… message_id=…>` block → reply with
  that `chat_id` (use `reply_to=message_id` to thread under an earlier message;
  omit for the latest).

## 2. Addressing another bot
- In a shared channel, a message aimed at another bot **must** carry its
  `<@user_id>` mention or a `reply_to` — otherwise the receiving bot silently
  drops it. Derive user_ids deterministically; never guess/invent bot names.
- **Split-message retag**: if a long message is auto-split into 2+ parts,
  re-include the recipient `<@user_id>` mention at the head of **every**
  continuation part. A continuation without the mention is silently dropped
  (= effectively unsent). Self-check: if the send result reports "N parts",
  verify each part carries the mention; prefer compressing to one part. Ask
  other bots to do the same when their reports are truncated.

## 3. Meeting / topic threads
- ≥2 bots · ≥10 min · has an agenda (2-of-3) → spin a dedicated thread; the
  main channel gets only a redirect. One-shot relays/acks stay inline.

## 4. Completion gate
- On finishing a directed deliverable, pre-report to your completion/report
  channel **before** saying "done" to the requester. Repeating ops loops are
  exempt.

▶ Fill in: your reply tool name; your bots' user_ids + roster source; your
completion-report channel/thread id; which channels are meeting vs. main.
