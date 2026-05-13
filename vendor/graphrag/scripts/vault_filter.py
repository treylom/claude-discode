"""Vault file filter — central exclude rule for archive/duplicate dirs.

Single source of truth for `vault.rglob("*.md")` filtering across the
GraphRAG ingest pipeline. Edit `EXCLUDE_DIRS` / `EXCLUDE_PREFIXES` here
to change actual ingest behavior in every script.

Why centralized:
- bootstrap.py / entity_extractor.py / embedding_index.py /
  frontmatter_sync.py / incremental.py / repair_search_quality.py all
  walked the vault separately; some had drift (frontmatter_sync,
  incremental had no exclude rule at all). Drift caused archive
  duplicates in the entity index.
- 2026-05-03 vault path duplicate cleanup cycle — see
  `feedback_vault_path_normalization.md` for the full incident.
"""
from __future__ import annotations

from pathlib import Path
from typing import Iterable

# Exact directory names to exclude (any depth)
EXCLUDE_DIRS = {
    "obsidian-ai-vault",        # outer git source root, rsync target
    ".obsidian",                # Obsidian app config
    ".trash",
    ".tmp.drivedownload",
    ".tmp.driveupload",
    "AI_Second_Brain",          # nested duplicate vault copy
    "Second_Brain",             # nested duplicate vault copy
}

# Directory name prefixes to exclude (e.g. "_archive-2026-04",
# "_archive_per_session_20260412_002123", "_attachments")
EXCLUDE_PREFIXES = (
    "_archive",
    "_attachments",
)


def is_excluded_path(rel_parts: Iterable[str]) -> bool:
    """True if any path part matches an exclude rule (set or prefix)."""
    for part in rel_parts:
        if part in EXCLUDE_DIRS:
            return True
        if any(part.startswith(prefix) for prefix in EXCLUDE_PREFIXES):
            return True
    return False


def filter_md_files(md_files: Iterable[Path], vault: Path) -> list[Path]:
    """Filter list of .md Path objects, excluding archive/duplicate dirs."""
    out: list[Path] = []
    for f in md_files:
        try:
            rel = f.relative_to(vault)
        except ValueError:
            continue
        if not is_excluded_path(rel.parts):
            out.append(f)
    return out


def walk_vault_md(vault: Path) -> list[Path]:
    """Walk vault for .md files with exclude rule applied. Most common entry point."""
    return filter_md_files(vault.rglob("*.md"), vault)
