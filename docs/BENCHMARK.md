# 5-axis Benchmark — claude-discode 4-Tier Search

본 benchmark 는 claude-discode 의 4-Tier search 가 `obsidian-cli` 단독 / Claude `/search` / vault-search MCP 단독 대비 어떤 trade-off 를 보이는지 5 차원으로 측정합니다.

## ⚠ 본인 vault 측정이 정공법

`benchmark/fixtures/queries.yaml` 의 20 query 는 **데모용 sample fixture** (가상의 NuriFlow Systems 회사 시나리오) 입니다. 본인 vault 에서 의미 있는 수치를 보려면 본인 fixture 작성이 권장됩니다:

```bash
# 1. fixture template 복사
cp benchmark/fixtures/queries.yaml benchmark/fixtures/my-vault.yaml

# 2. my-vault.yaml 의 expected_hits 를 본인 vault 의 실제 path 로 수정
#    (예: "40-Reports" → "Library/Reports" 등)

# 3. 본인 vault 로 측정
FIXTURE=$(pwd)/benchmark/fixtures/my-vault.yaml VAULT=~/your-vault bash benchmark/runners/run-all.sh

# 4. 결과 확인 (README 표 inject 안 함 — 본인 vault 수치는 personal)
python3 benchmark/report-generator.py --print-only
```

## GraphRAG (Tier 1) 본인 vault 사용

Tier 1 GraphRAG 가 본인 vault 를 인덱싱해야 의미 있는 recall + kg_depth 측정 가능. claude-discode 의 `scripts/install-graphrag.sh` 는 본인 vault 인덱싱 + 서버 띄움까지 자동화 (CLAUDE_DISCODE_VAULT env 또는 `--vault` flag).

```bash
CLAUDE_DISCODE_VAULT=~/your-vault \
  bash scripts/install-graphrag.sh --apply
```

별도 포트 (예: 8401) 사용 시 `GRAPHRAG_PORT=8401` env + `GRAPHRAG_URL=http://localhost:8401` env (benchmark/runners/tier1.sh 가 받음).

## 5 Axes

### 1. `latency_ms` — 응답 시간 (P50, milliseconds)

각 query 에 대한 응답 시간. 3회 반복 후 P50. 빠를수록 좋음.

| Tier | 기대 범위 | 이유 |
|---|---|---|
| 4 (ripgrep) | 30-100 ms | local file scan, no network |
| 3 (obsidian-cli) | 200-500 ms | local index lookup |
| 2 (vault-search MCP) | 500-1000 ms | MCP 호출 + embedding lookup |
| 1 (GraphRAG) | 1500-3000 ms | LLM call + graph traversal |

### 2. `recall_at_5` — top-5 결과의 expected_hit 비율

20 queries 각각의 `expected_hits` (ground truth) 가 top-5 에 들어있는 비율. 높을수록 좋음.

기대 범위:
- ripgrep (Tier 4): 0.3-0.5 (literal string 만)
- obsidian-cli (Tier 3): 0.5-0.7 (light fuzzy)
- vault-search MCP (Tier 2): 0.6-0.8 (embedding)
- GraphRAG (Tier 1): 0.8-0.95 (semantic + graph)

**Ground truth 큐레이션 (Round 2 outcome)**: query 작성자 (1차) + 외부 LLM evaluator (2차, Opus + Sonnet cross-check) + 사용자 spot-check 5개 (3차).

### 3. `cost_tokens` — LLM 호출 token + context 합산

LLM 사용 시점만 발생. ripgrep/CLI = 0, MCP/GraphRAG > 0.

**Tokenizer 고정 (Round 2 outcome)**: OpenAI `tiktoken` 으로 통일 측정. 정확도 ±15%. 표 footnote 에 tokenizer 명시.

### 4. `setup_time_min` — 설치 + 첫 indexing 까지 시간 (학생 self-report cohort 평균)

