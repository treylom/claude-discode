"""thiscode — Hermes plugin entry point.

Wires the thiscode 4-Tier search + KM ingestion tools into Hermes Agent.
Bridges to the bash-based dispatcher in ../skills/search/references/
and the km-lite variant in ../skills/thiscode-km-lite/references/ via subprocess.
"""

from . import schemas, tools


def register(ctx):
    ctx.register_tool(
        name="claude_discode_search",
        toolset="research",
        schema=schemas.SEARCH_SCHEMA,
        handler=tools.handle_search,
    )
    ctx.register_tool(
        name="claude_discode_ingest",
        toolset="knowledge",
        schema=schemas.INGEST_SCHEMA,
        handler=tools.handle_ingest,
    )
    ctx.register_hook("on_session_start", tools.session_start_drift_check)
    ctx.register_command("/search", tools.cmd_search)
    ctx.register_command("/thiscode-km", tools.cmd_km)
