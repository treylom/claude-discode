#!/usr/bin/env python3
"""
Repair GraphRAG entity search fields without LLM/API calls.

Fills:
  - entities.name_ko for rows where it is NULL/empty
  - entities.source_note for rows where it is NULL/empty and the entity matches
    a vault Markdown filename

Then rebuilds entities_fts.
"""
from __future__ import annotations

import argparse
import re
import shutil
import sqlite3
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path


_PROJECT_DIR = Path(__file__).resolve().parents[3]
DEFAULT_DB_PATH = _PROJECT_DIR / ".team-os/graphrag/index/vault_graph.db"
DEFAULT_VAULT_PATH = Path("/mnt/c/Users/treyl/Documents/Obsidian/Second_Brain")

# Exclude rule — re-export from vault_filter.py (single source of truth)
from vault_filter import EXCLUDE_DIRS, is_excluded_path

KOREAN_RE = re.compile(r"[가-힣]")
TOKEN_RE = re.compile(r"[A-Za-z0-9가-힣]+")
SPACE_RE = re.compile(r"\s+")

TOKEN_KO = {
    "agent": "에이전트",
    "agents": "에이전트",
    "automation": "자동화",
    "center": "센터",
    "cli": "CLI",
    "code": "Code",
    "codex": "Codex",
    "context": "컨텍스트",
    "data": "데이터",
    "finance": "재무",
    "graph": "그래프",
    "guide": "가이드",
    "memory": "메모리",
    "prompt": "프롬프트",
    "prompts": "프롬프트",
    "rag": "RAG",
    "research": "리서치",
    "rule": "규칙",
    "search": "검색",
    "team": "팀",
    "thread": "스레드",
    "window": "윈도우",
    "xml": "XML",
}

PHRASE_KO = {
    ("finance", "team"): "재무팀",
    ("data", "center"): "데이터센터",
    ("context", "window"): "컨텍스트 윈도우",
    ("prompt", "engineering"): "프롬프트 엔지니어링",
}


def normalize_text(value: str) -> str:
    value = value.replace(".md", "")
    value = re.sub(r"[_\\/\-]+", " ", value)
    return SPACE_RE.sub(" ", value).strip()


def match_key(value: str) -> str:
    return normalize_text(value).casefold()


def unique_append(parts: list[str], value: str | None) -> None:
    if not value:
        return
    value = SPACE_RE.sub(" ", value).strip()
    if not value:
        return
    existing = {p.casefold() for p in parts}
    if value.casefold() not in existing:
        parts.append(value)


def korean_aliases(text: str) -> list[str]:
    tokens = [m.group(0) for m in TOKEN_RE.finditer(text)]
    aliases: list[str] = []
    i = 0
    while i < len(tokens):
        lower = tokens[i].casefold()
        next_lower = tokens[i + 1].casefold() if i + 1 < len(tokens) else None
        if next_lower and (lower, next_lower) in PHRASE_KO:
            unique_append(aliases, PHRASE_KO[(lower, next_lower)])
            i += 2
            continue
        unique_append(aliases, TOKEN_KO.get(lower))
        i += 1
    return aliases


def make_name_ko(name: str, source_note: str | None) -> str:
    parts: list[str] = []
    normalized_name = normalize_text(name)
    unique_append(parts, normalized_name)

    if source_note:
        note_title = normalize_text(Path(source_note).stem)
        unique_append(parts, note_title)

    if not KOREAN_RE.search(name):
        for alias in korean_aliases(" ".join(parts)):
            unique_append(parts, alias)

    return " ".join(parts)


def iter_vault_notes(vault_path: Path) -> list[tuple[str, str, str]]:
    notes: list[tuple[str, str, str]] = []
    for md_path in vault_path.rglob("*.md"):
        rel = md_path.relative_to(vault_path)
        if is_excluded_path(rel.parts):
            continue
        rel_str = rel.as_posix()
        notes.append((rel_str, md_path.stem, match_key(md_path.stem)))
    return notes


