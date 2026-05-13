# ATTRIBUTIONS

claude-discode v2.3 가 의존하는 모든 외부 패키지 / repo 의 출처 / license / version pin.

> 본 매트릭스 = spec doc `docs/superpowers/specs/2026-05-13-claude-discode-v2.3-dependency-packaging-design.md` §5 동등.
> license cross-compatibility = MIT + Apache 2.0 + BSD-3 + Unlicense 모두 permissive, copyleft (GPL/LGPL) zero — cross-compatible.

## Plugin (1)

| Name | Source | License | Version | Install method |
|------|--------|---------|---------|----------------|
| superpowers | github.com/anthropics/claude-plugins-official | MIT | 5.1.0 | Claude Code plugin manager (`claude plugin install superpowers`) |

## Spec doc (2 — vendored 본문)

| Name | Source | License | Version | Vendored at |
|------|--------|---------|---------|-------------|
| agentskills | github.com/agentskills-io/agent-skills-in-action | Apache 2.0 | 2026-04-22 (Manning book) | `vendor/agentskills/SKILL-SPEC.md` |
| hermes-agent | github.com/NousResearch/hermes-agent | MIT | latest (2026-05-13) | `vendor/hermes/HERMES-SPEC.md` |

## External tools — required (5)

| Name | Source | License | Install method |
|------|--------|---------|----------------|
| ripgrep | github.com/BurntSushi/ripgrep | Unlicense + MIT dual | `install-ripgrep.sh` (brew / apt / dnf / apk) |
| networkx | github.com/networkx/networkx | BSD-3 | `install-graphrag.sh` (pip) |
| python-louvain | github.com/taynaud/python-louvain | BSD-3 | `install-graphrag.sh` (pip) |
| pyyaml | github.com/yaml/pyyaml | MIT | `install-graphrag.sh` (pip) |
| fastapi | github.com/tiangolo/fastapi | MIT | `install-graphrag.sh` (pip) |

## External tools — required (2 — v0.2 audit 추가)

| Name | Source | License | Install method |
|------|--------|---------|----------------|
| uvicorn | github.com/encode/uvicorn | BSD-3 | `install-graphrag.sh` (pip) |
| numpy | github.com/numpy/numpy | BSD-3 | `install-graphrag.sh` (pip, embedding_index.py 의존) |
| httpx | github.com/encode/httpx | BSD-3 | `install-graphrag.sh` (pip, graph_search.py 의존) |

## External tools — optional GUI guide (1)

| Name | Source | License | Install method |
|------|--------|---------|----------------|
| Obsidian CLI | obsidian.md (3-binary detect) | Obsidian proprietary GUI | `install-obsidian-cli.sh` (브라우저 download 안내, WSL = Windows side install) |

## Optional Dense channel (3 — 사용자 confirm 1회)

| Name | Source | License | Install method |
|------|--------|---------|----------------|
| torch | github.com/pytorch/pytorch | BSD-3 | `install-dense-embedding.sh` (pip, ~600MB) |
| transformers | github.com/huggingface/transformers | Apache 2.0 | `install-dense-embedding.sh` (pip, ~500MB) |
| sentence-transformers | github.com/UKPLab/sentence-transformers | Apache 2.0 | `install-dense-embedding.sh` (pip) |

## Vendored Python runtime (claude-discode/vendor/graphrag/)

GraphRAG core 21 file (`.py` 18 + `.sh` 2 + `requirements.txt` 1) = obsidian-ai-vault `.team-os/graphrag/scripts/` 와 동등 vendor 박제.

- 출처: github.com/treylom/obsidian-ai-vault `.team-os/graphrag/scripts/` (private vault, 2026-05-13 snapshot)
- License: claude-discode 본 repo license 와 동등 (treylom own)
- Update 정책: pin version (vault SoT 변경 시 manual sync, v2.4 cycle 안 변경)

## claude-discode 본 repo

- 본 repo license: claude-discode/LICENSE 참조
- Maintainer: treylom

## License compatibility 검증 (Phase 1 GPT-5.5)

본 매트릭스 license set:
- MIT (superpowers, hermes-agent, pyyaml, fastapi)
- Apache 2.0 (agentskills, transformers, sentence-transformers)
- BSD-3 (networkx, python-louvain, uvicorn, numpy, httpx, torch)
- Unlicense + MIT (ripgrep)
- Obsidian proprietary GUI (안내만 — vendor 없음)

**cross-compatibility:** MIT + Apache 2.0 + BSD-3 + Unlicense 모두 permissive license. copyleft (GPL / LGPL) zero. claude-discode 본 license (MIT 추정) 와 호환.

---

본 매트릭스 변경 시: spec doc §5 동시 update. CI smoke test 안 `pip install -r vendor/graphrag/scripts/requirements.txt` 자동 검증.
