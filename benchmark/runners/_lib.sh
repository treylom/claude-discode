#!/usr/bin/env bash
# Shared helpers for per-Tier benchmark runners

now_ms() {
  if command -v gdate >/dev/null 2>&1; then
    echo $(($(gdate +%s%N) / 1000000))
  else
    python3 -c "import time; print(int(time.time()*1000))"
  fi
}

# recall_at_k <expected_hits_json_array> <top_k_paths_newline> <k>
recall_at_k() {
  local expected="$1" top="$2" k="${3:-5}"
  local hit=0 total
  total=$(echo "$expected" | jq 'length')
  if [ "$total" = "0" ] || [ -z "$top" ]; then
    echo "0"
    return
  fi
  while IFS= read -r ex; do
    [ -z "$ex" ] && continue
    if echo "$top" | head -n "$k" | grep -qF "$ex"; then
      hit=$((hit + 1))
    fi
  done < <(echo "$expected" | jq -r '.[]')
  python3 -c "print(round($hit / $total, 3))"
}

# Emit a JSON result object for one query
emit_result() {
  local qid="$1" tier="$2" lat="$3" recall="$4" cost="$5" setup="$6" kg="$7"
  jq -nc \
    --arg qid "$qid" --argjson tier "$tier" --argjson lat "$lat" \
    --argjson recall "$recall" --argjson cost "$cost" \
    --argjson setup "$setup" --argjson kg "$kg" \
    '{query_id:$qid,tier:$tier,latency_ms:$lat,recall_at_5:$recall,cost_tokens:$cost,setup_time_min:$setup,kg_depth:$kg}'
}
