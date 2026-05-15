# SETUP — thiscode (개발자 / 일반 사용자)

5 단계, 매 step 검증 명령 + troubleshooting 1-2 line. **초보자는 [SETUP-BEGINNER.md](SETUP-BEGINNER.md) 권장**.

## 1. Prereq (5분)

```bash
node --version          # 검증: v18.x.x 이상
jq --version            # 검증: jq-1.6+
git --version           # 검증: 2.30+
claude --version 2>/dev/null  # (선택) Claude Code CLI
```

troubleshooting: 미설치 시 https://nodejs.org / `brew install jq` / `brew install git`

## 2. Plugin install (2분)

```bash
mkdir -p ~/.claude/plugins
git clone https://github.com/treylom/ThisCode ~/.claude/plugins/thiscode
ls ~/.claude/plugins/thiscode/.claude-plugin   # 검증: 출력 있음
```

advanced (1-line installer): `curl -fsSL https://raw.githubusercontent.com/treylom/ThisCode/main/install.sh | bash`

troubleshooting: `~/.claude/plugins/` 디렉토리 없으면 `mkdir -p ~/.claude/plugins` 먼저

## 3. Tier 2 — vault-search MCP (5분, 권장)

```bash
bash ~/.claude/plugins/thiscode/scripts/install-vault-search.sh --apply
claude mcp list | grep vault-search   # 검증: vault-search 항목 출력
```

Claude Code 재시작 필요. troubleshooting: `npm install` 실패 시 `nvm use 18`

## 4. Tier 3 — obsidian-cli (3분, Obsidian 사용자만)

```bash
bash ~/.claude/plugins/thiscode/scripts/install-obsidian-cli.sh
which obsidian-cli      # 검증: path 출력
```

Obsidian 미사용 시 skip.

## 5. Tier 1 — GraphRAG (20-30분, advanced)

Python 3.10+, Docker (선택) 필요.

```bash
bash ~/.claude/plugins/thiscode/scripts/install-graphrag.sh --apply
curl localhost:8400/health   # 검증: {"status":"ok"}
```

첫 indexing 시간 ~15분 (vault 크기 의존). troubleshooting: port 8400 충돌 시 `GRAPHRAG_PORT=8401 bash scripts/...`

## 검증 (전체)

```bash
bash ~/.claude/plugins/thiscode/scripts/healthcheck.sh
```

예상 출력:

```
thiscode healthcheck v1.0
─────────────────────────────────
✓ Tier 4 (ripgrep)  : OK
✓ Tier 3 (MCP)      : OK
✓ Tier 2 (CLI)      : OK
✓ Tier 1 (GraphRAG) : OK
─────────────────────────────────
all required checks passed ✅
```

Exit code: `0` = all required OK / `1` = required FAIL / `2` = intentional SKIP only (예: Tier 1 안 깔음)

## 사용

```
/thiscode:search "your query"   # 4-Tier fallback 자동
/thiscode:km                     # KM wizard
/thiscode:setup                  # 재설정 (Tier 추가/제거)
```

## 벤치마크 (선택)

```bash
cd ~/.claude/plugins/thiscode
VAULT=./sample-vault BENCHMARK_SKIP_TIER1=1 bash benchmark/runners/run-all.sh
python3 benchmark/report-generator.py --print-only
```

자기 vault 측정: `VAULT=~/path/to/vault ...` — 단 `benchmark/fixtures/queries.yaml` 의 `expected_hits` 는 본인 vault 에 맞게 수정 필요 (자세한 건 [docs/BENCHMARK.md](BENCHMARK.md)).
