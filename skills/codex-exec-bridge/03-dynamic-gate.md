---
name: codex-exec-bridge/03-dynamic-gate
description: Dynamic Gate 통합 — 실행 순서(tsc→build→test→lint), 게이트 결과 형식, FAIL 자동 수정 흐름, Bash 게이트 실행 함수
disable-model-invocation: true
---

# Codex Exec Bridge — Dynamic Gate Integration (§3)

> 상위 가이드: [SKILL.md](SKILL.md)
> 상세 파이프라인: `.claude/skills/dynamic-gate-verification.md`

---

## Section 3: Dynamic Gate Integration

### 실행 순서 (순차 — 앞 게이트 실패 시 중단)

```
tsc → build → test → lint
```

**각 게이트는 이전 게이트 통과 시에만 실행.**

### 게이트 결과 형식

```json
{
  "gates": [
    {
      "name": "tsc",
      "passed": true,
      "duration_ms": 1200
    },
    {
      "name": "build",
      "passed": true,
      "duration_ms": 3400
    },
    {
      "name": "test",
      "passed": false,
      "error": "2 tests failed",
      "stderr": "FAIL src/foo.test.ts\n  ● foo › should return bar\n    Expected: 'bar'\n    Received: 'baz'"
    }
  ],
  "overall": "FAIL",
  "failed_gate": "test"
}
```

**overall 값:** `"PASS"` | `"FAIL"` | `"SKIP"` (게이트 미감지 시)

### FAIL 시 자동 수정 흐름

```
게이트 FAIL 감지
  → 실패 게이트 + 에러 메시지 추출
  → autofix 프롬프트 생성 (Section 4 참조)
  → codex exec 재실행
  → 게이트 재검증
  → 최대 2회 재시도 후 Lead에게 에스컬레이션
```

### 게이트 실행 (Bash)

```bash
run_gate() {
  local gate_name="$1"
  local gate_cmd="$2"
  local start=$(date +%s%3N)

  output=$(eval "$gate_cmd" 2>&1)
  exit_code=$?
  local end=$(date +%s%3N)
  local duration=$((end - start))

  if [ $exit_code -eq 0 ]; then
    echo '{"name":"'"$gate_name"'","passed":true,"duration_ms":'"$duration"'}'
  else
    # stderr 최대 500자 truncate
    local truncated_err=$(echo "$output" | head -c 500)
    echo '{"name":"'"$gate_name"'","passed":false,"error":"'"$(echo "$truncated_err" | head -1)"'","duration_ms":'"$duration"'}'
    return 1
  fi
}
```
