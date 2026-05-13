---
name: codex-exec-bridge/05-team-communication
description: Agent Teams 통신 프로토콜 — SendMessage(완료/에러), progress curl 업데이트, TaskUpdate(completed/in_progress), 전체 실행 흐름 요약
disable-model-invocation: true
---

# Codex Exec Bridge — Agent Teams Communication (§5)

> 상위 가이드: [SKILL.md](SKILL.md)

---

## Section 5: Agent Teams Communication

### 결과 보고 (SendMessage)

태스크 완료 시 Lead에게 메시지 전송:

```javascript
SendMessage({
  type: "message",
  recipient: "lead",
  content: "Task completed. Files modified: [src/foo.ts, src/bar.ts]. Gate results: tsc PASS, build PASS, test PASS, lint PASS.",
  summary: "bridge-agent-dev: task done"
})
```

**에러 시:**

```javascript
SendMessage({
  type: "message",
  recipient: "lead",
  content: "Task failed after 2 retries. Failed gate: test. Error: 2 tests failed in src/foo.test.ts. Full log: .team-os/codex-status/{task_id}.stderr.txt",
  summary: "bridge-agent-dev: task failed"
})
```

### 진행 상황 업데이트 (progress_update_rule)

```bash
# 진행 중 주기적 업데이트
curl -s -X POST http://localhost:3747/api/progress \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d "{\"agent\":\"codex-exec-worker\",\"progress\":${progress},\"task\":\"${task_id}\",\"note\":\"${note}\"}" \
  --connect-timeout 2 || true

# 진행 단계별 progress 값
# 0%:  태스크 수신
# 10%: codex exec 시작
# 50%: codex exec 완료, 게이트 검증 중
# 80%: 게이트 통과, 보고서 작성 중
# 100%: 완료
```

### TaskUpdate — 태스크 완료/실패 마킹

```javascript
// 성공 시
TaskUpdate({
  taskId: task_id,
  status: "completed"
})

// 실패 시 (에스컬레이션 후)
TaskUpdate({
  taskId: task_id,
  status: "in_progress"  // Lead가 처리할 수 있도록 in_progress 유지
})
```

### 전체 실행 흐름 요약

```
1. 태스크 수신 (SendMessage from lead)
2. progress 0% 업데이트
3. pending 상태 파일 작성 (atomic write)
4. codex exec 실행 (timeout 300s)
5. running 상태 파일 업데이트
6. progress 50% 업데이트
7. Dynamic Gate 실행 (tsc → build → test → lint)
8. PASS: report.json 작성 → SendMessage(lead, done) → TaskUpdate(completed)
9. FAIL: autofix 프롬프트 생성 → codex exec 재실행 (최대 2회)
10. 모든 재시도 실패: SendMessage(lead, escalation) → progress 100%
```
