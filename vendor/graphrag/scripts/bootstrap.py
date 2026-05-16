"""
bootstrap.py — Initial graph population from cortex.db or vault scan
Python 3.12 compatible

Strategy:
1. cortex.db exists → import existing graph data
2. cortex.db missing → scan vault for wikilinks + tags (rule-based)
"""
from __future__ import annotations

import json
import re
import sqlite3
from pathlib import Path
from typing import Any

from graphrag_core import (
    get_connection,
    close_connection,
    compute_content_hash,
    compute_frontmatter_hash,
    validate_db_path,
)

try:
    import yaml
except ImportError:
    raise ImportError("pyyaml not installed. Run: pip install 'pyyaml>=6.0'")

_PROJECT_DIR = Path(__file__).resolve().parents[3]
_DEFAULT_DB = str(_PROJECT_DIR / ".team-os/graphrag/index/vault_graph.db")

_FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n?", re.DOTALL)


def _parse_frontmatter(content: str) -> tuple[dict, str]:
    m = _FM_RE.match(content)
    if not m:
        return {}, content
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError:
        fm = {}
    return fm, content[m.end():]


# ---------------------------------------------------------------------------
# Bootstrap from cortex.db
# ---------------------------------------------------------------------------

def bootstrap_from_cortex(
    cortex_db: str | Path,
    target_conn: sqlite3.Connection,
) -> dict[str, int]:
    """
    Import entities and relationships from an existing cortex.db.
    Cortex schema assumed: nodes(id, name, type, ...), edges(id, source, target, type, ...)
    Falls back gracefully if schema differs.
    """
    cortex_path = Path(cortex_db)
    if not cortex_path.exists():
        raise FileNotFoundError(f"cortex.db not found: {cortex_path}")

    stats = {"entities": 0, "relationships": 0, "errors": 0}

    try:
        src = sqlite3.connect(str(cortex_path))
        src.row_factory = sqlite3.Row

        # Try to detect schema
        tables = {
            row[0]
            for row in src.execute("SELECT name FROM sqlite_master WHERE type='table'")
        }

        # --- Import entities/nodes ---
        if "nodes" in tables:
            for row in src.execute("SELECT * FROM nodes"):
                d = dict(row)
                target_conn.execute(
                    """INSERT INTO entities (id, name, name_ko, type, description, source_note)
                       VALUES (:id, :name, :name_ko, :type, :description, :source_note)
                       ON CONFLICT(id) DO NOTHING""",
                    {
                        "id": d.get("id", ""),
                        "name": d.get("name", ""),
                        "name_ko": d.get("name_ko"),
                        "type": d.get("type", "concept"),
                        "description": d.get("description"),
                        "source_note": d.get("source_note") or d.get("note_path"),
                    },
                )
                stats["entities"] += 1

        elif "entities" in tables:
            for row in src.execute("SELECT * FROM entities"):
                d = dict(row)
                target_conn.execute(
                    """INSERT INTO entities (id, name, name_ko, type, description, source_note)
                       VALUES (:id, :name, :name_ko, :type, :description, :source_note)
                       ON CONFLICT(id) DO NOTHING""",
                    {
                        "id": d.get("id", ""),
                        "name": d.get("name", ""),
                        "name_ko": d.get("name_ko"),
                        "type": d.get("type", "concept"),
                        "description": d.get("description"),
                        "source_note": d.get("source_note"),
                    },
                )
                stats["entities"] += 1

        # --- Import relationships/edges ---
        edge_table = "edges" if "edges" in tables else ("relationships" if "relationships" in tables else None)
        if edge_table:
            for row in src.execute(f"SELECT * FROM {edge_table}"):
                d = dict(row)
                target_conn.execute(
                    """INSERT INTO relationships
                       (id, source_id, target_id, type, strength, evidence_text, source_note)
                       VALUES (:id, :source_id, :target_id, :type, :strength, :evidence_text, :source_note)
                       ON CONFLICT(id) DO NOTHING""",
                    {
                        "id": d.get("id", ""),
                        "source_id": d.get("source_id") or d.get("source", ""),
                        "target_id": d.get("target_id") or d.get("target", ""),
                        "type": d.get("type", "related_to"),
                        "strength": d.get("strength", 1.0),
                        "evidence_text": d.get("evidence_text"),
                        "source_note": d.get("source_note"),
                    },
                )
                stats["relationships"] += 1

        target_conn.commit()
        src.close()

    except Exception as e:
        stats["errors"] += 1
        try:
            src.close()
        except Exception:
            pass
        raise RuntimeError(f"cortex.db import failed: {e}") from e

    return stats


# ---------------------------------------------------------------------------
# Bootstrap from vault (fallback)
# ---------------------------------------------------------------------------

