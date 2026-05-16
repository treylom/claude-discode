# knowledge-manager-lite — 참조 (사용 예시 · 변종 비교 · 참조 스킬)

> SKILL.md 에서 분리(Skills 2.0 ≤500). 운영 흐름은 SKILL.md, 본 파일은 on-demand 참조.

## 참조 스킬 (상세 워크플로우)

| 기능 | 참조 스킬 |
|------|----------|
| 전체 워크플로우 | `km-workflow.md` |
| 콘텐츠 추출 | `km-content-extraction.md` |
| **YouTube 트랜스크립트** | `km-youtube-transcript.md` |
| 소셜 미디어 | `km-social-media.md` |
| 출력 형식 | `km-export-formats.md` |
| 연결 강화 | `km-link-strengthening.md` |
| 연결 감사 | `km-link-audit.md` |
| Obsidian 노트 형식 | `zettelkasten-note.md` |
| 다이어그램 | `drawio-diagram.md` |
| **이미지 파이프라인** | `km-image-pipeline.md` |
| **Mode R: 아카이브 재편** | `km-archive-reorganization.md` |

---

## /knowledge-manager-lite 와 다른 KM 변종 비교

| 변종 | 대상 | AskUserQuestion | 카카오 전송 | ntfy 알림 | 권장 환경 |
|------|------|-----------------|-----------|-----------|----------|
| `/knowledge-manager` | 개인 연구/창작 | 있음 (콘텐츠 설정 대화형) | 옵션 | 옵션 | 개인 데스크탑 대화형 |
| `/knowledge-manager-at` | Agent Teams 병렬 | 있음 | 옵션 | 있음 | 대용량 병렬 처리 |
| `/knowledge-manager-m` | 개인 모바일/카카오 | 카카오 수신자만 1회 | 필수 | 필수 | 운영자 개인 모바일 워크플로우 |
| **`/knowledge-manager-lite`** | **배포·공용 환경** | **없음** | **제거됨** | **제거됨** | **배포·최소 설정 환경** |

---

## 사용 예시

```bash
# 기본 URL 정리 (기본 프리셋: 상세, 전체균형, 3-tier, 최대)
/knowledge-manager-lite https://example.com/article

# 빠른 요약 (최소 프리셋)
/knowledge-manager-lite https://threads.net/@user/post/123 빠르게

# 상세 분석
/knowledge-manager-lite https://arxiv.org/paper 꼼꼼히

# 실용 중심 정리
/knowledge-manager-lite https://docs.example.com 실무용

# 아카이브 재편 (Mode R)
/knowledge-manager-lite Research/외부자료 아카이브 재편

# vault 종합
/knowledge-manager-lite AI-Safety 주제 종합해줘 간단히
```

## Auto-Learned Patterns

- [2026-04-12] 배포 환경에서 카카오톡/ntfy 알림과 AskUserQuestion을 제거한 경량 KM 버전 분리 — 공용 환경에서 개인 알림 설정 없이 동작 가능. 키워드 기반 자동 프리셋("빠르게/꼼꼼히/실무용")으로 대체 (source: 2026-04-12-0023)
