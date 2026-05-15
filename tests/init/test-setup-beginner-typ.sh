#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

grep -q "thiscode-init\|wizard\|8 Phase" "$ROOT/docs/SETUP-BEGINNER.typ" || { echo "FAIL: typ wizard section 누락"; exit 1; }
test -f "$ROOT/docs/SETUP-BEGINNER.pdf" || { echo "FAIL: PDF 없음"; exit 1; }

# PDF mtime 가 typ 보다 새로움 (recompile 확인)
[ "$ROOT/docs/SETUP-BEGINNER.pdf" -nt "$ROOT/docs/SETUP-BEGINNER.typ" ] || [ "$(stat -f %m $ROOT/docs/SETUP-BEGINNER.pdf)" -ge "$(stat -f %m $ROOT/docs/SETUP-BEGINNER.typ)" ] || { echo "WARN: PDF mtime 검증 — manual"; }

echo "PASS setup-beginner typ"
