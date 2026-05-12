---
name: claude-discode-codex-bridge
description: Use when delegating coding or research tasks to Codex CLI (gpt-5.5) from Claude Code, Hermes, or other agent runtimes. Wraps the codex exec subprocess pattern (CLI invocation, status file, dynamic gate, error recovery, team communication) so users can call /tofu-at-codex-style hybrid teams without re-implementing the protocol.
license: MIT
compatibility: Codex CLI (npm @openai/codex) + ChatGPT OAuth (Plus 이상) + Claude Code (primary) / Hermes (subprocess wrapper)
metadata:
  author: 김재경 (treylom)
  version: "0.1.0"
  hermes:
    tags: [Codex, Subprocess, BotOrchestration]
    requires_tools: [bash]
---

# claude-discode-codex-bridge

> **사용 시점**: 코딩·리서치 task 를 GPT-5.5 (Codex) 에 위임할 때. Lead (Opus / Sonnet) + Workers (Codex) + DA (Codex adversarial) 하이브리드 패턴.

## 5-section anatomy (vault `codex-exec-bridge` skill 재활용)

vault `.claude/skills/codex-exec-bridge/` 6-file 구조를 본 plugin 안에 packaging:

1. **§1 CLI Invocation** — `codex exec` 기본 호출, reasoning effort, 플래그, 타임아웃
2. **§2 Status File** — 상태 파일 protocol (위치, atomic write, 상태 머신)
3. **§3 Dynamic Gate** — 결과 검증 (순서, 형식, FAIL 흐름)
4. **§4 Error Recovery** — timeout / rate limit / auth error 회복
5. **§5 Team Communication** — Lead ↔ Worker ↔ DA 보고 패턴

## §1. CLI 기본 호출

### 단일 호출 (코딩 task)

```bash
codex exec --no-stream --model gpt-5.5 "$prompt"
```

| 플래그 | 역할 |
|---|---|
| `--no-stream` | 스트리밍 비활성 (output 한 번에) |
| `--model gpt-5.5` | 모델 명시 (default 가 다를 수 있음) |
| `--full-auto` | 자동 승인 (sandbox 없이 실행, 자동화 시 권장) |
| `--timeout 300` | 5분 cap |

### Adversarial review (DA)

```bash
codex exec --no-stream --model gpt-5.5 --json adversarial-review --scope working-tree
```

→ JSON output 받음 (concerns + score). working-tree scope = 모든 변경 검사. `--base HEAD~N` 회피 (R13 회귀 — diff 만 분석 시 본 코드 무시).

## §2. 상태 파일

긴 task 시 status file 로 진행 추적:

```bash
STATUS_FILE=".codex/status-${task_id}.json"
mkdir -p .codex

# 시작
echo '{"status":"running","started_at":"'$(date -Iseconds)'","task":"'$task'"}' > "${STATUS_FILE}.tmp"
mv "${STATUS_FILE}.tmp" "${STATUS_FILE}"     # atomic

# 종료
echo '{"status":"completed","ended_at":"'$(date -Iseconds)'","exit_code":'$?'}' > "${STATUS_FILE}.tmp"
mv "${STATUS_FILE}.tmp" "${STATUS_FILE}"
```

상태 머신: `pending → running → (completed | failed | timeout)`.

## §3. Dynamic Gate

검증 순서:
1. exit code 0 인지
2. stdout 에 expected pattern 있는지
3. 부속 산출물 (`.codex/<task_id>/output.json`) 존재 + 유효 JSON
4. test/build 통과 (해당 시)

FAIL 시: error message + status file `failed` 상태 + retry policy 적용.

## §4. Error Recovery

| 에러 | 원인 | 회복 |
|---|---|---|
| `timeout` | reasoning 길거나 network 느림 | `--timeout 600` 으로 재시도 (1회) |
| `auth error` | `~/.codex/auth.json` 만료 | `codex login` → 재인증 |
| `rate limit exceeded` | ChatGPT Plus 주간 quota | OpenRouter API key fallback 또는 다음 주 reset |
| `model not found` | gpt-5.5 picker 안 보임 | `npm update -g @openai/codex` |
| `network error` | 인터넷 disconnect | 대기 후 재시도 |

## §5. Team Communication

Lead (Claude Code 안 본 skill 호출 주체) ↔ Worker (Codex subprocess) ↔ DA (Codex adversarial) 패턴:

```
Lead Task → Worker (codex exec, gpt-5.5)
   ↓ output
Lead 받음 → DA (codex exec adversarial-review --scope working-tree)
   ↓ verdict (ACCEPTABLE / CONCERN / BLOCKING)
Lead 합성 → 사용자에게 보고
```

⚠️ **모든 비코딩 워커도 inference = GPT-5.5 강제** (sonnet 단독 답변 ❌). sonnet 은 orchestrator container 역할만 — codex 호출 + SUMMARY.

⚠️ **DA 동반 스폰 의무**: 워커 완료 단독으로 sign-off ❌. ACCEPTABLE / CONCERN / BLOCKING 3단계 verdict 필수.

## Hermes 환경 호환 — subprocess plugin pattern

코난 REPORT §4.3 참조. Hermes plugin 의 tool handler 안에서 Python subprocess 로 codex CLI 호출:

```python
# claude-discode/hermes-plugin/tools/codex_bridge.py
import json
import subprocess

def codex_exec(args: dict, **kwargs) -> str:
    prompt = args.get("prompt", "").strip()
    if not prompt:
        return json.dumps({"error": "prompt required"})
    try:
        result = subprocess.run(
            ["codex", "exec", "--no-stream", "--model", "gpt-5.5", prompt],
            capture_output=True, text=True, timeout=300,
        )
        return json.dumps({
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode,
        })
    except subprocess.TimeoutExpired:
        return json.dumps({"error": "timeout"})
```

Hermes 의 자체 Codex provider 와 외부 codex CLI 가 분리 auth 파일로 무충돌 공존. 자세히는 [docs/07-codex-호출-layer.md] 참조.

## 관련 자원

- vault `/Users/tofu_mac/obsidian-ai-vault/.claude/skills/codex-exec-bridge/` (6-file 원본)
- vault `/Users/tofu_mac/obsidian-ai-vault/.claude/commands/tofu-at-codex.md` (v2.2 spec)
- vault `/Users/tofu_mac/obsidian-ai-vault/.claude/agents/codex-exec-worker.md` (worker agent)
- slash command: [../../commands/codex-check.md](../../commands/codex-check.md)
- 코난 REPORT (Hermes 호환 fact base): `<vault>/020-Library/Research/2026-05-12-hermes-skill-compat/REPORT.md`
