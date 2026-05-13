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

if ! command -v obsidian-cli >/dev/null 2>&1; then
  jq -n '{ "skipped": true, "reason": "obsidian-cli not installed" }' > "$OUT"
  echo "tier3 SKIPPED: obsidian-cli missing"
  exit 0
fi

FIX="${FIXTURE:-$(cd "$HERE/../fixtures" && pwd)/queries.yaml}"
RESULTS=()

# v2.0.1 — Mac binary (KEY=VALUE) + npm binary (POSIX flags) syntax fallback + stdin redirect
# (v1.0 잠재 bug fix: stdin consumption 으로 while loop 1회 후 break + Mac obsidian-cli syntax mismatch)
search_obsidian() {
  local qtext="$1"
  # Mac obsidian-cli (Obsidian.app 번들) — KEY=VALUE syntax
  obsidian-cli search "query=$qtext" "limit=5" "format=text" </dev/null 2>/dev/null && return 0
  # npm obsidian-cli (Yakitrak 등) — POSIX flag syntax
  obsidian-cli search --limit 5 -- "$qtext" </dev/null 2>/dev/null && return 0
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
