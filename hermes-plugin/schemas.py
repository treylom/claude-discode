"""JSON-schema definitions for claude-discode Hermes tools."""

SEARCH_SCHEMA = {
    "type": "object",
    "description": "4-Tier vault search (GraphRAG → Obsidian CLI → MCP → ripgrep).",
    "properties": {
        "query": {"type": "string", "description": "Search query in natural language."},
        "mode": {
            "type": "string",
            "enum": ["quick", "deep", "auto"],
            "default": "auto",
        },
        "no_moc": {"type": "boolean", "default": False, "description": "Skip MOC priority routing."},
        "force_tier": {
            "type": "integer",
            "minimum": 1,
            "maximum": 4,
            "description": "Optional: force a specific Tier for debugging.",
        },
    },
    "required": ["query"],
}

INGEST_SCHEMA = {
    "type": "object",
    "description": "Mode I — ingest a URL / file / inline text into the vault (km-lite variant).",
    "properties": {
        "content": {"type": "string", "description": "Inline text to ingest (alternative to source)."},
        "source": {"type": "string", "description": "URL or file path."},
        "title": {"type": "string"},
        "variant": {
            "type": "string",
            "enum": ["lite", "plain"],
            "default": "lite",
        },
    },
    "anyOf": [{"required": ["content"]}, {"required": ["source"]}],
}
