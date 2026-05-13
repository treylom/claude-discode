#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
grep -q "note_count" "$ROOT/scripts/install-vault-search.sh" || { echo "FAIL: note_count check missing"; exit 1; }
grep -q "100" "$ROOT/scripts/install-vault-search.sh" || { echo "FAIL: 100 threshold missing"; exit 1; }
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
bash "$ROOT/scripts/install-vault-search.sh" --recommend-only VAULT="$TMP" 2>&1 | grep -qE "warn|note_count" || { echo "FAIL: empty vault warn missing"; exit 1; }
echo "PASS vault-search note count"
