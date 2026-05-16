# knowledge-manager-at — STEP 2~4 상세 (팀 구성 / 스폰 / 결과 수집·RALPH·DA)

> SKILL.md 에서 분리(Skills 2.0 ≤500, progressive disclosure). 본 STEP 실행 시 Read 후 그대로 수행.

## STEP 2: 팀 구성 + 공유 메모리 초기화

### 2-1. 팀 생성

```
TeamCreate({
  team_name: "km-at-{주제키워드}",
  description: "{사용자 요청 요약} - Agent Teams 풀스케일",
  agent_type: "knowledge-manager-at-lead"
})
```

### 2-2. 공유 메모리 초기화 (계층 + Steps 포함)

```
# 세션별 파일 초기화 (MEMORY.md는 유지!)

# TEAM_PLAN.md — Steps 테이블 + Hierarchy 포함 (Agent Office 계층 그래프 렌더링용)
Write(".team-os/artifacts/TEAM_PLAN.md", """
# TEAM_PLAN

## Topic: {주제}
## Complexity: AT Full-Scale
## Team Size: 9

## Team
| # | name | role | model | Status |
|---|------|------|-------|--------|
| 1 | Lead | 총괄 오케스트레이션 (Main Lead) | opus 1M | active |
| 2 | vault-intel-lead | Vault Intelligence Category Lead | sonnet 1M | pending |
| 3 | content-proc-lead | Content Processing Category Lead | sonnet 1M | pending |
| 4 | @graph-navigator | Wikilink 그래프 탐색 | sonnet 1M | pending |
| 5 | @retrieval-specialist | 키워드+태그 검색 | sonnet 1M | pending |
| 6 | @link-curator | 양방향 링크 추천 | haiku | pending |
| 7 | @content-extractor | 소스 콘텐츠 추출 | sonnet 1M | pending |
| 8 | @deep-reader | Hub 노트 정독 + 교차 분석 | sonnet 1M | pending |
| 9 | @content-analyzer | 노트 구조 설계 + 태그 추천 | sonnet 1M | pending |
| 10 | @devils-advocate | 반론 + 교차 검증 | sonnet 1M | pending |

## Hierarchy
| parent | children |
|--------|----------|
| Lead | vault-intel-lead, content-proc-lead, @devils-advocate |
| vault-intel-lead | @graph-navigator, @retrieval-specialist, @link-curator |
| content-proc-lead | @content-extractor, @deep-reader, @content-analyzer |

## Steps
| # | Step | Assignee | Dependency | Status |
|---|------|----------|------------|--------|
| S1 | 소스 콘텐츠 추출 | @content-extractor | - | pending |
| S2 | Wikilink 그래프 탐색 | @graph-navigator | - | pending |
| S3 | 키워드+태그 넓은 검색 | @retrieval-specialist | - | pending |
| S4 | Hub 노트 정독 + 교차 분석 | @deep-reader | S2 | pending |
| S5 | 양방향 링크 후보 추천 | @link-curator | S2 | pending |
| S6 | Vault Intelligence 통합 | vault-intel-lead | S2,S3,S5 | pending |
| S7 | Content Processing 통합 | content-proc-lead | S1,S4 | pending |
| S8 | 노트 구조 설계 + 태그 추천 | @content-analyzer | S1 | pending |
| S9 | 최종 반론 + 교차 검증 | @devils-advocate | S6,S7,S8 | pending |

## Quality Targets
| Metric | Target | Measure |
|--------|--------|---------|
| Hub 노트 발견 | 최소 2개 | Graph ∩ Retrieval 교차 확인 |
| 교차 검증 핵심 노트 | 최소 3개 | 2개+ 소스에서 확인 |
| 연결 후보 | 최소 5개 | 양방향 링크 가능 |
| 원문 추출 커버리지 | 90%+ | 주요 섹션 기준 |
| 이미지 추출 (활성 시) | 주요 차트/그래프 90%+ | Image Catalog 기준 |
| RALPH SHIP 기준 | 4개 차원 모두 충족 | vault/content 기준별 |
| DA ACCEPTABLE 기준 | 워커 간 일관성 + 커버리지 누락 없음 | 종합 검토 |
""")

Write(".team-os/artifacts/TEAM_BULLETIN.md", "# TEAM_BULLETIN\n\n## Updates\n\n(팀원 발견사항이 여기에 추가됩니다)\n")
Write(".team-os/artifacts/TEAM_PROGRESS.md", """
# TEAM_PROGRESS

## Status Board

| Agent | Task | Progress | Updated | Note |
|-------|------|----------|---------|------|
| Lead | 팀 구성 중 | 5% | {timestamp} | active |
| vault-intel-lead | | 0% | {timestamp} | pending |
| content-proc-lead | | 0% | {timestamp} | pending |
| @graph-navigator | | 0% | {timestamp} | pending |
| @retrieval-specialist | | 0% | {timestamp} | pending |
| @link-curator | | 0% | {timestamp} | pending |
| @content-extractor | | 0% | {timestamp} | pending |
| @deep-reader | | 0% | {timestamp} | pending |
| @content-analyzer | | 0% | {timestamp} | pending |
| @devils-advocate | | 0% | {timestamp} | pending |

## Checkpoints

| # | Name | Condition | Done |
|---|------|-----------|------|
| 1 | All workers spawned | 모든 워커 Task 생성 완료 | [ ] |
| 2 | All workers completed | 모든 워커 결과 수신 | [ ] |
| 3 | Artifacts generated | 최종 산출물 생성 | [ ] |
""")
Write(".team-os/artifacts/TEAM_FINDINGS.md", "# TEAM_FINDINGS\n\n## Session: {주제}\n\n(교차 검증 결과가 여기에 기록됩니다)\n")

# MEMORY.md에서 이전 세션 교훈 읽기
Read(".team-os/artifacts/MEMORY.md") → 관련 Lessons Learned 확인
```

