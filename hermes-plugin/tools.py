"""Tool handlers for the thiscode Hermes plugin.

All handlers shell out to the canonical bash dispatchers vendored in ../scripts/
and ../skills/*/references/*.md.sh — so behavior stays byte-identical with the
Claude Code path and the contracts in ../contracts/.

Per Hermes convention, handlers MUST return JSON strings and MUST NOT raise.
"""

import json
import os
import shlex
import subprocess
from pathlib import Path

PLUGIN_DIR = Path(__file__).resolve().parent
REPO_ROOT = PLUGIN_DIR.parent

SEARCH_DISPATCHER = REPO_ROOT / "skills" / "search" / "references" / "tier-implementations.md.sh"
KM_LITE_CORE = REPO_ROOT / "skills" / "thiscode-km-lite" / "references" / "extract-and-classify.md.sh"
DRIFT_CHECK = REPO_ROOT / "scripts" / "km-version.sh"


def _run(cmd: list[str], env_extra: dict[str, str] | None = None, timeout: int = 30) -> dict:
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout, env=env, check=False
        )
        return {
            "ok": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode,
        }
    except subprocess.TimeoutExpired:
        return {"ok": False, "stdout": "", "stderr": f"timeout after {timeout}s", "returncode": -1}
    except FileNotFoundError as exc:
        return {"ok": False, "stdout": "", "stderr": f"missing binary: {exc}", "returncode": -2}


def handle_search(args: dict, **_kwargs) -> str:
    query = args.get("query", "").strip()
    if not query:
        return json.dumps({"error": "empty query"})
    env = {}
    if "force_tier" in args:
        env["CLAUDE_DISCODE_FORCE_TIER"] = str(args["force_tier"])
    res = _run(["bash", str(SEARCH_DISPATCHER), query], env_extra=env)
    return json.dumps({"query": query, **res})


def handle_ingest(args: dict, **_kwargs) -> str:
    cmd: list[str] = ["bash", str(KM_LITE_CORE)]
    for key in ("content", "source", "title"):
        if args.get(key):
            flag = {"content": "--content", "source": "--source-url", "title": "--title"}[key]
            cmd.extend([flag, args[key]])
    res = _run(cmd)
    return json.dumps({"variant": args.get("variant", "lite"), **res})


def session_start_drift_check(*_args, **_kwargs) -> dict:
    """Emit a drift warning to the session if thiscode contracts diverge from the vault mirror."""
    res = _run(["bash", str(DRIFT_CHECK)], timeout=5)
    if not res["ok"]:
        return {
            "context": (
                "thiscode contract drift detected — run `bash {}` for details.".format(DRIFT_CHECK)
            )
        }
    return {}


def cmd_search(args: list[str] | str, **_kwargs) -> str:
    if isinstance(args, list):
        query = " ".join(args)
    else:
        query = str(args)
    return handle_search({"query": query})


def cmd_km(args: list[str] | str, **_kwargs) -> str:
    if isinstance(args, list):
        # primitive parse: --source URL  or  --content "..."
        kv = {}
        i = 0
        while i < len(args):
            if args[i].startswith("--") and i + 1 < len(args):
                kv[args[i][2:]] = args[i + 1]
                i += 2
            else:
                i += 1
        return handle_ingest({"source": kv.get("source"), "content": kv.get("content"), "title": kv.get("title")})
    # single string fallback — treat as inline content
    return handle_ingest({"content": str(args)})
