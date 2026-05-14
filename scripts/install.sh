#!/usr/bin/env bash
# install.sh — claude-discode v2.3 top-level orchestrator
# 진정 zero-config: `bash install.sh --apply` 1회 → 모든 외부 dep 해결.
# 순서: superpowers (plugin) → ripgrep → obsidian-cli → graphrag → dense-embedding
# 출처 명기: claude-discode/ATTRIBUTIONS.md 참조 (15 deps).
set -euo pipefail

MODE="${1:---check}"
LOG="${HOME}/.claude-discode-setup.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OS detect — Windows native (Cygwin / MINGW / MSYS) → WSL 안내 후 종료
OS="$(uname -s)"
case "$OS" in
  CYGWIN*|MINGW*|MSYS*)
    cat <<'EOF' >&2

⚠️  Windows native (Cygwin / Git Bash / MSYS) 감지.

claude-discode v2.3 은 WSL 2 (Ubuntu 22.04+) required.
PowerShell port 는 v2.4 후속 cycle 안 평가 예정.

WSL 설치: https://docs.microsoft.com/windows/wsl/install
설치 후: wsl -d Ubuntu  →  본 install.sh 재실행.
EOF
    exit 1
    ;;
esac

usage() {
  cat <<EOF >&2
Usage: $0 [--check | --apply]
  --check    (default) 모든 sub-installer --check 모드 일괄 진단
  --apply    모든 sub-installer --apply 모드 일괄 install
             (Dense embedding 만 사용자 confirm 1회)
EOF
}

case "$MODE" in
  --check|--apply) ;;
  -h|--help)       usage; exit 0 ;;
  *)               echo "unknown arg: $MODE" >&2; usage; exit 2 ;;
esac

# redact helper — log / 출력 안 user-specific path 가림 (PII 안 안)
# $HOME 안 metacharacter escape + Windows path (WSL cross-mount) 도 cover
redact() {
  local home_esc
  home_esc=$(printf '%s\n' "${HOME:-/HOME}" | sed 's/[]\/$*.^|[]/\\&/g')
  sed -E "s|${home_esc}|/HOME|g; s|/Users/[^/]+|/Users/REDACTED|g; s|/home/[^/]+|/home/REDACTED|g; s|C:\\\\Users\\\\[^\\\\]+|C:\\\\Users\\\\REDACTED|g; s|/mnt/c/Users/[^/]+|/mnt/c/Users/REDACTED|g"
}

echo "===== claude-discode v2.3 install (mode=$MODE) =====" | tee -a "$LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] install.sh start mode=$MODE" >> "$LOG"

SCRIPTS=(install-superpowers.sh install-ripgrep.sh install-obsidian-cli.sh install-graphrag.sh install-dense-embedding.sh)
# v2.3.2: superpowers 도 optional 분류 — Claude Code CLI 미설치 환경 (CI 등) 안 graceful (codex Axis B IMPORTANT — CI policy 일치)
OPTIONAL=(install-superpowers.sh install-obsidian-cli.sh install-dense-embedding.sh)

FAILED=()
OPTIONAL_FAIL=()
for s in "${SCRIPTS[@]}"; do
  echo ""
  echo "--- Running: $s ($MODE) ---" | tee -a "$LOG"
  if bash "$SCRIPT_DIR/$s" "$MODE" 2>&1 | tee -a "$LOG"; then
    echo "✓ $s OK"
  else
    rc=$?
    is_optional=0
    for o in "${OPTIONAL[@]}"; do
      [[ "$s" == "$o" ]] && is_optional=1 && break
    done
    if [[ $is_optional -eq 1 ]]; then
      echo "○ $s optional fail (rc=$rc)" | tee -a "$LOG"
      OPTIONAL_FAIL+=("$s")
    else
      echo "✗ $s required FAIL (rc=$rc)" | tee -a "$LOG"
      FAILED+=("$s")
    fi
  fi
done

echo ""
echo "===== install summary =====" | tee -a "$LOG"
if [[ ${#FAILED[@]} -eq 0 ]]; then
  if [[ ${#OPTIONAL_FAIL[@]} -eq 0 ]]; then
    echo "✓ all installers OK (required + optional)"
  else
    echo "✓ required OK, ○ optional: ${OPTIONAL_FAIL[*]}"
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] install.sh DONE" >> "$LOG"
  echo "Next: bash $SCRIPT_DIR/healthcheck.sh"
  exit 0
else
  echo "✗ required FAIL: ${FAILED[*]}"
  echo "Log (redacted snippets):"
  tail -20 "$LOG" | redact >&2
  exit 1
fi
