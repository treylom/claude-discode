#!/usr/bin/env bash
# run-all.sh — execute 4-Tier benchmark, merge into single date-stamped JSON
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
VAULT="${VAULT:-$ROOT/sample-vault}"
DATE=$(date +%Y-%m-%d)
RESULTS="$ROOT/benchmark/results"
mkdir -p "$RESULTS"

for t in 4 3 2 1; do
  VAULT="$VAULT" bash "$HERE/tier$t.sh" --output "$RESULTS/tier$t-$DATE.json" || echo "tier$t exited non-zero (continuing)"
done

# Merge into single date-stamped file
jq -n \
  --slurpfile t1 "$RESULTS/tier1-$DATE.json" \
  --slurpfile t2 "$RESULTS/tier2-$DATE.json" \
  --slurpfile t3 "$RESULTS/tier3-$DATE.json" \
  --slurpfile t4 "$RESULTS/tier4-$DATE.json" \
  --arg date "$DATE" \
  '{ date: $date, tier1: $t1[0], tier2: $t2[0], tier3: $t3[0], tier4: $t4[0] }' \
  > "$RESULTS/$DATE.json"

echo "merged: $RESULTS/$DATE.json"