### 2-3. 태스크 생성 (TaskCreate)

```
# Category Leads
TaskCreate("vault-intel-lead: Vault Intelligence 조율 - graph/retrieval/link 워커 관리")
TaskCreate("content-proc-lead: Content Processing 조율 - extractor/reader/analyzer 워커 관리")

# Vault Intelligence Workers
TaskCreate("graph-navigator: Wikilink 2-hop 그래프 탐색 - Hub 노트 식별")
TaskCreate("retrieval-specialist: 키워드+태그 넓은 검색 - TOP 20 정리")
TaskCreate("link-curator: 양방향 링크 후보 추천", blockedBy: [graph-navigator task ID])

# Content Processing Workers
TaskCreate("content-extractor: 소스 콘텐츠 추출")
TaskCreate("deep-reader: Hub 노트 깊이 읽기 + 교차 분석")
TaskCreate("content-analyzer: 노트 구조 설계 + 태그 추천")

# Devil's Advocate
TaskCreate("devils-advocate: 최종 결과 반론 + 교차 검증")
```

### 2-4. Agent Office 능동 대시보드 연동 (CRITICAL — 실시간 Push)

**원칙: 모든 상태 전환에서 curl API push + TEAM_PROGRESS.md + TEAM_BULLETIN.md 3중 업데이트 수행.**

> 파일 watcher만으로는 15초 폴링 지연이 발생합니다.
> curl API push를 함께 사용하면 SSE로 실시간 반영됩니다.

```
IF dashboard_available:
  # 팀 생성 직후 초기 progress push (Lead: 5%, "팀 구성 중")
  Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"Lead\",\"progress\":5,\"task\":\"팀 구성 중\",\"note\":\"active\"}' --connect-timeout 2 || true")

  # TEAM_BULLETIN.md 초기 기록
  TEAM_BULLETIN.md에 Append:
    ## [{timestamp}] - Lead
    **Task**: Team created
    **Findings**: KM-AT 풀스케일 팀 ({주제}) 생성 완료. 9명 스폰 대기.
    **Status**: active

ELSE:
  # dashboard_available = false → curl 호출 생략, 파일 업데이트만 수행
  "Agent Office 미실행. 파일 기반 진행률만 기록."
```