def bootstrap_from_vault(
    vault_path: str | Path,
    target_conn: sqlite3.Connection,
    batch_size: int = 100,
) -> dict[str, int]:
    """
    Scan all .md files in vault, extract entities + relationships via rule-based parsing.
    Uses entity_extractor for wikilink + tag parsing.
    """
    from entity_extractor import extract_entities_from_note, save_to_db, set_note_path_cache

    vault = Path(vault_path)
    stats = {"notes": 0, "entities": 0, "relationships": 0, "errors": 0}

    # Exclude rule — single source of truth in vault_filter.py
    # (covers symlinked/duplicate dirs, Obsidian internals, _archive*, _attachments)
    from vault_filter import walk_vault_md
    print("Scanning vault for .md files (NTFS — may take 1-2 min)...")
    md_files = walk_vault_md(vault)
    print(f"Found {len(md_files)} notes. Pre-building wikilink cache...")
    # Share file list with entity_extractor to avoid a second NTFS scan
    set_note_path_cache(md_files)
    print(f"Cache ready ({len(md_files)} stems). Starting extraction...")

    for i, md_file in enumerate(md_files):
        rel_path = str(md_file.relative_to(vault))
        try:
            content = md_file.read_text(encoding="utf-8")
            fm, body = _parse_frontmatter(content)

            content_hash = compute_content_hash(body, fm)
            fm_hash = compute_frontmatter_hash(fm)

            entities, relationships, reified = extract_entities_from_note(rel_path, content, use_llm=False)
            save_to_db(target_conn, entities, relationships, rel_path, reified)

            target_conn.execute(
                """INSERT OR REPLACE INTO note_graph_state
                   (note_path, content_hash, frontmatter_hash, graph_synced)
                   VALUES (?, ?, ?, 0)""",
                (rel_path, content_hash, fm_hash),
            )

            stats["notes"] += 1
            stats["entities"] += len(entities)
            stats["relationships"] += len(relationships)

            if (i + 1) % batch_size == 0:
                target_conn.commit()
                print(f"  Progress: {i + 1}/{len(md_files)} notes processed...")

        except Exception as e:
            stats["errors"] += 1
            try:
                target_conn.execute(
                    "INSERT INTO sync_log (operation, note_path, status, source) VALUES ('bootstrap', ?, 'error', ?)",
                    (rel_path, str(e)),
                )
            except Exception:
                pass

    target_conn.commit()
    return stats


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def main(
    vault_path: str = "<vault>",
    db_path: str = _DEFAULT_DB,
    cortex_db: str | None = None,
) -> None:
    """
    Bootstrap GraphRAG index:
    1. Try cortex.db import if available
    2. Fall back to vault scan
    """
    import sys

    conn = get_connection(db_path)

    # Check existing data
    existing = conn.execute("SELECT COUNT(*) FROM entities").fetchone()[0]
    if existing > 0:
        print(f"DB already has {existing} entities. Use --force to re-bootstrap.")
        close_connection(conn)
        return

    # Try cortex.db
    cortex_path = Path(cortex_db) if cortex_db else Path(db_path).parent / ".cortex.db"
    if cortex_path.exists():
        print(f"Importing from cortex.db: {cortex_path}")
        try:
            stats = bootstrap_from_cortex(cortex_path, conn)
            print(f"Cortex import: entities={stats['entities']}, "
                  f"relationships={stats['relationships']}, errors={stats['errors']}")
        except Exception as e:
            print(f"Cortex import failed ({e}), falling back to vault scan...", file=sys.stderr)
            stats = bootstrap_from_vault(vault_path, conn)
            print(f"Vault scan: notes={stats['notes']}, entities={stats['entities']}, "
                  f"relationships={stats['relationships']}, errors={stats['errors']}")
    else:
        print(f"No cortex.db found at {cortex_path}. Running vault scan...")
        stats = bootstrap_from_vault(vault_path, conn)
        print(f"Vault scan complete: notes={stats['notes']}, entities={stats['entities']}, "
              f"relationships={stats['relationships']}, errors={stats['errors']}")

    close_connection(conn)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Bootstrap GraphRAG index from cortex.db or vault scan")
    parser.add_argument("--db", default=_DEFAULT_DB)
    parser.add_argument("--vault", default="<vault>")
    parser.add_argument("--cortex", default=None, help="Path to cortex.db (auto-detected if not specified)")
    parser.add_argument("--force", action="store_true", help="Re-bootstrap even if DB has data")
    args = parser.parse_args()

    if args.force:
        conn = get_connection(args.db)
        conn.execute("DELETE FROM entities")
        conn.execute("DELETE FROM relationships")
        conn.execute("DELETE FROM note_graph_state")
        conn.commit()
        close_connection(conn)
        print("DB cleared for forced re-bootstrap.")

    main(vault_path=args.vault, db_path=args.db, cortex_db=args.cortex)
