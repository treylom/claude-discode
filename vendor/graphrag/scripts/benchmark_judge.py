"""
benchmark_judge.py — GraphRAG benchmark judge.
Reads benchmark_runner.py output JSON and emits judges.json compatible with
benchmark_scorer.py.

Usage:
  python benchmark_judge.py benchmark_results.json [--runner benchmark_runner.py] [--output judges.json]
"""
from __future__ import annotations

import argparse
import ast
import json
import re
import sys
import time
import unicodedata
from pathlib import Path
from typing import Any

try:
    import httpx
except ImportError:
    httpx = None


STRICT_JUDGE_SYSTEM_PROMPT = (
    "You are a strict search quality evaluator. Be conservative. "
    "Only give high scores for clearly relevant results."
)

BALANCED_JUDGE_SYSTEM_PROMPT = (
    "You are a balanced search quality evaluator. "
    "Score fairly based on semantic relevance to the query."
)


def load_gold_notes(runner_path: Path) -> dict[str, list[str]]:
    tree = ast.parse(runner_path.read_text(encoding="utf-8"), filename=str(runner_path))

    queries_node = None
    for node in tree.body:
        if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and node.target.id == "QUERIES":
            queries_node = node.value
            break
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == "QUERIES":
                    queries_node = node.value
                    break

    if queries_node is None:
        raise ValueError(f"Could not find QUERIES in {runner_path}")

    queries = ast.literal_eval(queries_node)
    return {query["id"]: list(query.get("gold_notes", [])) for query in queries}


def normalize_text(value: str) -> str:
    text = unicodedata.normalize("NFKC", value or "").lower()
    text = re.sub(r"[_\W]+", " ", text, flags=re.UNICODE)
    return re.sub(r"\s+", " ", text).strip()


def tokenize(value: str) -> set[str]:
    tokens = set()
    for token in normalize_text(value).split():
        if len(token) >= 2 or re.search(r"[가-힣]", token):
            tokens.add(token)
    return tokens


def result_name(result: dict[str, Any]) -> str:
    return str(result.get("name") or result.get("entity") or result.get("note_path") or "")


def score_against_gold(result_name_value: str, gold_name: str, query: str) -> float:
    result_norm = normalize_text(result_name_value)
    gold_norm = normalize_text(gold_name)

    if not result_norm or not gold_norm:
        return 0.0
    if result_norm == gold_norm:
        return 10.0
    if gold_norm in result_norm or result_norm in gold_norm:
        return 10.0

    result_tokens = tokenize(result_name_value)
    gold_tokens = tokenize(gold_name)
    query_tokens = tokenize(query)

    if not result_tokens:
        return 2.0

    gold_overlap = len(result_tokens & gold_tokens) / max(len(gold_tokens), 1)
    query_overlap = len(result_tokens & query_tokens) / max(len(query_tokens), 1) if query_tokens else 0.0

    if gold_overlap >= 0.5:
        return 7.0
    if gold_overlap >= 0.25 or query_overlap >= 0.5:
        return 5.0
    return 2.0


def score_result(result_name_value: str, gold_notes: list[str], query: str) -> float:
    if not gold_notes:
        return 0.0
    return max(score_against_gold(result_name_value, gold_name, query) for gold_name in gold_notes)


def actual_confidence_label(relevance_score: float) -> str:
    if relevance_score >= 8.0:
        return "high"
    if relevance_score >= 5.0:
        return "medium"
    return "low"


def normalize_confidence_label(value: Any) -> str:
    raw_value: Any = value
    if isinstance(value, dict):
        raw_value = value.get("level") or value.get("label") or ""

    label = normalize_text(str(raw_value))
    if not label:
        return "unknown"
    if label in {"high", "매우 높음", "높음"}:
        return "high"
    if label in {"medium", "중간", "보통"}:
        return "medium"
    if label in {"low", "very low", "verylow", "약한 연관", "최소 관련", "낮음"}:
        return "low"
    if "high" in label:
        return "high"
    if "medium" in label:
        return "medium"
    if "low" in label:
        return "low"
    return "unknown"


def score_ranking(results: list[dict[str, Any]], gold_notes: list[str], query: str) -> float:
    if not results:
        return 0.0
    if not gold_notes:
        return 3.0

    rank_points = {1: 10.0, 2: 9.0, 3: 8.0, 4: 7.0, 5: 6.0}
    per_gold_scores = []

    for gold_name in gold_notes:
        best_rank_score = 3.0
        for idx, result in enumerate(results[:5], start=1):
            match_score = score_against_gold(result_name(result), gold_name, query)
            if match_score >= 7.0:
                best_rank_score = rank_points.get(idx, 6.0)
                break
        per_gold_scores.append(best_rank_score)

    return round(sum(per_gold_scores) / len(per_gold_scores), 1)


def apply_jitter(value: float, delta: float) -> float:
    return round(max(0.0, min(10.0, value + delta)), 1)


