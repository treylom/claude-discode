#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
find "$ROOT/build" -name '*.typ' -print0 | sort -z | while IFS= read -r -d '' src; do
  typst compile --root "$ROOT" "$src" "${src%.typ}.pdf"
done