> **진행률 갱신 규칙 (8레벨 스케일 — CRITICAL for Agent Office 실시간 반영)**:
> - 5%(created) → 10%(spawned) → 20%(first_message) → 30-70%(active, 작업 비례) → 80%(results_sent / SHIP) → 90%(DA review) → 95%(shutdown) → 100%(team_deleted)
> - Explore 워커: 10%(spawned) → 25→50→75%(active) → 80%(results_sent) → 95%(shutdown) → 100%(team_deleted)
> - Done(100%)은 TeamDelete 후에만 표시. 80-99%는 "Wrapping up"으로 표시.
> - 최소 2분마다 1회 갱신 (Agent Office 15초 폴링 + SSE로 실시간 반영)

---

## STEP 3: 팀원 스폰 (병렬!)

**반드시 하나의 메시지에서 모든 Task를 병렬로 호출하세요!**

> Spawn Prompt 로드: `.team-os/spawn-prompts/{role}.md`를 Read로 읽어서 프롬프트에 포함.
> `{{TOPIC}}`, `{{REPORT_TO}}`, `{{PREFERENCES}}` 등 변수를 실제 값으로 치환.

### 3-0. progress_update_rule 주입 확인 (CRITICAL)

각 spawn prompt에 `<progress_update_rule>` 섹션이 포함되어야 합니다.
- **general-purpose 워커** (content-extractor, content-analyzer): curl 기반 직접 push
- **Category Lead** (vault-intel-lead, content-proc-lead): curl 직접 push + Explore 워커 진행률 중계
- **Explore 워커** (graph-navigator, retrieval-specialist, link-curator, deep-reader): SendMessage 기반 보고 (Bash 불가)
- **DA** (devils-advocate): curl 기반 직접 push (아래 inline prompt에 포함)

spawn prompt 파일에 `<progress_update_rule>`이 이미 포함되어 있으므로 별도 주입 불필요.
단, 변수 치환 시 `{{REPORT_TO}}`가 정확히 치환되었는지 확인.

```
# ⚠️ 1M 컨텍스트 규칙: 모든 sonnet/opus 스폰은 model: "sonnet[1m]" / "opus[1m]" 사용. haiku만 200K.
# 9명 동시 호출 (하나의 메시지에 모든 Task 포함):

# === Category Lead: Vault Intelligence ===
Task(@vault-intel-lead):
  subagent_type: "general-purpose"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "vault-intel-lead"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/vault-intel-lead.md 내용]
    ({{REPORT_TO}} = 'Lead', {{TOPIC}} = '{주제}', {{TOPIC_KEYWORD}} = '{키워드}')

# === Category Lead: Content Processing ===
Task(@content-proc-lead):
  subagent_type: "general-purpose"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "content-proc-lead"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/content-proc-lead.md 내용]
    ({{REPORT_TO}} = 'Lead', {{TOPIC}} = '{주제}', {{SOURCE_URL}} = '{URL}', {{PREFERENCES}} = '{선호도}')

# === Vault Intelligence Workers ===
Task(@graph-navigator):
  subagent_type: "Explore"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "graph-navigator"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/graph-navigator.md 내용]
    ({{REPORT_TO}} = 'vault-intel-lead', {{TOPIC}} = '{주제}', {{TOPIC_KEYWORD}} = '{키워드}')

Task(@retrieval-specialist):
  subagent_type: "Explore"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "retrieval-specialist"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/retrieval-specialist.md 내용]
    ({{REPORT_TO}} = 'vault-intel-lead', {{TOPIC}} = '{주제}')

Task(@link-curator):
  subagent_type: "Explore"
  model: "haiku"
  team_name: "km-at-{주제키워드}"
  name: "link-curator"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/link-curator.md 내용]
    ({{REPORT_TO}} = 'vault-intel-lead', {{TOPIC}} = '{주제}', {{NEW_NOTES}} = '생성 예정 노트 목록')

# === Content Processing Workers ===
Task(@content-extractor):
  subagent_type: "general-purpose"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "content-extractor"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/content-extractor.md 내용]
    ({{REPORT_TO}} = 'content-proc-lead', {{SOURCE_URL}} = '{URL}', {{SOURCE_TYPE}} = '{type}', {{TOPIC}} = '{주제}')

Task(@deep-reader):
  subagent_type: "Explore"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "deep-reader"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/deep-reader.md 내용]
    ({{REPORT_TO}} = 'content-proc-lead', {{TOPIC}} = '{주제}', {{HUB_NOTES}} = 'graph-navigator가 식별 예정')

Task(@content-analyzer):
  subagent_type: "general-purpose"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "content-analyzer"
  run_in_background: true
  prompt: |
    [.team-os/spawn-prompts/content-analyzer.md 내용]
    ({{REPORT_TO}} = 'content-proc-lead', {{TOPIC}} = '{주제}', {{PREFERENCES}} = '{사용자선호}')

# === Devil's Advocate ===
Task(@devils-advocate):
  subagent_type: "general-purpose"
  model: "sonnet[1m]"
  team_name: "km-at-{주제키워드}"
  name: "devils-advocate"
  run_in_background: true
  prompt: |
    당신은 Devil's Advocate입니다. km-at-{주제키워드} 팀의 DA로서,
    Lead의 최종 결과에 대해 반론을 제기합니다.
    Lead가 결과를 보내면 다음을 검토하세요:
    1. 누락된 관점/정보
    2. 편향된 해석
    3. 불완전한 연결
    4. 대안적 구조 제안
    평소에는 대기합니다. Lead가 메시지를 보내면 활동합니다.

    <progress_update_rule>
    작업 시작 시:
    Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"@devils-advocate\",\"progress\":10,\"task\":\"대기 중\"}'")
    검토 시작 시: progress=30, 검토 중 50, 반론 작성 80, 완료 100
    curl 실패해도 무시.
    </progress_update_rule>
```

