---
contract: km-variant-matrix
version: 0.1.0
date: 2026-05-13
---

# KM Variant Responsibility Matrix

| Variant | Mode I | Mode R | Mode G | Python deps | Agent Teams | Default for |
|---|---|---|---|---|---|---|
| **lite** | ✓ | ✗ (notice) | ✓ read-only | None | No | Phase 1·2 강의 학생 |
| **at** | ✓ | ✓ | ✓ full | km-tools.py + jq | Yes (Category Lead + RALPH + DA) | Phase 3 심화 |
| **plain** | ✓ | ✗ | ✗ | None | No | fallback (no AskUserQuestion env) |

## Decision rules

- Headless environment ($CLAUDE_DISCODE_HEADLESS=1) → force `plain`.
- User did not specify variant + interactive → `lite` (Phase 1·2 default).
- User explicit `/thiscode:km --variant at` → `at` (after env check for jq+km-tools).
- Mode R requested + variant ≠ at → suggest `--variant at` + abort.
