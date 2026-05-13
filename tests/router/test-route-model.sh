#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Test 1: 단순 query → haiku
RESULT=$(node "$ROOT/scripts/route-model.mjs" --query "NuriFlow ARR")
[ "$RESULT" = "haiku" ] || { echo "FAIL: simple query expected haiku, got $RESULT"; exit 1; }

# Test 2: 중간 query → sonnet
RESULT=$(node "$ROOT/scripts/route-model.mjs" --query "Q1 보고서 핵심 3가지 요약")
[ "$RESULT" = "sonnet" ] || { echo "FAIL: medium query expected sonnet, got $RESULT"; exit 1; }

# Test 3: 종합 query → opus
RESULT=$(node "$ROOT/scripts/route-model.mjs" --query "ARR 증가와 팀 size 의 상관관계를 추론하고 다음 분기 ARR 을 예측하라")
[ "$RESULT" = "opus" ] || { echo "FAIL: complex query expected opus, got $RESULT"; exit 1; }

# Test 4: user override
RESULT=$(node "$ROOT/scripts/route-model.mjs" --query "anything" --model opus)
[ "$RESULT" = "opus" ] || { echo "FAIL: override expected opus, got $RESULT"; exit 1; }

# Test 5: GPT provider env
RESULT=$(CLAUDE_DISCODE_LLM_PROVIDER=codex node "$ROOT/scripts/route-model.mjs" --query "NuriFlow ARR")
[ "$RESULT" = "gpt-5.5" ] || { echo "FAIL: codex simple expected gpt-5.5, got $RESULT"; exit 1; }

echo "PASS route-model 5/5"
