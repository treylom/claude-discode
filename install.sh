#!/usr/bin/env bash
# claude-discode installer
# 환경: WSL Ubuntu / Linux native / macOS 자동 detect 후 분기
#
# 사용:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/claude-discode/main/install.sh | bash
#   또는 git clone 후 ./install.sh
#
# 8 step (Zettelkasten WSL2-tmux 가이드 기반):
#   1. 환경 detect (OS / WSL / package manager)
#   2. 필수 패키지 (tmux, git, curl, jq, build-essential)
#   3. nvm + Node.js LTS
#   4. Claude Code 전역 설치
#   5. oh-my-tmux (gpakosz/.tmux) 자동 install
#   6. (선택) claude-discode tmux.conf.local 적용
#   7. claude-discode plugin install 안내
#   8. 첫 봇 wizard 안내 (Claude Code 안 /claude-discode:start)

set -euo pipefail

# ---------------------------------------------------------------- colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { printf "${BLUE}[claude-discode]${NC} %s\n" "$*"; }
ok()   { printf "  ${GREEN}✓${NC} %s\n" "$*"; }
warn() { printf "  ${YELLOW}⚠${NC} %s\n" "$*"; }
err()  { printf "  ${RED}✗${NC} %s\n" "$*" >&2; }
step() { printf "\n${BOLD}${BLUE}━━━ Step %s/8 ━━━${NC} ${BOLD}%s${NC}\n" "$1" "$2"; }

# ---------------------------------------------------------------- globals

ENV_KIND=""    # wsl / linux / macos
PKG_MGR=""     # apt / dnf / yum / brew / pacman
REPO_DIR=""    # claude-discode 레포 루트 (curl 경로 시 추후 git clone 으로 채워짐)

# ---------------------------------------------------------------- Step 1

detect_env() {
  step 1 "환경 detect"

  local os
  os="$(uname -s)"
  case "$os" in
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        ENV_KIND="wsl"
        ok "WSL 감지 (Windows Subsystem for Linux)"
      else
        ENV_KIND="linux"
        ok "Linux native 감지"
      fi
      ;;
    Darwin)
      ENV_KIND="macos"
      ok "macOS 감지"
      ;;
    *)
      err "지원 안 함: $os (Linux / macOS / WSL 만 지원)"
      exit 1
      ;;
  esac

  if   command -v apt-get >/dev/null 2>&1; then PKG_MGR="apt"
  elif command -v dnf     >/dev/null 2>&1; then PKG_MGR="dnf"
  elif command -v yum     >/dev/null 2>&1; then PKG_MGR="yum"
  elif command -v brew    >/dev/null 2>&1; then PKG_MGR="brew"
  elif command -v pacman  >/dev/null 2>&1; then PKG_MGR="pacman"
  else
    err "패키지 매니저 못 찾음 (apt / dnf / yum / brew / pacman 중 하나 필요)"
    exit 1
  fi
  ok "패키지 매니저: $PKG_MGR"
}

# ---------------------------------------------------------------- Step 2

install_base_packages() {
  step 2 "필수 패키지 (tmux + git + curl + jq + build tools)"

  case "$PKG_MGR" in
    apt)
      sudo apt-get update -qq
      sudo apt-get install -y -qq tmux git curl jq build-essential
      ;;
    dnf)
      sudo dnf install -y -q tmux git curl jq gcc make
      ;;
    yum)
      sudo yum install -y -q tmux git curl jq gcc make
      ;;
    brew)
      brew list tmux >/dev/null 2>&1 || brew install tmux
      brew list git  >/dev/null 2>&1 || brew install git
      brew list curl >/dev/null 2>&1 || brew install curl
      brew list jq   >/dev/null 2>&1 || brew install jq
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed tmux git curl jq base-devel
      ;;
  esac

  ok "tmux: $(tmux -V)"
  ok "git: $(git --version | head -1)"
}

# ---------------------------------------------------------------- Step 3

install_node() {
  step 3 "nvm + Node.js LTS"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js 이미 설치됨: $(node --version) → skip"
    return
  fi

  if [ ! -d "$HOME/.nvm" ]; then
    log "nvm 설치 (v0.40.1)"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  else
    ok "nvm 이미 설치됨"
  fi

  # 현재 셸에서 nvm 활성화
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  log "Node.js LTS 설치"
  nvm install --lts
  nvm use --lts

  ok "Node.js: $(node --version)"
  warn "새 터미널을 열어야 nvm/node 가 PATH 에 영구 잡힙니다"
}