### 3-1. 스폰 후 초기 진행 업데이트 (대시보드 연동 — tofu-at STEP 7-4-2 패턴)

**모든 Task 스폰 직후, 대시보드에 실행 상태를 반영합니다.**

```
# 모든 Task 스폰 직후:
FOR each spawned_role in [vault-intel-lead, content-proc-lead, graph-navigator, retrieval-specialist, link-curator, content-extractor, deep-reader, content-analyzer, devils-advocate]:
  TEAM_PROGRESS.md의 해당 Agent 행 업데이트:
    Progress: 0% → 10%
    Note: pending → spawned
    Updated: {current_timestamp}

  IF dashboard_available:
    Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"{spawned_role}\",\"progress\":10,\"task\":\"초기화 중\",\"note\":\"spawned\"}' --connect-timeout 2 || true")

# Lead Progress 업데이트: 5% → 10%
TEAM_PROGRESS.md: Lead → Progress: 10%, Note: spawning complete
IF dashboard_available:
  Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"Lead\",\"progress\":10,\"task\":\"팀 스폰 완료\",\"note\":\"spawning complete\"}' --connect-timeout 2 || true")

# Checkpoint 1 업데이트:
TEAM_PROGRESS.md의 Checkpoints:
  | 1 | All workers spawned | 모든 워커 Task 생성 완료 | [x] |

# TEAM_BULLETIN.md에 Append:
  ## [{timestamp}] - Lead
  **Task**: Team spawn complete
  **Findings**: 9명 워커 스폰 완료: vault-intel-lead, content-proc-lead, graph-navigator, retrieval-specialist, link-curator, content-extractor, deep-reader, content-analyzer, devils-advocate
  **Status**: active
```

### 3-4. 사용자 알림

팀 구성 후 사용자에게 표시:

```
Knowledge Manager AT가 풀스케일 Agent Teams 모드로 실행됩니다.

| 계층 | 팀원 | 역할 | 모델 | 상태 |
|------|------|------|------|------|
| Lead | Main | 총괄 오케스트레이션 | Opus 1M | 실행 중 |
| Cat.Lead | vault-intel-lead | Vault 탐색 조율 | Sonnet 1M | 실행 중 |
| Cat.Lead | content-proc-lead | 콘텐츠 처리 조율 | Sonnet 1M | 실행 중 |
| Worker | @graph-navigator | Wikilink 그래프 탐색 | Sonnet 1M | 실행 중 |
| Worker | @retrieval-specialist | 키워드+태그 검색 | Sonnet 1M | 실행 중 |
| Worker | @content-extractor | 소스 콘텐츠 추출 | Sonnet 1M | 실행 중 |
| Worker | @deep-reader | 핵심 노트 정독 | Sonnet 1M | 실행 중 |
| Worker | @content-analyzer | 노트 구조 설계 | Sonnet 1M | 실행 중 |
| Worker | @link-curator | 연결 후보 추천 | Haiku | 대기 중 |
| DA | @devils-advocate | 결과 반론 검증 | Sonnet 1M | 대기 중 |

RALPH Loop: ON (최대 5회) | DA: ON
팀원들이 병렬 처리 중입니다. Category Lead가 결과를 통합하여 보고합니다.
```

