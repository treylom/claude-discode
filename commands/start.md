---
description: claude-discode 메인 wizard — 환경 인식 + Discord 봇 셋업 + 첫 대화 검증
allowedTools: Bash, Read, Write, Edit, AskUserQuestion, Skill
---

# /claude-discode:start — 메인 wizard

> 새 머신에 Claude Code + Discord 봇 통합 환경을 처음 셋업할 때 진입점.

$ARGUMENTS

---

## 진행 흐름 (agent 가 사용자에게 안내)

### Step 1. 환경 점검 (자동, 사용자 input 0회)

```bash
uname -s                                  # → "Linux" or "Darwin"
grep -i microsoft /proc/version 2>/dev/null && echo "WSL"
command -v tmux git curl node claude     # 의존 도구 확인
```

부족한 도구 있으면 `bash install.sh` 실행 안내 (또는 `curl -fsSL https://raw.githubusercontent.com/treylom/claude-discode/main/install.sh | bash`).

### Step 2. Discord 봇 생성 안내 (사용자 수동)

브라우저로 https://discord.com/developers/applications 접속:

1. "New Application" → 이름 (예: `Karpathy-mybot`)
2. 좌측 "Bot" 탭 → "Reset Token" → 토큰 복사
3. OAuth2 → URL Generator
   - Scopes: `bot`, `applications.commands`
   - Bot Permissions: Send Messages, Read Messages, Read Message History, Add Reactions, Attach Files, Embed Links
4. 생성된 URL 로 봇을 본인 Discord 서버 또는 DM 가능 채널에 초대

### Step 3. 봇 토큰 입력 (AskUserQuestion)

봇 토큰 입력 → 다음 위치에 저장:

```bash
mkdir -p ~/.claude/channels/discord-<bot-name>
chmod 700 ~/.claude/channels/discord-<bot-name>
cat > ~/.claude/channels/discord-<bot-name>/.env <<EOF
DISCORD_BOT_TOKEN=<입력 토큰>
EOF
chmod 600 ~/.claude/channels/discord-<bot-name>/.env
```

⚠️ 토큰을 Discord 본문이나 git 에 노출 금지.

### Step 4. soul.md 페르소나 결정 (AskUserQuestion)

template 중 선택 또는 자유 작성:

| template | 어울리는 사용 |
|---|---|
| `general-assistant` | 범용 비서 (default) |
| `research-bot` | 자료조사·교차검증 (코난 스타일) |
| `writing-bot` | 글쓰기·퇴고 (글재경 스타일) |
| `schedule-bot` | 일정·Todo (스트레인지 스타일) |
| `custom` | 자유 페르소나 (사용자 직접 작성) |

선택 후 다음 위치 생성:
```
~/.claude/channels/discord-<bot-name>/soul.md
```

content 는 YAML frontmatter (`name + description + version + created + triggers`) + 강제 페르소나 규율 + 시그니처 + 팀 + Why 패턴.

### Step 5. 페어링 + 첫 대화 검증

```bash
tmux new-session -s <bot-name>
cd ~/<project> && claude
```

Discord 앱에서 봇에 DM:
```
안녕
```

봇 응답 확인 ✅ → 첫 대화 검증 완료.

---

## 검증 체크리스트

- [ ] `claude --version` ≥ 2.x
- [ ] tmux session 정상 진입
- [ ] Discord 봇 DM 수신 → 봇 응답 표시
- [ ] soul.md 페르소나 어휘가 응답에 자연 포함

---

## 다음 step

추가 봇 / 회의실 / 자가 업데이트:

- `/claude-discode:add-bot` — 추가 봇 1개 신설
- `/claude-discode:open-meeting` — 회의실 폴더 신설 (다 봇 협업)
- `/claude-discode:self-update` — 메인봇 시작 시 git pull 체크
