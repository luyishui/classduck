from __future__ import annotations


def normalize_level(level: str | None) -> str:
    raw = (level or "").strip().lower()
    if raw == "junior":
        return "undergraduate"
    if raw in {"undergraduate", "master", "general"}:
        return raw
    return "general"
