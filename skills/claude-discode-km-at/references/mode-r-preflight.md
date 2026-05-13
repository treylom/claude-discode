# Mode R Preflight (read-only)

> Phase 5 (2000+ 노트 vault) 시 자동. 진단만, 이동/rename 안 함.

## checks

### broken_wikilinks

```bash
# find all [[wikilinks]] in vault, check target existence
rg -o "\[\[([^\]]+)\]\]" --no-filename "$VAULT" \
  | sort -u \
  | while read link; do
      target=$(echo "$link" | sed 's/^\[\[//;s/\]\]$//')
      # vault 안 해당 이름의 .md 가 있는지
      if ! find "$VAULT" -name "$target.md" | grep -q .; then
        echo "BROKEN: $link"
      fi
    done
```

### folder_entropy

```bash
# 폴더당 .md 갯수
find "$VAULT" -name "*.md" -exec dirname {} \; \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -20
```

### orphan_notes

```bash
# 어떤 노트에서도 link 안 된 노트 찾기
all_notes=$(find "$VAULT" -name "*.md" -exec basename {} .md \; | sort -u)
linked=$(rg -o "\[\[([^\]]+)\]\]" --no-filename "$VAULT" | sed 's/^\[\[//;s/\]\]$//' | sort -u)
comm -23 <(echo "$all_notes") <(echo "$linked")
```

## output format

`meetings/{date}-km-at-preflight-report.md` (markdown):

```markdown
---
type: km-at-preflight-report
date: {date}
vault: {vault_path}
note_count: {n}
---

# Mode R Preflight Report

## broken_wikilinks (N건)
- [[link1]] (referenced in /path/note.md)
- ...

## folder_entropy (top 20)
| count | folder |
| 50 | 020-Library/Research |
| ... | ... |

## orphan_notes (N건)
- /path/note1.md
- ...

## suggested apply (dry-run, 사용자 동의 시만)
- 이동 후보: ...
- 삭제 후보: ...
- rename 후보: ...
```

## apply (read-only X)

preflight report 사용자 검토 → 명시 동의 → `--apply` flag + `--dry-run` 의무. dry-run 결과 검증 후만 실제 적용.

```bash
# 1. preflight 만 (자동 호출됨)
/claude-discode:km --variant at --preflight

# 2. dry-run apply (보고서 본 후)
/claude-discode:km --variant at --apply --dry-run --report meetings/2026-05-13-km-at-preflight-report.md

# 3. 실제 apply (dry-run 통과 후)
/claude-discode:km --variant at --apply --report meetings/2026-05-13-km-at-preflight-report.md
```
