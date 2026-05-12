---
description: claude-discode 검색 환경 초기 설치 (Obsidian CLI / vault-search MCP / GraphRAG 서버)
allowedTools: Bash, AskUserQuestion, Write, Read
---

# /claude-discode:km-bootstrap

Invokes the `claude-discode-km-bootstrap` skill — detects environment, prompts for vault_root + install matrix, runs install-*.sh scripts.

Use this command when:
- 처음 설치
- `/claude-discode:search` 가 4-Tier 전부 실패 메시지 출력
- 머신 옮긴 후 환경 재구성
