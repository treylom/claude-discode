#!/usr/bin/env bash
# tier4.sh — Tier 4 ripgrep runner (baseline)
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

FIX="$(cd "$HERE/../fixtures" && pwd)/queries.yaml"
RESULTS=()

while IFS= read -r qid; do
  qtext=$(yq ".queries[] | select(.id == \"$qid\") | .text" "$FIX")
  expected=$(yq -o=json ".queries[] | select(.id == \"$qid\") | .expected_hits" "$FIX")

  start=$(now_ms)
  TOP=$(rg --type-add 'docs:*.{md,docx,pdf,typ}' -t docs -li -- "$qtext" "$VAULT" 2>/dev/null | head -n 5 || true)
  end=$(now_ms)
  latency=$((end - start))

  recall=$(recall_at_k "$expected" "$TOP" 5)
  RESULTS+=("$(emit_result "$qid" 4 "$latency" "$recall" 0 0 0)")
done < <(yq '.queries[].id' "$FIX")

printf '%s\n' "${RESULTS[@]}" | jq -s . > "$OUT"
echo "wrote $OUT ($(jq 'length' "$OUT") results)"
