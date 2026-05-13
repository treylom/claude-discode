#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
YAML="$ROOT/.agents/claude-discode-km-at.yaml"

yq -e '.phases.preflight.auto == true' "$YAML" >/dev/null || { echo "FAIL: phases.preflight.auto missing"; exit 1; }
yq -e '.phases.preflight.scope == "read-only"' "$YAML" >/dev/null || { echo "FAIL: read-only scope missing"; exit 1; }
yq -e '.phases.apply.dry_run_required == true' "$YAML" >/dev/null || { echo "FAIL: dry_run_required missing"; exit 1; }
yq -e '.phases.preflight.checks | contains(["broken_wikilinks"])' "$YAML" >/dev/null
yq -e '.phases.preflight.checks | contains(["folder_entropy"])' "$YAML" >/dev/null
yq -e '.phases.preflight.checks | contains(["orphan_notes"])' "$YAML" >/dev/null

echo "PASS km-at mode-r preflight yaml"
