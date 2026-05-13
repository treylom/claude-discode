#!/usr/bin/env python3
"""report-generator.py — read latest benchmark JSON, build 5-axis table, inject README.md.

Round 2/3 outcome:
- kg_depth: 3 metric saved (avg/max/edge_count); README shows depth_avg only.
- README markers: <!-- BENCHMARK-TABLE-START --> ... <!-- BENCHMARK-TABLE-END -->
"""
import json
import sys
import argparse
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
RESULTS_DIR = ROOT / "benchmark" / "results"
README = ROOT / "README.md"

TIER_LABEL = {1: "GraphRAG", 2: "Obsidian CLI", 3: "vault-search MCP", 4: "ripgrep"}


def latest_json() -> Path:
    files = sorted(p for p in RESULTS_DIR.glob("????-??-??.json"))
    if not files:
        sys.exit("no benchmark results found in benchmark/results/ — run benchmark/runners/run-all.sh first")
    return files[-1]


def percentile(values, p):
    if not values:
        return 0
    s = sorted(values)
    k = int(len(s) * p)
    k = min(max(k, 0), len(s) - 1)
    return s[k]


def aggregate(tier_results):
    if not tier_results or (isinstance(tier_results, dict) and tier_results.get("skipped")):
        reason = tier_results.get("reason", "skipped") if isinstance(tier_results, dict) else "no data"
        return {
            "latency_p50": "—",
            "recall_at_5": "—",
            "cost_tokens": "—",
            "setup_time_min": "—",
            "kg_depth": "—",
            "note": f"SKIPPED ({reason[:40]})",
        }
    rows = tier_results
    if not rows:
        return {k: "—" for k in ("latency_p50", "recall_at_5", "cost_tokens", "setup_time_min", "kg_depth")} | {"note": "empty"}

    return {
        "latency_p50": percentile([r["latency_ms"] for r in rows], 0.5),
        "recall_at_5": round(sum(r["recall_at_5"] for r in rows) / len(rows), 3),
        "cost_tokens": round(sum(r["cost_tokens"] for r in rows) / len(rows), 1) if any(r["cost_tokens"] for r in rows) else 0,
        "setup_time_min": rows[0]["setup_time_min"],
        "kg_depth": round(sum(r["kg_depth"] for r in rows) / len(rows), 2) if any(r["kg_depth"] for r in rows) else 0,
        "note": "",
    }


def build_table(data: dict) -> str:
    lines = [
        "| Tier | Method | latency_ms (P50) | recall@5 | cost_tokens | setup_time_min | kg_depth (avg) | note |",
        "|------|--------|-------------------|----------|-------------|----------------|----------------|------|",
    ]
    for t in [1, 2, 3, 4]:
        a = aggregate(data.get(f"tier{t}"))
        lines.append(
            f"| {t} | {TIER_LABEL[t]} | {a['latency_p50']} | {a['recall_at_5']} | {a['cost_tokens']} | {a['setup_time_min']} | {a['kg_depth']} | {a['note']} |"
        )
    lines.append("")
    lines.append(f"Last updated: {data['date']} — [results JSON](benchmark/results/{data['date']}.json)")
    lines.append("")
    lines.append("> 측정 방법 + 해석 가이드: [docs/BENCHMARK.md](docs/BENCHMARK.md)")
    return "\n".join(lines)


def inject_readme(table: str) -> None:
    if not README.exists():
        sys.exit("README.md not found")
    txt = README.read_text(encoding="utf-8")
    start = "<!-- BENCHMARK-TABLE-START -->"
    end = "<!-- BENCHMARK-TABLE-END -->"
    if start not in txt or end not in txt:
        sys.exit(f"README missing markers {start} / {end} — add them first")
    pre, _, rest = txt.partition(start)
    _, _, post = rest.partition(end)
    new = pre + start + "\n" + table + "\n" + end + post
    README.write_text(new, encoding="utf-8")
    print("README.md benchmark table updated")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--print-only", action="store_true", help="print table to stdout, skip README injection")
    args = ap.parse_args()

    data = json.loads(latest_json().read_text())
    table = build_table(data)

    if args.print_only:
        print(table)
    else:
        inject_readme(table)
        print(table)


if __name__ == "__main__":
    main()
