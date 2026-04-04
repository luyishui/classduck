from __future__ import annotations

from pathlib import Path


def discover_fixture_dirs(fixtures_root: Path) -> list[Path]:
    """Return fixture directories under tests/fixtures."""
    if not fixtures_root.exists():
        return []
    return sorted([p for p in fixtures_root.iterdir() if p.is_dir()])
