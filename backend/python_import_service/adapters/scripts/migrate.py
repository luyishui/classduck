from __future__ import annotations

import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent
RUNTIME_CONFIG_DIR = SERVICE_ROOT / "data" / "school_configs"
RUNTIME_SCRIPT_DIR = SERVICE_ROOT / "data" / "scripts"


def normalize_level(level: str | None) -> str:
    raw = (level or "").strip().lower()
    if raw == "junior":
        return "undergraduate"
    if raw in {"undergraduate", "master", "general"}:
        return raw
    return "general"


def target_paths(level: str) -> tuple[Path, Path]:
    if level == "master":
        return (
            ADAPTER_ROOT / "master" / "schools",
            ADAPTER_ROOT / "master" / "scripts",
        )
    if level == "undergraduate":
        return (
            ADAPTER_ROOT / "undergraduate" / "schools",
            ADAPTER_ROOT / "undergraduate" / "scripts",
        )
    return (
        ADAPTER_ROOT / "general" / "systems",
        ADAPTER_ROOT / "general" / "scripts",
    )


def write_migration_map(items: list[dict[str, str]]) -> None:
    lines = ["version: 1", "items:"]
    for item in items:
        lines.append("  - source_repo: \"classduck/backend_runtime\"")
        lines.append(f"    source_path: \"{item['source_path']}\"")
        lines.append("    license: \"INTERNAL\"")
        lines.append(f"    target_path: \"{item['target_path']}\"")
        lines.append("    maintainer: \"unknown\"")
    if not items:
        lines.append("  []")
    (ADAPTER_ROOT / "index" / "migration_map.yaml").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    if not RUNTIME_CONFIG_DIR.exists():
        print(f"runtime config dir not found: {RUNTIME_CONFIG_DIR}")
        return 1

    migrated = 0
    mapping_items: list[dict[str, str]] = []

    for config_path in sorted(RUNTIME_CONFIG_DIR.glob("*.json")):
        data = json.loads(config_path.read_text(encoding="utf-8"))

        school_id = str(data.get("id", "")).strip()
        if not school_id:
            print(f"skip config without id: {config_path.name}")
            continue

        level = normalize_level(data.get("level"))
        config_dir, script_dir = target_paths(level)
        config_dir.mkdir(parents=True, exist_ok=True)
        script_dir.mkdir(parents=True, exist_ok=True)

        adapter_data = {
            "id": school_id,
            "level": level,
            "title": data.get("name", school_id),
            "import_url": data.get("login_url", ""),
            "target_url": data.get("target_url", ""),
            "system_type": data.get("system_type", ""),
            "delay_seconds": data.get("pre_extract_delay", 0),
            "source": "classduck_runtime",
            "source_path": str(config_path.relative_to(SERVICE_ROOT)).replace("\\", "/"),
            "license": "INTERNAL",
            "runtime": data,
        }

        target_config_path = config_dir / f"{school_id}.json"
        target_config_path.write_text(
            json.dumps(adapter_data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        runtime_script = RUNTIME_SCRIPT_DIR / f"{school_id}_provider.js"
        if runtime_script.exists():
            target_script = script_dir / runtime_script.name
            target_script.write_text(runtime_script.read_text(encoding="utf-8"), encoding="utf-8")

        mapping_items.append(
            {
                "source_path": str(config_path.relative_to(SERVICE_ROOT)).replace("\\", "/"),
                "target_path": str(target_config_path.relative_to(SERVICE_ROOT)).replace("\\", "/"),
            }
        )
        migrated += 1

    write_migration_map(mapping_items)
    print(f"migrated configs: {migrated}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
