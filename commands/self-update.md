---
description: claude-discode 플러그인 자가 업데이트 체크 (git fetch + behind 알림) — 메인봇 SessionStart 시 자동 호출 가능
allowedTools: Bash, Read
---

# /claude-discode:self-update — 자가 업데이트 체크

> 메인봇 시작 시 또는 수동으로 claude-discode 레포의 latest commit 과 로컬 차이를 점검.

$ARGUMENTS

---

## 진행 흐름

### Step 1. 로컬 plugin 위치 detect

```bash
# Claude Code marketplace install 시 표준 경로
PLUGIN_DIR="$HOME/.claude/plugins/marketplaces/claude-discode-marketplace"
# 또는 사용자 로컬 clone 위치
LOCAL_CLONE="$HOME/code/claude-discode"

if [ -d "$PLUGIN_DIR" ]; then
  TARGET="$PLUGIN_DIR"
elif [ -d "$LOCAL_CLONE" ]; then
  TARGET="$LOCAL_CLONE"
else
  echo "claude-discode 미설치"
  exit 1
fi
```

### Step 2. git fetch + behind 비교

```bash
cd "$TARGET"
git fetch origin --quiet
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
BEHIND=$(git rev-list --count HEAD..origin/main)
```

### Step 3. 결과 보고

```
{
  "status": "<up-to-date|behind|ahead|diverged>",
  "local": "<short-sha>",
  "remote": "<short-sha>",
  "behind_count": <N>,
  "ahead_count": <M>,
  "last_remote_commit_subject": "<subject>",
  "last_remote_commit_date": "<ISO date>"
}
```

agent 가 사용자에게 안내:
- `up-to-date`: 조용히 종료 (변화 없음)
- `behind N`: "N 개 commit 뒤처져 있어요. `/claude-discode:self-update pull` 로 업데이트 받을 수 있습니다"
- `ahead M`: 사용자가 local 수정 가지고 있음 — manual review 필요
- `diverged`: rebase 또는 reset 필요 — manual

### Step 4. (옵션) `pull` 인자 시 자동 업데이트

```bash
if [ "$ARGUMENTS" = "pull" ]; then
  cd "$TARGET"
  git pull --ff-only
  echo "업데이트 완료. 새 commit:"
  git log --oneline HEAD~"$BEHIND".."$HEAD"
fi
```

⚠️ `pull --ff-only` 사용 — diverged 일 때 안전 실패. local 수정 보존.

---

## SessionStart hook 으로 자동 호출 (선택)

`~/.claude/settings.json` 또는 `<vault>/.claude/settings.json` 의 hook 등록:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "claude -p '/claude-discode:self-update'"
          }
        ]
      }
    ]
  }
}
```

→ 매 세션 시작 시 자동 update check. behind 시만 알림.

---

## 검증

- [ ] up-to-date 상태일 때 silent 종료
- [ ] behind 상태일 때 N 개 commit 정보 정확 표시
- [ ] `pull` 인자 시 `--ff-only` 동작 (diverged 안전 실패)
- [ ] SessionStart hook 등록 시 매 세션 자동 체크