### Phase A-G: GraphRAG 하이브리드 검색 (Dense + Sparse + Reranker)

```
VAULT_ROOT="${VAULT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DB_PATH="${VAULT_ROOT}/.team-os/graphrag/index/vault_graph.db"
INDEX_DIR="${VAULT_ROOT}/.team-os/graphrag/index"

IF DB 존재:
  1. 하이브리드 검색 (Dense Embedding + FTS5 Sparse + Reranker):
     Bash("python3 .team-os/graphrag/scripts/graph_search.py hybrid '{키워드}' --top-k 20 2>/dev/null || echo '[]'")
     → JSON 결과 파싱: results[].entity, results[].source_note, results[].score, results[].source
     → 실패 시 기존 LIKE 폴백:
       Bash("python3 -c \"import sqlite3; c=sqlite3.connect('{DB_PATH}').cursor(); [print(r) for r in c.execute(\\\"SELECT name, type, description, source_note FROM entities WHERE name LIKE '%{키워드}%' OR name_ko LIKE '%{키워드}%' LIMIT 20\\\")]\"")

  2. 관계 탐색 (1-2홉):
     발견된 엔티티의 source/target 관계 조회:
     Bash("python3 -c \"import sqlite3; c=sqlite3.connect('{DB_PATH}').cursor(); [print(r) for r in c.execute(\\\"SELECT r.type, e2.name, e2.source_note FROM relationships r JOIN entities e2 ON r.target_id=e2.id WHERE r.source_id IN (SELECT id FROM entities WHERE name LIKE '%{키워드}%') LIMIT 30\\\")]\"")

  3. 커뮤니티 연관 노트:
     엔티티가 속한 커뮤니티의 다른 멤버 조회:
     Bash("python3 -c \"import sqlite3; c=sqlite3.connect('{DB_PATH}').cursor(); [print(r) for r in c.execute(\\\"SELECT DISTINCT e2.name, e2.source_note FROM entities e1 JOIN entities e2 ON e1.community_id=e2.community_id WHERE e1.name LIKE '%{키워드}%' AND e2.name!=e1.name LIMIT 15\\\")]\"")

  4. 결과를 graphrag_results에 저장 → Phase C 교차 검증에 포함

ELSE:
  → GraphRAG DB 미존재. Phase A-G 스킵.
```

> **하이브리드 검색**: Dense Embedding(시멘틱) + FTS5(키워드) + Reranker 자동 결합.
> embedding index 미존재 시 기존 LIKE 검색으로 graceful fallback.

---

## STEP 4: 결과 수집 + RALPH + DA (대시보드 실시간 갱신 포함)

### Phase 1: Category Lead 결과 수신 (Health Check 루프 강화 — tofu-at STEP 7-5.5)

```
# Category Lead들이 워커 결과를 통합하여 SendMessage로 보고
# 대기: vault-intel-lead + content-proc-lead 모두 보고할 때까지

WHILE (미완료 Category Lead 존재):
  # TEAM_PROGRESS.md에서 각 에이전트의 마지막 업데이트 시간 확인
  FOR each active_lead in [vault-intel-lead, content-proc-lead]:
    last_update = TEAM_PROGRESS.md에서 해당 Agent의 Updated 열 파싱
    elapsed = current_time - last_update

    IF elapsed > 5분:
      # 1차: 상태 확인 메시지 전송
      SendMessage(
        recipient: "{active_lead}",
        content: "상태 확인: 마지막 업데이트로부터 5분 경과. 현재 진행 상황을 보고해주세요.",
        summary: "Health check for {active_lead}"
      )

      # 2차 (10분 경과 시): 셧다운 + 교체 판단
      IF elapsed > 10분 AND 이미 상태 확인 메시지 전송 완료:
        → SendMessage(type: "shutdown_request", recipient: "{active_lead}")
        → 새 에이전트 스폰 (같은 이름 재사용 금지! e.g., vault-intel-lead-2)
        → TEAM_BULLETIN.md에 기록: "Agent {active_lead} replaced due to inactivity"
        → TEAM_PROGRESS.md: 해당 Agent Note → "replaced (inactivity)"

  WAIT  # 메시지 자동 수신 대기
```

