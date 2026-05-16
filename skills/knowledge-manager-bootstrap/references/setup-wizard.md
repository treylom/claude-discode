# Setup Wizard Prompts (for AskUserQuestion)

## Prompt 1: vault_root
- header: vault 위치
- question: "knowledge base 가 들어갈 vault root 폴더를 선택해주세요."
- options: <auto-populated candidates> + "직접 입력"

## Prompt 2: install matrix
- header: 설치 범위
- question: "어느 Tier 까지 설치할까요? 입문 사용자는 보통 #2 부터 시작합니다."
- options:
  1. Obsidian + grep only (최소)
  2. + vault-search MCP (Tier 3 활성, 추천)
  3. + GraphRAG server (Tier 1 활성, full)
