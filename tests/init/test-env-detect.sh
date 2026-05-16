#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# env detect 단독 모드 — JSON 출력 검증
OUT=$("$ROOT/scripts/claude-discode-init.sh" --detect-only --json)

# 필수 키 9개
for k in os vault.path vault.note_count tools.obsidian_cli tools.python tools.docker tools.ripgrep resources.ram_gb resources.disk_free_gb; do
  echo "$OUT" | jq -e ".$k != null" >/dev/null || { echo "FAIL: $k missing"; exit 1; }
done

echo "PASS env detect (9 keys)"
