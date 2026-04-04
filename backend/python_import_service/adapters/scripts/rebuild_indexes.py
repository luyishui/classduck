from __future__ import annotations

import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent

SCHOOL_INDEX_PATH = ADAPTER_ROOT / "index" / "school_index.yaml"
MIGRATION_MAP_PATH = ADAPTER_ROOT / "index" / "migration_map.yaml"

SOURCE_REPO_MAP = {
    "shiguang_warehouse": "shiguang_warehouse",
    "classduck_runtime": "classduck/backend_runtime",
    "class_schedule_flutter": "Class-Shedule-Flutter",
    "aishedule_master": "aishedule-master",
}


def adapter_config_paths() -> list[Path]:
    return sorted(
        [
            *(ADAPTER_ROOT / "undergraduate" / "schools").glob("*.json"),
            *(ADAPTER_ROOT / "master" / "schools").glob("*.json"),
            *(ADAPTER_ROOT / "general" / "systems").glob("*.json"),
        ]
    )


def yaml_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


def write_school_index(items: list[dict[str, str]]) -> None:
    lines = ["version: 1", "schools:"]
    for item in sorted(items, key=lambda it: (it.get("title", ""), it.get("id", ""))):
        lines.append(f"  - id: {yaml_quote(item['id'])}")
        lines.append(f"    title: {yaml_quote(item['title'])}")
        lines.append(f"    level: {yaml_quote(item['level'])}")
        lines.append(f"    system_type: {yaml_quote(item['system_type'])}")
    if not items:
        lines.append("  []")
    SCHOOL_INDEX_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_migration_map(items: list[dict[str, str]]) -> None:
    lines = ["version: 1", "items:"]
    for item in sorted(
        items,
        key=lambda it: (it.get("source_repo", ""), it.get("source_path", ""), it.get("target_path", "")),
    ):
        lines.append(f"  - source_repo: {yaml_quote(item['source_repo'])}")
        lines.append(f"    source_path: {yaml_quote(item['source_path'])}")
        lines.append(f"    license: {yaml_quote(item['license'])}")
        lines.append(f"    target_path: {yaml_quote(item['target_path'])}")
        lines.append(f"    maintainer: {yaml_quote(item['maintainer'])}")
    if not items:
        lines.append("  []")
    MIGRATION_MAP_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    school_items: list[dict[str, str]] = []
    migration_items: list[dict[str, str]] = []
    seen_migration_keys: set[tuple[str, str, str]] = set()

    for config_path in adapter_config_paths():
        try:
            payload = json.loads(config_path.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"skip invalid config {config_path.name}: {exc}")
            continue

        school_id = str(payload.get("id") or "").strip()
        if not school_id:
            continue

        school_items.append(
            {
                "id": school_id,
                "title": str(payload.get("title") or school_id),
                "level": str(payload.get("level") or "general"),
                "system_type": str(payload.get("system_type") or ""),
            }
        )

        source_path = str(payload.get("source_path") or "").strip()
        if not source_path:
            continue

        source = str(payload.get("source") or "").strip()
        source_repo = SOURCE_REPO_MAP.get(source, source or "unknown")
        license_name = str(payload.get("license") or "UNKNOWN")
        maintainer = str(payload.get("maintainer") or "unknown")
        target_path = str(config_path.relative_to(SERVICE_ROOT)).replace("\\", "/")

        migration_key = (source_repo, source_path, target_path)
        if migration_key in seen_migration_keys:
            continue
        seen_migration_keys.add(migration_key)

        migration_items.append(
            {
                "source_repo": source_repo,
                "source_path": source_path,
                "license": license_name,
                "target_path": target_path,
                "maintainer": maintainer,
            }
        )

    write_school_index(school_items)
    write_migration_map(migration_items)

    print(f"rebuilt school index entries: {len(school_items)}")
    print(f"rebuilt migration map entries: {len(migration_items)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
