---
name: codex-exec-bridge/04-error-recovery
description: Codex Exec Bridge 에러 복구 — autofix 프롬프트 템플릿, 컨텍스트 주입, 재시도 예산(max 2회), 에스컬레이션, 재시도 아카이브
disable-model-invocation: true
---

# Codex Exec Bridge — Error Recovery (§4)

> 상위 가이드: [SKILL.md](SKILL.md)

pumasi-job.js lines 946-1007 (`buildRedelegationContext`) 패턴 기반.

---

## Section 4: Error Recovery (Redelegate with Context)

### Autofix 프롬프트 템플릿

```
# 재위임 (Re-delegation)

## 이전 시도 결과
- 상태: {prev_state}
- 시도 횟수: {retry_count + 1}/{max_retries + 1}

### 게이트 결과
전체: {overall} ({passed}/{total})
  ✗ {failed_gate}: {error_first_line}

### 이전 출력 (참고)
{prev_stdout_truncated_1500chars}

## 수정 지시사항
Fix the following error: {stderr}

## 필수 규칙
- 위 게이트 실패 항목을 반드시 해결하세요
- 이전에 생성한 파일이 있다면 수정/덮어쓰기 가능합니다
- 새로운 파일을 추가하지 마세요 (지시된 파일만 수정)

---

{original_task_prompt}
```

### 컨텍스트 주입 항목

| 항목 | 출처 | 최대 길이 |
|------|------|----------|
| 게이트 결과 | `{task_id}.report.json` → gates | 전체 |
| 수정된 파일 목록 | stdout 파싱 또는 git diff | 전체 |
| 원본 제약조건 | 원래 태스크 프롬프트 | 전체 |
| 에러 stderr | `{task_id}.stderr.txt` | 1500자 truncate |
| 이전 stdout | `{task_id}.stdout.txt` | 1500자 truncate |

### 재시도 예산 (Retry Budget)

```
max_retries = 2  # 최대 2회 autofix 시도

시도 1: 원본 태스크 실행
시도 2: autofix 프롬프트 #1 (실패 시)
시도 3: autofix 프롬프트 #2 (실패 시)
→ 모두 실패: Lead에게 에스컬레이션
```

### 에스컬레이션 (모든 재시도 실패 시)

```javascript
SendMessage({
  type: "message",
  recipient: "lead",
  content: `태스크 ${task_id} autofix 실패 (${max_retries}회 시도)\n\n` +
           `실패 게이트: ${failed_gate}\n` +
           `에러:\n\`\`\`\n${stderr_truncated}\n\`\`\`\n\n` +
           `수정된 파일: ${files_modified.join(', ')}\n` +
           `상세 로그: .team-os/codex-status/${task_id}.stderr.txt`,
  summary: `bridge: task ${task_id} failed after ${max_retries} retries`
})
```

### 재시도 아카이브

각 시도 실패 시 이전 결과 보존:
```
.team-os/codex-status/
  {task_id}/
    attempt-0/          # 첫 번째 시도 아카이브
      stdout.txt
      stderr.txt
      report.json
    attempt-1/          # 두 번째 시도 아카이브
      ...
    {task_id}.json      # 현재 상태
    {task_id}.stdout.txt
    {task_id}.stderr.txt
    {task_id}.report.json
```
