"""
FastAPI server for GraphRAG search — keeps models resident in memory.
Usage: uvicorn search_server:app --host 127.0.0.1 --port 8400
"""
from __future__ import annotations

import os
import sqlite3
import threading
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

import embedding_index
import graph_search
from community_detector import build_networkx_graph
from graphrag_core import close_connection

PROJECT_DIR = Path(__file__).resolve().parents[3]
# v2.3.1: env override + CI fresh env 안 graceful start (vault_graph.db anchor 없어도 server up)
DEFAULT_DB_PATH = Path(os.environ.get(
    "GRAPHRAG_DB_PATH",
    str(PROJECT_DIR / ".team-os/graphrag/index/vault_graph.db"),
))
DEFAULT_INDEX_DIR = Path(os.environ.get(
    "GRAPHRAG_INDEX_DIR",
    str(PROJECT_DIR / graph_search.DEFAULT_INDEX_DIR),
))
ALLOWED_ORIGINS = [
    "http://127.0.0.1:3748",
    "http://localhost:3748",
    "http://127.0.0.1:5173",
    "http://localhost:5173",
]
VALID_SEARCH_MODES = {"hybrid", "quick", "deep"}

# P1: Readiness gate — search blocks until models are loaded
_models_ready = threading.Event()


def _clear_model_caches() -> None:
    embedding_index._model = None
    graph_search._cross_encoder = None
    graph_search.clear_hybrid_cache()


def _warm_models() -> None:
    embedding_index._get_model()
    try:
        graph_search._get_cross_encoder()
    except ImportError:
        pass


def _open_readonly_connection(db_path: Path | str) -> sqlite3.Connection:
    db = Path(db_path)
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def _load_runtime_state(db_path: Path = DEFAULT_DB_PATH) -> dict[str, Any]:
    # v2.3.1: db_path 안 graceful — anchor 없으면 conn = None (CI fresh env / vault 미index 환경 안 startup 통과)
    db_p = Path(db_path)
    conn = _open_readonly_connection(db_p) if db_p.exists() else None
    # P1: Don't call _warm_models() here — moved to background thread
    return {
        "db_path": str(db_p),
        "index_dir": str(DEFAULT_INDEX_DIR),
        "conn": conn,
        "graph": None,
    }


def _get_graph(app: FastAPI):
    # v2.3.2: conn=None graceful — graph build requires DB anchor
    if getattr(app.state, "conn", None) is None:
        raise HTTPException(
            status_code=503,
            detail="GraphRAG index not built. Run vault index build first, then POST /reload or restart server.",
        )
    if getattr(app.state, "graph", None) is None:
        app.state.graph = build_networkx_graph(app.state.conn)
    return app.state.graph


def _replace_runtime_state(app: FastAPI, state: dict[str, Any]) -> None:
    old_conn = getattr(app.state, "conn", None)
    if old_conn is not None:
        close_connection(old_conn)
    for key, value in state.items():
        setattr(app.state, key, value)


@asynccontextmanager
async def lifespan(app: FastAPI):
    state = _load_runtime_state()
    _replace_runtime_state(app, state)

    # P1+P2: Background model warmup + diverse query warmup for CV stability
    def _background_warmup():
        # v2.3.1: conn None 시 (anchor 없음, CI fresh env) early return — server 는 up, warmup skip
        if state["conn"] is None:
            _models_ready.set()
            return
        _warm_models()
        # P2: Run diverse warmup queries to prime FTS5/embedding/reranker caches
        warmup_queries = ["GraphRAG", "프롬프트 엔지니어링", "AI 에이전트", "얼룩소"]
        try:
            warmup_conn = _open_readonly_connection(state["db_path"])
            for wq in warmup_queries:
                results = graph_search.hybrid_search(
                    warmup_conn, wq,
                    output_dir=state["index_dir"], top_k=5,
                )
                if results:
                    graph_search.rerank(wq, results, top_k=5)
            close_connection(warmup_conn)
        except Exception:
            pass
        _models_ready.set()

    threading.Thread(target=_background_warmup, daemon=True).start()

    yield
    conn = getattr(app.state, "conn", None)
    if conn is not None:
        close_connection(conn)