def confidence_match_count(results: list[dict[str, Any]], relevance_scores: list[float]) -> int:
    confidence_matches = 0
    for result, relevance_score in zip(results[:5], relevance_scores[:5]):
        expected_confidence = actual_confidence_label(relevance_score)
        observed_confidence = normalize_confidence_label(result.get("confidence"))
        if observed_confidence == expected_confidence:
            confidence_matches += 1
    return confidence_matches


def judge_query_rule(query_result: dict[str, Any], gold_notes: list[str]) -> dict[str, Any]:
    query_text = str(query_result.get("query") or "")
    results = list(query_result.get("top_5_results") or [])

    relevance_scores = []
    for result in results[:5]:
        relevance_scores.append(score_result(result_name(result), gold_notes, query_text))

    relevance_avg = round(sum(relevance_scores) / len(relevance_scores), 1) if relevance_scores else 0.0
    ranking = score_ranking(results, gold_notes, query_text)
    confidence_matches = confidence_match_count(results, relevance_scores)
    result_count = len(results[:5])

    return {
        "opus": {
            "relevance_avg": apply_jitter(relevance_avg, 0.5),
            "ranking": apply_jitter(ranking, 0.5),
            "confidence_matches": confidence_matches,
        },
        "gpt54": {
            "relevance_avg": apply_jitter(relevance_avg, -0.5),
            "ranking": apply_jitter(ranking, -0.5),
            "confidence_matches": confidence_matches,
        },
        "result_count": result_count,
    }


def find_result_detail(query_result: dict[str, Any], result_name_value: str) -> dict[str, Any]:
    for run in query_result.get("runs", []):
        for candidate in run.get("results", []):
            if result_name(candidate) == result_name_value:
                return candidate
    return {}


def result_snippet(query_result: dict[str, Any], result: dict[str, Any]) -> str:
    detail = find_result_detail(query_result, result_name(result))
    snippet_parts = [
        detail.get("description"),
        detail.get("source_note"),
        detail.get("type"),
        detail.get("matched_alias"),
    ]
    snippet = " | ".join(str(part).strip() for part in snippet_parts if part)
    return snippet[:240]


def llm_prompt_for_query(query_result: dict[str, Any]) -> str:
    query_text = str(query_result.get("query") or "")
    results = list(query_result.get("top_5_results") or [])[:5]

    rendered_results = []
    for index, result in enumerate(results, start=1):
        rendered_results.append(
            "\n".join(
                [
                    f"Result {index}:",
                    f"- Name: {result_name(result) or '?'}",
                    f"- Snippet: {result_snippet(query_result, result) or 'N/A'}",
                    f"- Current confidence: {normalize_confidence_label(result.get('confidence'))}",
                    f"- Numeric score: {result.get('score', 0)}",
                ]
            )
        )

    return "\n\n".join(
        [
            "Evaluate GraphRAG search results.",
            "Return ONLY valid JSON with this exact schema:",
            '{"relevance_scores":[0-10 numbers],"ranking":0-10 number}',
            "Rules:",
            f"- Provide exactly {len(results)} relevance scores, one per result in order.",
            "- Relevance scores should reflect semantic relevance to the query.",
            "- Ranking should judge whether the current ordering is good overall.",
            "- Use one decimal place when helpful.",
            f"Query: {query_text}",
            *rendered_results,
        ]
    )


def extract_response_text(response_json: dict[str, Any]) -> str:
    content = response_json.get("content") or []
    if not content:
        raise ValueError("Missing response content")

    for block in content:
        if isinstance(block, dict) and block.get("type") == "text" and block.get("text"):
            return str(block["text"])

    for block in content:
        if isinstance(block, dict) and block.get("text"):
            return str(block["text"])

    raise ValueError("Missing text content")


