#!/usr/bin/env bash
# extract-and-classify.md.sh — lite variant Mode I core (no Obsidian dependency).
# Tags handled by the skill harness; this script focuses on file write + frontmatter.
set -e

CONTENT=""; SOURCE=""; TITLE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --content) CONTENT="$2"; shift 2 ;;
    --source-url) SOURCE="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

VAULT="${CLAUDE_DISCODE_VAULT:-$HOME/obsidian-ai-vault}"
DEST="$VAULT/Inbox"
mkdir -p "$DEST"

SLUG=$(echo "$TITLE" | tr ' ' '-' | tr -cd 'A-Za-z0-9-' | head -c 40)
[ -z "$SLUG" ] && SLUG="note"
TS=$(date +%Y-%m-%d-%H%M)
FILE="$DEST/${TS}-${SLUG}.md"

{
  echo "---"
  echo "title: ${TITLE}"
  echo "source: ${SOURCE}"
  echo "captured: $(date +%Y-%m-%d)"
  echo "type: atomic"
  echo "---"
  echo ""
  printf '%b\n' "$CONTENT"
} > "$FILE"

echo "stored: $FILE"