def build_note_index(notes: list[tuple[str, str, str]]) -> dict[str, str]:
    candidates: dict[str, list[str]] = defaultdict(list)
    for rel_path, stem, stem_key in notes:
        candidates[stem_key].append(rel_path)
        candidates[match_key(rel_path[:-3])].append(rel_path)

    index: dict[str, str] = {}
    for key, paths in candidates.items():
        paths.sort(key=lambda p: (len(p), p.count("/"), p.casefold()))
        index[key] = paths[0]
    return index


def recover_source_note(name: str, note_index: dict[str, str], note_keys: list[tuple[str, str]]) -> str | None:
    key = match_key(name)
    if key in note_index:
        return note_index[key]

    basename_key = match_key(Path(name).name)
    if basename_key in note_index:
        return note_index[basename_key]

    if len(key) < 8:
        return None

    best_score = 0.0
    best_path: str | None = None
    for note_key, rel_path in note_keys:
        if abs(len(note_key) - len(key)) > max(6, len(key) // 3):
            continue
        score = SequenceMatcher(None, key, note_key).ratio()
        if score > best_score:
            best_score = score
            best_path = rel_path

    if best_score >= 0.92:
        return best_path
    return None


def repair(db_path: Path, vault_path: Path, backup: bool) -> dict[str, int]:
    if backup:
        backup_path = db_path.with_suffix(db_path.suffix + ".search_quality.bak")
        shutil.copy2(db_path, backup_path)
        print(f"Backup written: {backup_path}")

    notes = iter_vault_notes(vault_path)
    note_index = build_note_index(notes)
    note_keys = sorted(
        {(stem_key, rel_path) for rel_path, _stem, stem_key in notes},
        key=lambda item: item[0],
    )

    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    try:
        rows = con.execute(
            """
            SELECT id, name, name_ko, source_note
              FROM entities
             WHERE name_ko IS NULL
                OR TRIM(name_ko) = ''
                OR source_note IS NULL
                OR TRIM(source_note) = ''
            """
        ).fetchall()

        name_ko_filled = 0
        source_note_filled = 0

        with con:
            for row in rows:
                source_note = row["source_note"]
                updates: dict[str, str] = {}

                if not source_note or not source_note.strip():
                    recovered = recover_source_note(row["name"], note_index, note_keys)
                    if recovered:
                        source_note = recovered
                        updates["source_note"] = recovered
                        source_note_filled += 1

                if not row["name_ko"] or not row["name_ko"].strip():
                    updates["name_ko"] = make_name_ko(row["name"], source_note)
                    name_ko_filled += 1

                if updates:
                    updates["id"] = row["id"]
                    set_clause = ", ".join(f"{col} = :{col}" for col in updates if col != "id")
                    con.execute(f"UPDATE entities SET {set_clause}, updated_at = datetime('now') WHERE id = :id", updates)

            con.execute("DELETE FROM entities_fts")
            con.execute(
                """
                INSERT INTO entities_fts(entity_id, name, name_ko, description, source_note)
                SELECT id, name, name_ko, description, source_note FROM entities
                """
            )

        total, missing_name_ko, missing_source_note, fts_count = con.execute(
            """
            SELECT
                (SELECT COUNT(*) FROM entities),
                (SELECT COUNT(*) FROM entities WHERE name_ko IS NULL OR TRIM(name_ko) = ''),
                (SELECT COUNT(*) FROM entities WHERE source_note IS NULL OR TRIM(source_note) = ''),
                (SELECT COUNT(*) FROM entities_fts)
            """
        ).fetchone()

        return {
            "vault_notes": len(notes),
            "entities": total,
            "name_ko_filled": name_ko_filled,
            "source_note_filled": source_note_filled,
            "missing_name_ko": missing_name_ko,
            "missing_source_note": missing_source_note,
            "fts_rows": fts_count,
        }
    finally:
        con.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Repair GraphRAG search quality fields.")
    parser.add_argument("--db", type=Path, default=DEFAULT_DB_PATH)
    parser.add_argument("--vault", type=Path, default=DEFAULT_VAULT_PATH)
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    stats = repair(args.db, args.vault, backup=not args.no_backup)
    for key, value in stats.items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
