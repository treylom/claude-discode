#!/bin/bash
set -e

F=$HOME/code/ThisCode/docs/MANUAL.typ
LINES=$(wc -l < "$F")
[ "$LINES" -lt 400 ] || { echo "FAIL: MANUAL.typ too long ($LINES lines, target < 400)"; exit 1; }

# v2.0 핵심 sections 7 개
for s in "thiscode" "설치" "4-Tier" "Knowledge Manager" "LLM 모델 routing" "Benchmark" "FAQ"; do
  grep -q "$s" "$F" || { echo "FAIL: missing section $s"; exit 1; }
done

test -f $HOME/code/ThisCode/docs/MANUAL.pdf || { echo "FAIL: PDF not regenerated"; exit 1; }
echo "PASS MANUAL v2"
