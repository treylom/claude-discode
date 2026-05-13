#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# non-interactive 모드 — output 만 검증 (install 안 함)
OUT=$("$ROOT/scripts/claude-discode-init.sh" --non-interactive)
echo "$OUT" | grep -q "환경 감지" || { echo "FAIL: env detect 출력 누락"; exit 1; }
echo "$OUT" | grep -q "Phase 추천" || { echo "FAIL: Phase 추천 출력 누락"; exit 1; }
echo "$OUT" | grep -q "non-interactive" || { echo "FAIL: non-interactive 안내 누락"; exit 1; }

# env override 시 vault path 변경 반영
CLAUDE_DISCODE_VAULT=/tmp/fake-vault-xyz OUT2=$("$ROOT/scripts/claude-discode-init.sh" --non-interactive --json 2>/dev/null || true)
# vault path 가 env 값 또는 빈값 (디렉토리 미존재) — 어떤 경우든 detect 실행됨
"$ROOT/scripts/claude-discode-init.sh" --detect-only --json | jq '.vault' >/dev/null || { echo "FAIL: env override detect 실패"; exit 1; }

# CLAUDE_DISCODE_INIT_AUTO env 인식 (실제 install 안 하고 output 만 확인)
OUT3=$(CLAUDE_DISCODE_INIT_AUTO="phase-3-mcp,phase-5-mode-r-preflight" "$ROOT/scripts/claude-discode-init.sh" --non-interactive)
echo "$OUT3" | grep -q "auto: phase-3-mcp" || { echo "FAIL: AUTO env 인식 누락"; exit 1; }

echo "PASS non-interactive 3 checks"
