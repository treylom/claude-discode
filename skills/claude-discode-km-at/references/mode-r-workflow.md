# Mode R Workflow (5-Phase)

## R0 — Pre-clean
- Resolve merge conflicts
- Detect dead links (broken `[[wikilinks]]`)
- Quarantine legacy folders to `_archive-<date>/`

## R1 — Progressive read + analysis
- Sample 10% of target folder
- Cluster by topic + format

## R2 — Category design + DA (round 1)
- Lead proposes taxonomy
- DA challenges with 3 counter-examples
- Iterate until DA approves

## R3 — Rule-book generation + DA (round 2)
- Lead writes `<target>/.km-rules.md` (concrete rename + move rules)
- DA dry-runs on R1 sample and reports false positives
- Iterate until clean

## R4 — Python batch execute
- `km-tools.py mode-r --rules <target>/.km-rules.md --apply`
- Auto-commit each batch (avoid auto-sync conflicts)

## R5 — Verification + report
- Full vault `vault_graph` snapshot diff
- Generate `Reorganization-Report-<date>.md`
- User review gate
