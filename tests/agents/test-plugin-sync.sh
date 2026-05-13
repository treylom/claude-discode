#!/usr/bin/env bash
# test-plugin-sync.sh — hermes-plugin/plugin.yaml's provides_tools is subset of .agents/*.yaml provides_tools union
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v yq >/dev/null 2>&1; then
  echo "SKIP: yq not installed"
  exit 0
fi

PLUGIN_TOOLS=$(yq '.provides_tools[]' "$ROOT/hermes-plugin/plugin.yaml" | sort -u)
AGENT_TOOLS=$(yq '.provides_tools[]' "$ROOT"/.agents/*.yaml 2>/dev/null | sort -u)

FAIL=0
for t in $PLUGIN_TOOLS; do
  if ! echo "$AGENT_TOOLS" | grep -qx "$t"; then
    echo "FAIL: plugin tool $t not declared in any .agents/*.yaml"
    FAIL=1
  fi
done

# Plugin commands also subset
PLUGIN_CMDS=$(yq '.provides_commands[]' "$ROOT/hermes-plugin/plugin.yaml" | sort -u)
AGENT_CMDS=$(yq '.provides_commands[]?' "$ROOT"/.agents/*.yaml 2>/dev/null | sort -u)

for c in $PLUGIN_CMDS; do
  if ! echo "$AGENT_CMDS" | grep -qx "$c"; then
    echo "FAIL: plugin command $c not declared in any .agents/*.yaml"
    FAIL=1
  fi
done

[ "$FAIL" = "0" ] && echo "PASS plugin sync"
exit "$FAIL"