### Phase 2: RALPH Loop (자동, 최대 5회 — 대시보드 3중 업데이트)

```
FOR iteration IN 1..5:
  vault_intel_result = vault-intel-lead 보고서
  content_proc_result = content-proc-lead 보고서

  # 평가 기준
  vault_criteria:
    - Hub 노트 >= 2개
    - 교차 검증 핵심 노트 >= 3개
    - 연결 후보 >= 5개

  content_criteria:
    - 원문 주요 섹션 90%+ 추출
    - 교차 분석 항목 >= 3개
    - 노트 구조 제안 포함
    - 태그 추천 >= 5개

  IF vault_intel 충족:
    # === SHIP 판정: 3중 업데이트 ===
    TEAM_PROGRESS.md: vault-intel-lead → Progress: 80%, Note: SHIP (DA 리뷰 대기)
    IF dashboard_available:
      Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"vault-intel-lead\",\"progress\":80,\"task\":\"SHIP - DA 리뷰 대기\",\"note\":\"awaiting DA comprehensive review\"}' --connect-timeout 2 || true")
    TEAM_BULLETIN.md에 Append:
      ## [{timestamp}] - vault-intel-lead
      **Task**: Vault Intelligence 통합
      **Findings**: {결과 요약 1-2줄}
      **Status**: SHIP (DA 리뷰 대기)

    SendMessage(recipient: "vault-intel-lead", content: "SHIP 판정. DA 종합 리뷰 대기 중입니다.", summary: "SHIP - awaiting DA review")

  ELSE:
    # === REVISE 판정: 3중 업데이트 ===
    TEAM_PROGRESS.md: vault-intel-lead → Progress: 50%, Note: REVISE #{iteration}
    IF dashboard_available:
      Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"vault-intel-lead\",\"progress\":50,\"task\":\"REVISE\",\"note\":\"iteration #{iteration}\"}' --connect-timeout 2 || true")
    TEAM_BULLETIN.md에 Append:
      ## [{timestamp}] - Lead (RALPH)
      **Iteration**: {iteration}/5
      **Target**: vault-intel-lead
      **Feedback**: {구체적 부족 항목}
      **Status**: retry

    SendMessage({
      type: "message",
      recipient: "vault-intel-lead",
      content: "REVISE #{iteration}: {구체적 부족 항목}. 추가 탐색 요청.",
      summary: "RALPH: Vault Intel 보완 요청"
    })
    → 보완 결과 대기

  # content-proc-lead에 대해서도 동일한 SHIP/REVISE 3중 업데이트 패턴 적용
  # (위 vault-intel-lead 패턴을 content-proc-lead로 변경하여 반복)

  IF 모두 SHIP:
    BREAK → Phase 3으로
```

### Phase 3: DA 종합 리뷰 (2-Phase Review — tofu-at STEP 7-6.5 패턴)

**모든 Category Lead 결과 수집 완료 후, DA에게 전체 결과를 종합 검토하도록 요청합니다.**