app = FastAPI(title="GraphRAG Search Server", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    # v2.3.2: liveness only — process up 확인용. readiness gate 아님.
    # CI / Docker healthcheck 는 /ready 사용 의무.
    db_ready = getattr(app.state, "conn", None) is not None
    search_ready = db_ready and _models_ready.is_set()
    return {
        "status": "ok",
        "models_ready": _models_ready.is_set(),
        "db_ready": db_ready,
        "search_ready": search_ready,
    }


@app.get("/ready")
async def ready():
    # v2.3.2: readiness gate 별도 endpoint — CI / Docker HEALTHCHECK 의무 URL.
    # axis C 2-round debate (codex R2) 권고: /health 가 liveness-only false-positive readiness 차단.
    if getattr(app.state, "conn", None) is None:
        raise HTTPException(
            status_code=503,
            detail={"ready": False, "reason": "db_not_ready", "hint": "vault index not built — run vault index build + POST /reload"},
        )
    if not _models_ready.is_set():
        raise HTTPException(
            status_code=503,
            detail={"ready": False, "reason": "warmup_in_progress"},
        )
    return {"ready": True, "db_path": app.state.db_path}


@app.post("/reload")
async def reload_models():
    # v2.3.2: reload 시 models_ready clear + background warmup re-start
    _clear_model_caches()
    _models_ready.clear()
    new_state = _load_runtime_state(Path(app.state.db_path))
    _replace_runtime_state(app, new_state)

    # background warmup re-execution (lifespan 안 logic 동등)
    def _reload_warmup():
        if new_state["conn"] is None:
            _models_ready.set()
            return
        _warm_models()
        _models_ready.set()

    threading.Thread(target=_reload_warmup, daemon=True).start()

    return {
        "status": "reloaded",
        "db_path": app.state.db_path,
        "index_dir": app.state.index_dir,
        "db_ready": new_state["conn"] is not None,
    }


@app.get("/api/search")
async def search(
    q: str = Query(..., min_length=1),
    mode: str = Query("hybrid"),
    top_k: int = Query(20, ge=1, le=100),
    dense_weight: float = Query(graph_search.DEFAULT_DENSE_WEIGHT),
    sparse_weight: float = Query(graph_search.DEFAULT_SPARSE_WEIGHT),
    decomposed_weight: float = Query(graph_search.DEFAULT_DECOMPOSED_WEIGHT),
    entity_weight: float = Query(graph_search.DEFAULT_ENTITY_WEIGHT),
    rerank: bool = Query(True),
):
    if mode not in VALID_SEARCH_MODES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid mode: {mode}. Valid: {sorted(VALID_SEARCH_MODES)}",
        )

    # v2.3.2: conn=None graceful — DB anchor 없으면 503 (fresh env / vault index 미build)
    if app.state.conn is None:
        raise HTTPException(
            status_code=503,
            detail={
                "error": "GraphRAG index not built",
                "message": "Vault index has not been built. Build index first, then POST /reload or restart server.",
                "db_path": app.state.db_path,
            },
        )

    # P1: Wait for background model warmup (up to 60s)
    _models_ready.wait(timeout=60)

    results = graph_search.hybrid_search(
        app.state.conn,
        q,
        output_dir=app.state.index_dir,
        top_k=top_k,
        dense_weight=dense_weight,
        sparse_weight=sparse_weight,
        decomposed_weight=decomposed_weight,
        entity_weight=entity_weight,
    )
    final_results = graph_search.rerank(q, results, top_k=top_k) if rerank and results else results
    # M6: Community re-scoring for L1+ queries
    if final_results and len(final_results) >= 2:
        query_level = graph_search.classify_query_complexity(q)
        final_results = graph_search.community_rescore(final_results, app.state.conn, query_level)
    search_type = "hybrid+rerank" if rerank and results else "hybrid"
    return {
        "query": q,
        "results": final_results,
        "total": len(final_results),
        "source": "hybrid",
        "search_type": search_type,
    }


@app.get("/api/search/entities")
async def search_entities(
    q: str = Query(..., min_length=1),
    top_k: int = Query(10, ge=1, le=100),
):
    # v2.3.2: entity index 파일 부분 corrupt / missing 시 graceful 503 (uncaught 500 방지)
    try:
        # P3: Cross-lingual query expansion for entity search
        expanded_q = graph_search.expand_query_cross_lingual(q)
        raw_results = embedding_index.search_entities(expanded_q, app.state.index_dir, top_k=top_k)
    except (FileNotFoundError, ImportError, ValueError, OSError) as exc:
        # entity_embeddings.npy / entity_meta.json missing / corrupt / load fail
        raise HTTPException(
            status_code=503,
            detail={
                "error": "Entity index not built",
                "message": f"Entity index unavailable: {type(exc).__name__}. Build index first, then POST /reload.",
                "index_dir": str(app.state.index_dir),
            },
        )
    results = [
        {
            **row,
            "entity": row.get("entity") or row.get("name", ""),
            "name": row.get("name") or row.get("entity", ""),
        }
        for row in raw_results
    ]
    return {
        "query": q,
        "expanded_query": expanded_q if expanded_q != q else None,
        "results": results,
        "total": len(results),
        "source": "entity",
    }
