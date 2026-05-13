#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
yq -e '.provides_tools | contains(["claude_discode_route_model"])' "$ROOT/hermes-plugin/plugin.yaml" >/dev/null
yq -e '.metadata.tier_order' "$ROOT/hermes-plugin/plugin.yaml" >/dev/null
echo "PASS plugin v2"
