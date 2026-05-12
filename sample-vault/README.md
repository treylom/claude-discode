# NuriFlow Systems Sample Vault

This sample vault models NuriFlow Systems / 누리플로우 시스템즈, a Seoul B2B SaaS company with 186 employees, USD 28.4M ARR, HQ Seoul plus Singapore and Austin, and products FlowDesk, DocuLens AI, InsightBridge, LaunchOps, and Marketplace Preview.

## Typst Workflow

Install Typst, then compile all generated sources:

```bash
brew install typst
sample-vault/scripts/build-typst-vault.sh
```

PDFs live in `sample-vault/build/<doc-id>/` beside their `.typ` sources. All generated PDFs in this vault are compiled from Typst sources. `design/common.typ` defines Korean typography with Pretendard and Noto Sans CJK KR at the front of the fallback list, `lang: "ko"`, `par(leading: 0.65em)`, A4 pages, and code block monospace fallbacks.

## Search Checks

The vault intentionally repeats these research anchors across formats: 회사 미션, Q1 2026 매출, 신제품 출시, HR 정책. The dates are distributed from 2025-05-13 through 2026-05-13.
