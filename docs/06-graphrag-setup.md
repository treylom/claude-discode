---
title: GraphRAG 수동 설치 가이드
order: 6
---

# GraphRAG 서버 (Tier 1) 수동 설치

자동 설치 (`install-graphrag.sh --apply`)가 실패하면 본 가이드 따라 수동 진행.

## 요구 환경

- Python 3.11+ (venv 지원)
- 4GB+ RAM
- vault root (Obsidian 사용 가정. 없으면 `--vault-dir <path>` 옵션)

## 단계

1. vault 안 `.team-os/graphrag/` 폴더 신설 (또는 git clone 으로 가져옴)
2. `python3 -m venv .venv`
3. `.venv/bin/pip install -r requirements.txt`
4. `bash scripts/install-graphrag.sh --apply` — vendor(`vendor/graphrag/scripts/`)에서 인덱스 빌드 + `search_server` 기동(자동)

## 검증

```bash
curl http://127.0.0.1:8400/health
# 응답: {"status":"ok","index_version":"..."}
```

## 문제 해결

- 8400 포트 충돌: `GRAPHRAG_PORT=8401 bash scripts/install-graphrag.sh --apply` 후 `search` 설정에서 endpoint 변경
- Index build 실패: `--vault-dir` 명시 + frontmatter 검증 (`type:` 누락 노트 점검)