```
# PRECONDITION: 모든 Category Lead 결과 수집 완료 (각 lead progress == 80%)

# Phase 3-A: DA에게 전체 결과 종합 검토 요청
all_results_summary = vault_intel_report + content_proc_report 종합 1페이지 요약
SendMessage(
  recipient: "devils-advocate",
  content: "전체 결과를 종합 검토해주세요:\n\n{all_results_summary}\n\n검토 관점:\n1. Category Lead 간 결과 일관성\n2. 전체 커버리지 누락 여부\n3. 교차 검증 불일치\n4. 종합 recommendation: ACCEPTABLE 또는 CONCERN + 재작업 대상",
  summary: "DA comprehensive review request"
)

# DA 응답 수신
da_review = DA 메시지 자동 수신
da_iteration = 0

# Phase 3-B: DA 판정 처리
IF da_review.recommendation == "ACCEPTABLE":
  # 모든 워커/리드 100%로 업데이트
  FOR each agent in [vault-intel-lead, content-proc-lead, graph-navigator, retrieval-specialist, link-curator, content-extractor, deep-reader, content-analyzer]:
    TEAM_PROGRESS.md: Progress → 100%, Note → completed (DA ACCEPTABLE)
    IF dashboard_available:
      Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"{agent}\",\"progress\":100,\"task\":\"completed\",\"note\":\"DA ACCEPTABLE\"}' --connect-timeout 2 || true")

  # Checkpoint 2 업데이트
  TEAM_PROGRESS.md: | 2 | All workers completed | 모든 워커 결과 수신 | [x] |
  → Phase 4로

ELIF da_review.recommendation == "CONCERN":
  da_iteration += 1
  rework_targets = da_review에서 재작업 필요 대상 추출

  WHILE da_iteration < 3 AND rework_targets not empty:
    FOR each rework_target in rework_targets:
      SendMessage(
        recipient: "{rework_target}",
        content: "DA 종합 리뷰 피드백:\n{da_review.feedback}\n\n수정 후 다시 결과를 보내주세요.",
        summary: "DA rework request for {rework_target}"
      )
      # 3중 업데이트 (REVISE)
      TEAM_PROGRESS.md: {rework_target} → Progress: 50%, Note: DA rework #{da_iteration}
      IF dashboard_available:
        Bash("curl -s -X POST http://localhost:3747/api/progress -H 'Content-Type: application/json' -d '{\"agent\":\"{rework_target}\",\"progress\":50,\"task\":\"DA rework\",\"note\":\"iteration #{da_iteration}\"}' --connect-timeout 2 || true")
      TEAM_BULLETIN.md에 Append:
        ## [{timestamp}] - Lead (DA CONCERN)
        **Target**: {rework_target}
        **Feedback**: {da_review.feedback 요약}
        **Status**: DA rework #{da_iteration}

    # 수정 결과 재수신
    FOR each rework_target:
      reworked_result = 메시지 자동 수신
      TEAM_PROGRESS.md: {rework_target} → Progress: 80%, Note: rework submitted

    # DA 재검토
    da_iteration += 1
    SendMessage(
      recipient: "devils-advocate",
      content: "수정된 결과를 재검토해주세요:\n{reworked_results_summary}\n\nrecommendation: ACCEPTABLE 또는 CONCERN",
      summary: "DA re-review #{da_iteration}"
    )
    da_review = DA 메시지 자동 수신

    IF da_review.recommendation == "ACCEPTABLE":
      FOR each agent:
        TEAM_PROGRESS.md: Progress → 100%, Note → completed (DA ACCEPTABLE)
        IF dashboard_available:
          Bash("curl ... progress:100 ...")
      BREAK

    rework_targets = da_review에서 재작업 필요 대상 추출

  IF da_iteration >= 3:
    → 경고: "DA 리뷰 최대 반복(3)에 도달. 현재 결과로 진행."
    FOR each agent:
      TEAM_PROGRESS.md: Progress → 100%, Note → completed (DA max iterations)

# TEAM_FINDINGS.md에 DA 결과 기록
TEAM_FINDINGS.md:
  ## DA Review
  - Recommendation: {ACCEPTABLE/CONCERN}
  - Iterations: {da_iteration}
  - Feedback: {da_review 전문}
  - Lead Decision: {판정 사유}
```

### Phase 4: 교차 검증 통합

```
# 최종 교차 검증
Graph ∩ Retrieval → 핵심 노트 (확실히 관련)
Graph only → 관계 기반 발견 (간접 연결)
Retrieval only → 고립 노트 (링크 후보)

# Checkpoint 2 업데이트 (Phase 3에서 미완료 시)
TEAM_PROGRESS.md: | 2 | All workers completed | 모든 워커 결과 수신 | [x] |

# TEAM_FINDINGS.md 최종 작성
TEAM_FINDINGS.md:
  ## Cross-Validation Summary
  | Category | Count | Notes |
  |----------|-------|-------|
  | Core (Graph ∩ Retrieval) | N | ... |
  | Graph Only | N | ... |
  | Retrieval Only | N | ... |

  ## Key Insights
  1. ...

  ## DA Review
  - Recommendation: {ACCEPTABLE/CONCERN}
  - Iterations: {da_iteration}
  - Lead Decision: ...
```

---
