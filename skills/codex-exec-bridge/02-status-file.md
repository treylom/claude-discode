---
name: codex-exec-bridge/02-status-file
description: Codex Exec Bridge 상태 파일 프로토콜 — 파일 위치, atomic write 패턴, 상태 머신(pending/running/done/error/timed_out/missing_cli), 출력 파일
disable-model-invocation: true
---

# Codex Exec Bridge — Status File Protocol (§2)

> 상위 가이드: [SKILL.md](SKILL.md)

---

## Section 2: Status File Protocol

### 파일 위치

```
.team-os/codex-status/{task_id}.json          # 상태 파일 (atomic write)
.team-os/codex-status/{task_id}.stdout.txt    # 표준 출력
.team-os/codex-status/{task_id}.stderr.txt    # 표준 에러
.team-os/codex-status/{task_id}.report.json   # 최종 실행 보고서
```

### Atomic Write 패턴

pumasi-job-worker.js lines 67-71 (`atomicWriteJson`) 기반:

```javascript
// Node.js 구현
function atomicWriteJson(filePath, payload) {
  const tmpPath = `${filePath}.${process.pid}.${crypto.randomBytes(4).toString('hex')}.tmp`;
  fs.writeFileSync(tmpPath, JSON.stringify(payload, null, 2), 'utf8');
  fs.renameSync(tmpPath, filePath); // 원자적 교체 (POSIX rename 보장)
}
```

```bash
# Bash 구현 (동일한 atomic write 패턴)
write_status() {
  local file_path="$1"
  local payload="$2"
  local tmp_path="${file_path}.$$.$RANDOM.tmp"
  echo "$payload" > "$tmp_path"
  mv -f "$tmp_path" "$file_path"  # POSIX rename → atomic
}
```

**Atomic Write 원칙:**
- 임시 파일(`*.tmp`)에 먼저 쓴 후 rename
- 다른 프로세스가 부분 쓰기 중인 파일을 읽는 경쟁 조건 방지
- `mv`(rename)은 POSIX 보장으로 원자적

### 상태 머신

```
pending → running → done
                 → error
                 → timed_out
                 → canceled
                 → missing_cli
```

### 상태별 필수 필드

**pending** (실행 전):
```json
{
  "member": "codex-exec-worker",
  "state": "pending"
}
```

**running** (실행 중):
```json
{
  "member": "codex-exec-worker",
  "state": "running",
  "startedAt": "2026-03-03T10:00:00.000Z",
  "command": "codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check --ephemeral \"...\"",
  "pid": 12345
}
```

**done** (성공 완료):
```json
{
  "member": "codex-exec-worker",
  "state": "done",
  "startedAt": "2026-03-03T10:00:00.000Z",
  "finishedAt": "2026-03-03T10:02:30.000Z",
  "command": "codex exec ...",
  "exitCode": 0,
  "pid": 12345
}
```

**error** (비정상 종료):
```json
{
  "member": "codex-exec-worker",
  "state": "error",
  "message": "Process exited with code 1",
  "startedAt": "2026-03-03T10:00:00.000Z",
  "finishedAt": "2026-03-03T10:01:15.000Z",
  "command": "codex exec ...",
  "exitCode": 1,
  "pid": 12345
}
```

**timed_out** (타임아웃):
```json
{
  "member": "codex-exec-worker",
  "state": "timed_out",
  "message": "Timed out after 300s",
  "startedAt": "2026-03-03T10:00:00.000Z",
  "finishedAt": "2026-03-03T10:05:00.000Z",
  "command": "codex exec ...",
  "exitCode": null,
  "pid": 12345
}
```

**missing_cli** (codex 명령어 없음):
```json
{
  "member": "codex-exec-worker",
  "state": "missing_cli",
  "message": "ENOENT: codex command not found",
  "startedAt": "2026-03-03T10:00:00.000Z",
  "finishedAt": "2026-03-03T10:00:00.001Z",
  "command": "codex exec ...",
  "exitCode": null,
  "pid": null
}
```

### 출력 파일

```bash
# 실행 중 stdout/stderr 리디렉션
codex exec ... > ".team-os/codex-status/${task_id}.stdout.txt" \
                2> ".team-os/codex-status/${task_id}.stderr.txt"

# report.json — 실행 완료 후 작성
{
  "task_id": "task-001",
  "status": "done",           # done | error | timed_out
  "exit_code": 0,
  "started_at": "...",
  "finished_at": "...",
  "files_modified": ["src/foo.ts", "src/bar.ts"],
  "summary": "타입 에러 수정 완료"
}
```
