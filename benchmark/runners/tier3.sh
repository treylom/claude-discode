#!/usr/bin/env bash
# tier3.sh — Tier 3 obsidian-cli runner (skip if CLI missing)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/_lib.sh"

VAULT="${VAULT:?VAULT env required}"
OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output) OUT="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$OUT" ] || { echo "FAIL: --output required"; exit 1; }

# v2.0.2 — 3 binary 중 하나 있으면 OK (obsidian-cli / obsidian / notesmd-cli)
if ! command -v obsidian-cli >/dev/null 2>&1 \
  && ! command -v obsidian >/dev/null 2>&1 \
  && ! command -v notesmd-cli >/dev/null 2>&1; then
  jq -n '{ "skipped": true, "reason": "Obsidian CLI not installed (obsidian-cli / obsidian / notesmd-cli)" }' > "$OUT"
  echo "tier3 SKIPPED: Obsidian CLI missing (3 binary 중 하나 필요)"
  exit 0
fi

FIX="${FIXTURE:-$(cd "$HERE/../fixtures" && pwd)/queries.yaml}"
RESULTS=()

# v2.0.2 — binary 이름 detection (codex xhigh review verdict: NEEDS_PATCH_v2.0.2)
# 공식 Obsidian CLI (Obsidian.app 번들, /opt/homebrew/bin/obsidian-cli symlink) = KEY=VALUE syntax
# Yakitrak/notesmd-cli (별도 binary 이름) = search-content + --no-interactive --format json
# (v1.0 잠재 bug fix: stdin consumption + Mac obsidian-cli syntax mismatch + Yakitrak binary 이름 정정)
search_obsidian() {
  local qtext="$1"
  # 1순위: 공식 Obsidian CLI — obsidian-cli (homebrew symlink) 또는 obsidian (PATH 직접)
  if command -v obsidian-cli >/dev/null 2>&1; then
    obsidian-cli search "query=$qtext" "limit=5" "format=text" </dev/null 2>/dev/null && return 0
  fi
  if command -v obsidian >/dev/null 2>&1; then
    obsidian search "query=$qtext" "limit=5" "format=text" </dev/null 2>/dev/null && return 0
  fi
  # 2순위: Yakitrak/notesmd-cli — search-content 형식 (https://github.com/Yakitrak/notesmd-cli)
  if command -v notesmd-cli >/dev/null 2>&1; then
    notesmd-cli search-content "$qtext" --no-interactive --format json </dev/null 2>/dev/null && return 0
  fi
  return 1
}

# yq output 을 임시 파일에 capture — while loop 안 obsidian-cli stdin consumption 차단
QIDS_TMP="$(mktemp)"
trap 'rm -f "$QIDS_TMP"' EXIT
yq '.queries[].id' "$FIX" > "$QIDS_TMP"

while IFS= read -r qid; do
  qtext=$(yq ".queries[] | select(.id == \"$qid\") | .text" "$FIX")
  expected=$(yq -o=json ".queries[] | select(.id == \"$qid\") | .expected_hits" "$FIX")

  start=$(now_ms)
  TOP=$(search_obsidian "$qtext" | head -n 5 || true)
  end=$(now_ms)
  latency=$((end - start))
  recall=$(recall_at_k "$expected" "$TOP" 5)

  RESULTS+=("$(emit_result "$qid" 3 "$latency" "$recall" 0 5 0)")
done < "$QIDS_TMP"

printf '%s\n' "${RESULTS[@]}" | jq -s . > "$OUT"
echo "wrote $OUT ($(jq 'length' "$OUT") results)"