# ---------------------------------------------------------------- Step 4

install_claude_code() {
  step 4 "Claude Code (Anthropic 공식 CLI)"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code 이미 설치됨: $(claude --version) → skip"
    return
  fi

  # nvm 활성화 (Step 3 와 같은 셸에서 호출됐다고 가정)
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  npm install -g @anthropic-ai/claude-code

  ok "Claude Code: $(claude --version)"
  warn "다음 단계 가기 전, 다른 터미널에서 'claude auth login' 으로 브라우저 인증해주세요"
}

# ---------------------------------------------------------------- Step 5

install_oh_my_tmux() {
  step 5 "oh-my-tmux (gpakosz/.tmux)"

  if [ -d "$HOME/.tmux" ] && [ -L "$HOME/.tmux.conf" ]; then
    ok "oh-my-tmux 이미 설치됨 (~/.tmux + ~/.tmux.conf symlink) → skip"
    return
  fi

  cd "$HOME"

  if [ ! -d "$HOME/.tmux" ]; then
    git clone --single-branch https://github.com/gpakosz/.tmux.git
  fi

  ln -s -f .tmux/.tmux.conf .tmux.conf

  if [ ! -f "$HOME/.tmux.conf.local" ]; then
    cp .tmux/.tmux.conf.local .
    ok "~/.tmux.conf.local 신규 생성 (user override 파일)"
  else
    ok "~/.tmux.conf.local 기존 보존"
  fi

  ok "oh-my-tmux 설치 완료"
  warn "tmux 환경변수 TERM 은 xterm-256color 여야 합니다 (echo \$TERM 확인)"
}

# ---------------------------------------------------------------- Step 6

apply_our_tmux_conf() {
  step 6 "claude-discode tmux.conf.local 적용 (선택)"

  local src="$REPO_DIR/configs/tmux.conf.local"

  if [ -z "$REPO_DIR" ] || [ ! -f "$src" ]; then
    warn "claude-discode 레포가 로컬에 없음 → 본 step skip (Step 7 의 git clone 이후 다시 실행 가능)"
    return
  fi

  printf "\n  claude-discode 의 tmux.conf.local 을 사용하시겠어요? (y/N) "
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if [ -f "$HOME/.tmux.conf.local" ]; then
      cp "$HOME/.tmux.conf.local" "$HOME/.tmux.conf.local.bak"
      ok "기존 파일 백업: ~/.tmux.conf.local.bak"
    fi
    cp "$src" "$HOME/.tmux.conf.local"
    ok "claude-discode 의 tmux.conf.local 적용 완료"
  else
    ok "user override 유지 (~/.tmux.conf.local)"
  fi
}

# ---------------------------------------------------------------- Step 7

install_plugin() {
  step 7 "claude-discode plugin install 안내"

  cat <<'EOF'

  Claude Code 안에서 다음 한 줄 실행:

      /plugin marketplace add <owner>/claude-discode-marketplace
      /plugin install claude-discode@claude-discode-marketplace

  또는 로컬 git clone 으로:

      git clone https://github.com/<owner>/claude-discode.git ~/.claude/plugins/cache/local/claude-discode

  install 후 Claude Code 안에서 plugin 자동 인식.

EOF
  warn "marketplace URL 은 GitHub 공개 레포 신설 후 채워집니다 (현 staging 단계)"
}

# ---------------------------------------------------------------- Step 8

print_next_steps() {
  step 8 "첫 봇 wizard 안내"

  cat <<'EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║  설치 완료 — 다음 단계                                          ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                                ║
  ║  1. 새 tmux session 시작                                       ║
  ║       tmux new-session -s claude                              ║
  ║                                                                ║
  ║  2. claude 실행                                                ║
  ║       cd ~/<project> && claude                                ║
  ║                                                                ║
  ║  3. Claude Code 안에서 wizard 시동                             ║
  ║       /claude-discode:start                                   ║
  ║                                                                ║
  ║     wizard 가 단계별로 안내합니다                                ║
  ║       - Discord 봇 생성 (Developer Portal)                     ║
  ║       - 봇 토큰 입력                                            ║
  ║       - 첫 봇 페르소나 결정 (soul.md template)                 ║
  ║       - 페어링 + 첫 대화 검증                                    ║
  ║                                                                ║
  ║  4. 막히면 README.md 의 트러블슈팅 섹션 참조                     ║
  ║                                                                ║
  ╚══════════════════════════════════════════════════════════════╝

EOF
}

