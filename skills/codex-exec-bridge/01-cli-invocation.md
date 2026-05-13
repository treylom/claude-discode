---
name: codex-exec-bridge/01-cli-invocation
description: Codex CLI 기본 호출 형식, reasoning effort 레벨, 플래그 설명, --output-schema 옵션, 타임아웃 처리, 작업 디렉토리
disable-model-invocation: true
---

# Codex Exec Bridge — CLI Invocation (§1)

> 상위 가이드: [SKILL.md](SKILL.md)

---

## Section 1: Codex CLI Invocation Specification

### 기본 호출 형식

```bash
codex exec \
  --model gpt-5.4 \
  -c 'model_reasoning_effort="{REASONING_EFFORT:-high}"' \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  --ephemeral \
  "{prompt}"
```

### Reasoning Effort 레벨

| 레벨 | 값 | 용도 |
|------|---|------|
| low | 1024 토큰 상당 | 사소한 수정 |
| medium | 8192 토큰 상당 | 단순 작업 |
| **high** (기본값) | 16384 토큰 상당 | 대부분의 코딩 작업 |
| xhigh | 31999 토큰 상당 | 복잡한 아키텍처, DA 검토 |

Lead가 SendMessage로 `reasoning_effort` 파라미터를 전달하면 해당 값 사용.
미전달 시 기본값 `high`.

### 플래그 설명

| 플래그 | 역할 | 필요 이유 |
|--------|------|----------|
| `--dangerously-bypass-approvals-and-sandbox` | 파일 읽기/쓰기/명령 실행 승인 프롬프트 비활성화 | Agent Teams 자동화 환경에서 인터랙티브 승인 불가 |
| `--skip-git-repo-check` | git 저장소 여부 검사 생략 | 임시 디렉토리나 비-git 환경에서도 실행 가능 |
| `--ephemeral` | 세션 상태 비저장 (이전 대화 컨텍스트 없음) | 각 태스크를 독립된 실행으로 격리, 상태 누적 방지 |

### --output-schema 옵션 (구조화 JSON 출력)

구조화된 결과가 필요한 경우 (분석, 리포트 생성 태스크 등):

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  --ephemeral \
  --output-schema '{"type":"object","properties":{"status":{"type":"string"},"files_modified":{"type":"array","items":{"type":"string"}},"summary":{"type":"string"}},"required":["status","summary"]}' \
  "{prompt}"
```

**사용 기준:**
- 태스크 프롬프트에 "JSON으로 결과 반환", "구조화 출력" 지시가 있을 때
- gate result를 파싱해야 할 때
- 팀 리드에게 파일 목록 + 요약을 정형화하여 전달해야 할 때
- 자유형 코딩/수정 태스크에는 사용 금지 (출력 형식 강제로 인한 품질 저하)

### 타임아웃 처리

pumasi-job-worker.js lines 273-278 패턴 기반:

```javascript
// 타임아웃 설정 (기본 300초)
const timeoutSec = options.timeout || 300;

if (Number.isFinite(timeoutSec) && timeoutSec > 0) {
  timeoutHandle = setTimeout(() => {
    timeoutTriggered = true;
    try { process.kill(child.pid, 'SIGTERM'); } catch { /* ignore */ }
  }, timeoutSec * 1000);
  timeoutHandle.unref(); // Node.js 이벤트 루프 블로킹 방지
}
```

**Bash 환경에서 타임아웃 적용:**

```bash
# timeout 명령어로 SIGTERM 전송
timeout --signal=SIGTERM 300 \
  codex exec --model gpt-5.4 -c 'model_reasoning_effort="high"' \
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check --ephemeral "{prompt}"

# 종료 코드 확인
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
  echo "TIMED_OUT: 300s 초과"
  STATE="timed_out"
elif [ $EXIT_CODE -eq 0 ]; then
  STATE="done"
else
  STATE="error"
fi
```

**타임아웃 상태 분류:**
- 종료 코드 124 + SIGTERM → `timed_out`
- SIGTERM (타임아웃 아님) → `canceled`
- 코드 0 → `done`
- 기타 비정상 종료 → `error`

### 작업 디렉토리

항상 프로젝트 루트를 작업 디렉토리로 사용:

```bash
# cwd는 항상 프로젝트 루트
codex exec ... "{prompt}" 2>&1
# 또는 명시적으로
cd /path/to/project && codex exec ...
```
