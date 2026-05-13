#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/README.md"

# vault-first 표현
grep -q "Quickstart\|8 Phase\|claude-discode:init\|claude-discode init" "$F" || { echo "FAIL: init 진입점 안내 누락"; exit 1; }

# Discord/tmux secondary section
grep -qE "## (선택|Discord|tmux|Agent Teams)" "$F" || { echo "FAIL: Discord 영역 secondary section 누락"; exit 1; }

# Phase progressive 안내
grep -q "Phase" "$F" | head -5

echo "PASS readme vault-first"
