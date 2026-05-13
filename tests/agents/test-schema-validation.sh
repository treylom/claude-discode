#!/usr/bin/env bash
# test-schema-validation.sh — verify schema accepts valid + rejects invalid samples
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCHEMA="$ROOT/schemas/agent-spec.json"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Valid sample (Round 2/3 보강 반영: tier deprecated 추가 + evaluator field)
cat > "$TMPDIR/valid.yaml" <<'EOF'
name: test-agent
description: Test agent for schema validation
version: 1.0.0
tier: external
provides_tools: [test_tool]
allowedTools: [Bash]
gates:
  - id: latency-check
    expr: "latency_ms_p95 < 2000"
    evaluator: simple
benchmark:
  fixtures: benchmark/fixtures/queries.yaml
  axes: [latency_ms, recall_at_k]
  baseline_tier: 4
EOF

# Valid sample with deprecated tier (Round 2 보강)
cat > "$TMPDIR/valid-deprecated.yaml" <<'EOF'
name: old-agent
description: Deprecated agent (graduate inverse path)
version: 1.0.0
tier: deprecated
EOF

# Invalid: missing tier
cat > "$TMPDIR/invalid-no-tier.yaml" <<'EOF'
name: bad-agent
description: Missing tier field
version: 1.0.0
EOF

# Invalid: bad version format
cat > "$TMPDIR/invalid-version.yaml" <<'EOF'
name: bad-agent
description: Bad version format
version: 1.0
tier: external
EOF

# Invalid: unknown tier
cat > "$TMPDIR/invalid-tier.yaml" <<'EOF'
name: bad-agent
description: Unknown tier value
version: 1.0.0
tier: unknown-tier
EOF

PASS=0
FAIL=0

AJV_OPTS="--spec=draft2019 --strict=false -c ajv-formats"

for f in valid.yaml valid-deprecated.yaml; do
  if ajv validate -s "$SCHEMA" -d "$TMPDIR/$f" $AJV_OPTS >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $f should be accepted but was rejected"
    ajv validate -s "$SCHEMA" -d "$TMPDIR/$f" $AJV_OPTS 2>&1 | sed 's/^/  /'
    FAIL=$((FAIL + 1))
  fi
done

for f in invalid-no-tier.yaml invalid-version.yaml invalid-tier.yaml; do
  if ajv validate -s "$SCHEMA" -d "$TMPDIR/$f" $AJV_OPTS >/dev/null 2>&1; then
    echo "FAIL: $f should be rejected but was accepted"
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
done

echo "─────────────────────────────────"
echo "schema validation: PASS=$PASS / FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "✅ all schema tests passed" || exit 1
