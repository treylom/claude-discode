#!/usr/bin/env bash
# tier1.sh — Tier 1 GraphRAG FastAPI runner (skip via env or server-down)
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

GRAPHRAG_URL="${GRAPHRAG_URL:-http://localhost:8400}"

# CI escape hatch — set env to skip in GitHub Actions (Round 3 CC2 outcome)
if [ "${BENCHMARK_SKIP_TIER1:-0}" = "1" ]; then
  jq -n '{ "skipped": true, "reason": "BENCHMARK_SKIP_TIER1=1 (CI mode — measured separately via biweekly Docker job)" }' > "$OUT"
  echo "tier1 SKIPPED (env)"
  exit 0
fi

if ! curl -fsS "$GRAPHRAG_URL/health" >/dev/null 2>&1; then
  jq -n --arg url "$GRAPHRAG_URL" '{ "skipped": true, "reason": ("GraphRAG server not reachable at " + $url + " — start via scripts/install-graphrag.sh --apply") }' > "$OUT"
  echo "tier1 SKIPPED: server down at $GRAPHRAG_URL"
  exit 0
fi

FIX="${FIXTURE:-$(cd "$HERE/../fixtures" && pwd)/queries.yaml}"
RESULTS=()

# v1.0.1 fix: GraphRAG server endpoint is GET /api/search (not POST /query).
# Response schema: { query, results: [{path, ...}], total, source, search_type }.
# cost_tokens / kg_depth not provided by server — emit 0 with note in benchmark/results JSON.
while IFS= read -r qid; do
  qtext=$(yq ".queries[] | select(.id == \"$qid\") | .text" "$FIX")
  expected=$(yq -o=json ".queries[] | select(.id == \"$qid\") | .expected_hits" "$FIX")

  # URL-encode query string
  encoded_q=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$qtext")

  start=$(now_ms)
  RESP=$(curl -fsS "$GRAPHRAG_URL/api/search?q=$encoded_q&top_k=5" 2>/dev/null || echo '{"results":[]}')
  end=$(now_ms)
  latency=$((end - start))

  # Try .path first, then .file, then .source — schema variations
  TOP=$(echo "$RESP" | jq -r '.results[]? | (.path // .file // .source // empty)' | head -n 5)
  tokens=$(echo "$RESP" | jq -r '.usage.total_tokens // 0')
  kg_avg=$(echo "$RESP" | jq -r '.kg.depth_avg // 0')
  recall=$(recall_at_k "$expected" "$TOP" 5)

  RESULTS+=("$(emit_result "$qid" 1 "$latency" "$recall" "$tokens" 25 "$kg_avg")")
done < <(yq '.queries[].id' "$FIX")

printf '%s\n' "${RESULTS[@]}" | jq -s . > "$OUT"
echo "wrote $OUT ($(jq 'length' "$OUT") results)"