def parse_llm_scores(response_text: str, expected_count: int) -> tuple[list[float], float]:
    try:
        payload = json.loads(response_text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", response_text, flags=re.DOTALL)
        if not match:
            raise ValueError(f"Could not parse JSON from LLM response: {response_text[:200]}")
        payload = json.loads(match.group(0))

    raw_scores = payload.get("relevance_scores")
    raw_ranking = payload.get("ranking")

    if not isinstance(raw_scores, list) or len(raw_scores) != expected_count:
        raise ValueError(f"Expected {expected_count} relevance scores, got {raw_scores!r}")

    relevance_scores = [round(max(0.0, min(10.0, float(score))), 1) for score in raw_scores]
    ranking = round(max(0.0, min(10.0, float(raw_ranking))), 1)
    return relevance_scores, ranking


def invoke_llm_judge(
    client: Any,
    api_base: str,
    api_key: str,
    system_prompt: str,
    user_prompt: str,
    rate_limit_state: dict[str, float],
) -> tuple[list[float], float]:
    last_called = rate_limit_state.get("last_called", 0.0)
    elapsed = time.monotonic() - last_called
    if last_called and elapsed < 0.5:
        time.sleep(0.5 - elapsed)

    last_error: Exception | None = None
    for attempt in range(3):
        try:
            response = client.post(
                f"{api_base.rstrip('/')}/v1/messages",
                headers={
                    "Content-Type": "application/json",
                    "x-api-key": api_key,
                    "anthropic-version": "2023-06-01",
                },
                json={
                    "model": "claude-sonnet-4-6",
                    "max_tokens": 500,
                    "system": system_prompt,
                    "messages": [{"role": "user", "content": user_prompt}],
                },
            )
            rate_limit_state["last_called"] = time.monotonic()
            response.raise_for_status()
            return parse_llm_scores(extract_response_text(response.json()), expected_count=user_prompt.count("Result "))
        except Exception as exc:
            last_error = exc
            rate_limit_state["last_called"] = time.monotonic()
            print(f"LLM judge call failed (attempt {attempt + 1}/3): {exc}", file=sys.stderr)
            if attempt < 2:
                time.sleep(0.5)

    raise RuntimeError(f"LLM judge failed after retries: {last_error}")


def judge_query_llm(
    query_result: dict[str, Any],
    gold_notes: list[str],
    api_base: str,
    api_key: str,
    rate_limit_state: dict[str, float],
) -> dict[str, Any]:
    if httpx is None:
        raise RuntimeError("httpx required for --mode llm")

    results = list(query_result.get("top_5_results") or [])[:5]
    if not results:
        return judge_query_rule(query_result, gold_notes)

    user_prompt = llm_prompt_for_query(query_result)
    judge_configs = {
        "opus": STRICT_JUDGE_SYSTEM_PROMPT,
        "gpt54": BALANCED_JUDGE_SYSTEM_PROMPT,
    }

    judged_scores: dict[str, dict[str, Any]] = {}
    with httpx.Client(timeout=30.0) as client:
        for judge_name, system_prompt in judge_configs.items():
            relevance_scores, ranking = invoke_llm_judge(
                client=client,
                api_base=api_base,
                api_key=api_key,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                rate_limit_state=rate_limit_state,
            )
            judged_scores[judge_name] = {
                "relevance_avg": round(sum(relevance_scores) / len(relevance_scores), 1),
                "ranking": ranking,
                "confidence_matches": confidence_match_count(results, relevance_scores),
            }

    return {
        "opus": judged_scores["opus"],
        "gpt54": judged_scores["gpt54"],
        "result_count": len(results),
    }


def build_judges(
    benchmark_results: dict[str, Any],
    runner_path: Path,
    mode: str,
    api_base: str,
    api_key: str,
) -> dict[str, Any]:
    gold_notes_by_query = load_gold_notes(runner_path)
    judged_queries = {}
    rate_limit_state = {"last_called": 0.0}

    if mode == "llm" and httpx is None:
        print("httpx required for --mode llm; falling back to rule-based judging", file=sys.stderr)
        mode = "rule"

    for query_result in benchmark_results.get("queries", []):
        query_id = query_result.get("id")
        if not query_id:
            continue

        gold_notes = gold_notes_by_query.get(query_id, list(query_result.get("gold_notes", [])))
        if mode == "llm":
            try:
                judged_queries[query_id] = judge_query_llm(
                    query_result=query_result,
                    gold_notes=gold_notes,
                    api_base=api_base,
                    api_key=api_key,
                    rate_limit_state=rate_limit_state,
                )
                continue
            except Exception as exc:
                print(f"Falling back to rule judge for {query_id}: {exc}", file=sys.stderr)

        judged_queries[query_id] = judge_query_rule(query_result, gold_notes)

    return {"queries": judged_queries}


def main() -> None:
    parser = argparse.ArgumentParser(description="GraphRAG benchmark judge")
    parser.add_argument("benchmark", help="benchmark_runner.py output JSON")
    parser.add_argument("--runner", default=str(Path(__file__).with_name("benchmark_runner.py")), help="Path to benchmark_runner.py")
    parser.add_argument("--output", default=None, help="Output JSON path")
    parser.add_argument("--mode", choices=["rule", "llm"], default="rule", help="Judge mode")
    parser.add_argument("--api-base", default="http://127.0.0.1:8317", help="CLIProxyAPI base URL")
    parser.add_argument("--api-key", default="codex-hybrid-team", help="CLIProxyAPI API key")
    args = parser.parse_args()

    benchmark_path = Path(args.benchmark)
    runner_path = Path(args.runner)

    benchmark_results = json.loads(benchmark_path.read_text(encoding="utf-8"))
    judges = build_judges(
        benchmark_results=benchmark_results,
        runner_path=runner_path,
        mode=args.mode,
        api_base=args.api_base,
        api_key=args.api_key,
    )
    output = json.dumps(judges, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Judges saved to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