| Tier | 기본 | 도구 |
|---|---|---|
| 4 | 0 min | (기본 시스템) |
| 3 | ~5 min | obsidian-cli 설치 |
| 2 | ~10 min | npm install + MCP config |
| 1 | ~25 min | Python/Docker + embedding generation |

**측정 (Round 2 outcome)**: GitHub Actions 자동 측정 불가 — cohort metric. 강의 수강생 self-report N=30 평균 + GitHub Discussions Feedback category (Round 3 CC3). bias 인정, "self-reported" footnote.

### 5. `kg_depth` — knowledge graph 결과 노드의 평균 graph depth

Tier 1 (GraphRAG) 만 의미. 다른 Tier = 0.

값의 의미:
- 0 = 단일 노드 (no graph)
- 1-2 = 표면 traversal (1-2 hop)
- 3+ = 깊은 connectivity (multi-hop 추론)

**3 metric 저장, 표는 avg only (Round 2 outcome)**: JSON 결과는 `{ kg_depth: { avg, max, edge_count } }` 3개 raw 보존. README 표는 `kg_depth.avg` 만.

## 측정 방법

```bash
# 전체 4 Tier 실행
bash benchmark/runners/run-all.sh

# 특정 Tier 만
VAULT=./sample-vault bash benchmark/runners/tier4.sh --output /tmp/t4.json

# README 표 자동 갱신
python3 benchmark/report-generator.py

# 표만 출력 (README 수정 X)
python3 benchmark/report-generator.py --print-only
```

## 자기 vault 로 재실행

`sample-vault/` 대신 본인 vault 사용:

```bash
VAULT=~/Documents/Obsidian/MyVault bash benchmark/runners/run-all.sh
```

주의:
- `benchmark/fixtures/queries.yaml` 의 `expected_hits` 가 sample-vault 기준 — 자기 vault 로 측정 시 fixture 수정 필요
- 자기 fixture 작성: `cp benchmark/fixtures/queries.yaml benchmark/fixtures/my-queries.yaml` 후 수정

## CI 운영 (Round 3 CC2 outcome)

| Workflow | trigger | 행동 |
|---|---|---|
| `validate-agents.yml` | PR | `.agents/*.yaml` schema + index + plugin sync 검증 (PR required) |
| `benchmark.yml` | main push | Tier 4 measured, Tier 1/2/3 skip (Docker GraphRAG biweekly cron 별도) — 결과 PR 자동 생성, **auto-merge ❌** (사람 리뷰 강제) |
| `benchmark-tier1.yml` | biweekly schedule | Docker GraphRAG full run ($1-2/month CI 비용) |
| Mac Mini fallback | weekly cron | Tier 1 GitHub Actions 다운 시 보조 측정 |

**Tier 1 stale > 14 days 처리**: README badge `tier1-stale` 자동 표시 (별도 workflow).

## 해석 가이드

수치 본 후 학생이 묻는 질문 + 답:

- **"왜 GraphRAG 가 느린가요?"** → LLM 호출 + graph traversal 때문. 단 recall + kg_depth 우위
- **"ripgrep 만으로 충분?"** → literal 검색은 OK. 단 "ARR 증가 추세" 같은 semantic query 는 recall < 0.3
- **"Tier 3 vs Tier 2 차이는?"** → Tier 2 (MCP) 는 embedding 으로 fuzzy match. Tier 3 (CLI) 는 light index, 빠르지만 semantic 약함
- **"kg_depth = 0 은 왜?"** → Tier 2/3/4 는 graph 가 없음. Tier 1 만 의미
- **"내 vault 에서 직접 측정?"** → `VAULT=~/path bash benchmark/runners/run-all.sh` (fixture 수정 필요)

## v1.0 → v1.1 graduate trigger (Round 3 outcome)

`benchmark/results/*.json` 3주 (≈21일) 연속 다음 중 1개 발생 시 v1.1 PR 자동 생성:

1. 어떤 metric 이든 ±20% 이상 drift
2. 강의 수강생 feedback (GitHub Discussions) "재현 성공률 ⚠️/❌" 3건 이상
3. `tier1-stale > 14 days` badge 14일 이상 지속