# ---------------------------------------------------------------- main

main() {
  # REPO_DIR 추정: 본 스크립트 위치
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi

  log "claude-discode 설치 시작"
  log "환경 자동 detect 진행"

  detect_env
  install_base_packages
  install_node
  install_claude_code
  install_codex_cli              # Step 4.5
  install_oh_my_tmux
  apply_our_tmux_conf
  install_obsidian_cli           # NEW Step 6.5
  install_plugin
  print_next_steps

  log "claude-discode 설치 종료"
}

# ---------------------------------------------------------------- Step 6.5 (NEW)

install_obsidian_cli() {
  step "6.5" "Obsidian CLI (vault 접근 3-Tier 폴백 1순위)"

  if command -v obsidian >/dev/null 2>&1; then
    ok "Obsidian CLI 이미 설치됨: $(obsidian --version 2>&1 | head -1) → skip"
    return
  fi

  case "$ENV_KIND" in
    macos)
      log "Obsidian app 설치 시도 (brew cask)"
      brew install --cask obsidian || warn "brew cask 실패 — https://obsidian.md/download 에서 수동 설치"
      ;;
    wsl)
      warn "WSL 환경 — Windows native Obsidian 호출 권장:"
      cat <<'EOF'

  1. Windows 에서 https://obsidian.md/download → Obsidian Installer 다운로드 + 실행
  2. WSL alias 등록:
       alias obsidian="'/mnt/c/Program Files/Obsidian/Obsidian.com'"
       # 또는 ~/.bashrc 에 추가
  3. WSL 안 vault 경로:
       VAULT="/mnt/c/Users/<windows-user>/Documents/Obsidian/<vault-name>"

  자세히는 docs/04-obsidian-cli.md 참조.

EOF
      ;;
    linux)
      log "Linux 환경 — 3 옵션 안내"
      cat <<'EOF'

  Option A — Snap (Ubuntu 권장):
       sudo snap install obsidian --classic

  Option B — Flatpak:
       flatpak install flathub md.obsidian.Obsidian

  Option C — AppImage / deb:
       https://obsidian.md/download → 다운로드 후 수동 설치

EOF
      ;;
  esac

  # 검증
  if command -v obsidian >/dev/null 2>&1; then
    ok "Obsidian CLI: $(obsidian --version 2>&1 | head -1)"
  else
    warn "Obsidian CLI 설치 안 됨 — 3-Tier 폴백의 Tier 2 (MCP) 또는 Tier 3 (Write/Read/Grep) 으로 작동"
    warn "Obsidian 사용 안 하시면 본 단계 skip OK — claude-discode 대부분 작동"
  fi

  # vault 경로 설정 안내
  log "Obsidian vault 경로 환경변수 권장 (~/.bashrc 또는 ~/.zshrc 에 추가):"
  echo "  export OBSIDIAN_VAULT=\"\$HOME/Documents/<vault-name>\""
  echo "  # WSL: export OBSIDIAN_VAULT=\"/mnt/c/Users/<user>/Documents/Obsidian/<vault-name>\""
  echo ""
}

# ---------------------------------------------------------------- Step 4.5 (NEW)

install_codex_cli() {
  step "4.5" "Codex CLI (Codex 호출 layer 의존)"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex CLI 이미 설치됨: $(codex --version 2>&1 | head -1) → skip"
    return
  fi

  # nvm 활성화 (Step 3 에서)
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  npm install -g @openai/codex

  ok "Codex CLI: $(codex --version 2>&1 | head -1)"
  warn "다음 단계로 가기 전, 다른 터미널에서 'codex login' 으로 OAuth 인증해주세요"
  warn "Claude Code 안 install 후 /claude-discode:codex-check 슬래시로 검증 가능"
}

main "$@"
