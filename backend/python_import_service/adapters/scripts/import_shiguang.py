from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent
WORKSPACE_ROOT = SERVICE_ROOT.parent.parent

SHIGUANG_ROOT = WORKSPACE_ROOT / "shiguang_warehouse"
SHIGUANG_INDEX = SHIGUANG_ROOT / "index" / "root_index.yaml"
SHIGUANG_RESOURCES = SHIGUANG_ROOT / "resources"
MIGRATION_MAP_PATH = ADAPTER_ROOT / "index" / "migration_map.yaml"
SCHOOL_INDEX_PATH = ADAPTER_ROOT / "index" / "school_index.yaml"


def normalize_level_from_category(category: str | None) -> str:
    value = (category or "").strip().upper()
    if value == "BACHELOR_AND_ASSOCIATE":
        return "undergraduate"
    if value == "POSTGRADUATE":
        return "master"
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


def adapter_config_paths() -> list[Path]:
    return sorted(
        [
            *(ADAPTER_ROOT / "undergraduate" / "schools").glob("*.json"),
            *(ADAPTER_ROOT / "master" / "schools").glob("*.json"),
            *(ADAPTER_ROOT / "general" / "systems").glob("*.json"),
        ]
    )


def strip_inline_comment(line: str) -> str:
    in_double = False
    in_single = False
    escaped = False
    for index, ch in enumerate(line):
        if escaped:
            escaped = False
            continue
        if ch == "\\":
            escaped = True
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            continue
        if ch == "'" and not in_double:
            in_single = not in_single
            continue
        if ch == "#" and not in_double and not in_single:
            return line[:index]
    return line


def parse_scalar(raw: str) -> str:
    value = raw.strip()
    if not value:
        return ""
    if value.startswith('"') and value.endswith('"') and len(value) >= 2:
        return str(json.loads(value))
    return value


def parse_root_index(path: Path) -> list[dict[str, str]]:
    schools: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = strip_inline_comment(raw_line).rstrip()
        if not line.strip():
            continue

        match = re.match(r'^\s*-\s*id:\s*(.+?)\s*$', line)
        if match:
            if current and current.get("resource_folder"):
                schools.append(current)
            current = {"id": parse_scalar(match.group(1))}
            continue

        if current is None:
            continue

        for key in ("name", "initial", "resource_folder"):
            match = re.match(rf'^\s*{key}:\s*(.+?)\s*$', line)
            if match:
                current[key] = parse_scalar(match.group(1))
                break

    if current and current.get("resource_folder"):
        schools.append(current)

    return schools


def parse_adapters_yaml(path: Path) -> list[dict[str, str]]:
    adapters: list[dict[str, str]] = []
    current: dict[str, str] | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = strip_inline_comment(raw_line).rstrip()
        if not line.strip():
            continue

        match = re.match(r'^\s*-\s*adapter_id:\s*(.+?)\s*$', line)
        if match:
            if current and current.get("adapter_id"):
                adapters.append(current)
            current = {"adapter_id": parse_scalar(match.group(1))}
            continue

        if current is None:
            continue

        for key in (
            "adapter_name",
            "category",
            "asset_js_path",
            "import_url",
            "maintainer",
            "description",
        ):
            match = re.match(rf'^\s*{key}:\s*(.+?)\s*$', line)
            if match:
                current[key] = parse_scalar(match.group(1))
                break

    if current and current.get("adapter_id"):
        adapters.append(current)

    return adapters


def sanitize_school_id(raw: str) -> str:
    text = re.sub(r"[^a-z0-9_]+", "_", raw.strip().lower()).strip("_")
    return text or "adapter"


def unique_school_id(base: str, used: set[str]) -> str:
    candidate = base
    suffix = 2
    while candidate in used:
        candidate = f"{base}_{suffix}"
        suffix += 1
    return candidate


def yaml_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


def default_runtime_payload(
    school_id: str,
    title: str,
    level: str,
    import_url: str,
    system_type: str,
    notes: str,
) -> dict:
    return {
        "id": school_id,
        "name": title,
        "level": level,
        "system_type": system_type,
        "login_url": import_url,
        "target_url": "",
        "fetch_config": {
            "url": "",
            "method": "POST",
            "headers": {},
            "body_template": "",
            "credentials": "include",
        },
        "term_mapping": {"first": "1", "second": "2", "short": ""},
        "data_path": "",
        "field_mapping": {
            "name": "name",
            "position": "position",
            "teacher": "teacher",
            "weeks": "weeks",
            "day": "day",
            "sections": "sections",
        },
        "timer_config": {
            "total_week": 20,
            "start_semester": "2026-02-24",
            "start_with_sunday": False,
            "forenoon": 5,
            "afternoon": 4,
            "night": 3,
            "sections": [],
        },
        "script_version": "1.0.0",
        "pre_extract_delay": 0,
        "notes": notes,
    }


def load_existing_origin_map() -> tuple[dict[tuple[str, str], str], set[str], list[dict]]:
    origin_map: dict[tuple[str, str], str] = {}
    used_ids: set[str] = set()
    existing_records: list[dict] = []

    for path in adapter_config_paths():
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue

        school_id = str(payload.get("id", "")).strip()
        if not school_id:
            continue

        used_ids.add(school_id)

        source = str(payload.get("source", "")).strip()
        source_path = str(payload.get("source_path", "")).strip()
        source_adapter_id = str(payload.get("source_adapter_id", "")).strip()
        if source == "shiguang_warehouse" and source_path and source_adapter_id:
            origin_map[(source_path, source_adapter_id)] = school_id

        existing_records.append(
            {
                "id": school_id,
                "level": str(payload.get("level", "general") or "general"),
                "title": str(payload.get("title") or school_id),
                "system_type": str(payload.get("system_type") or ""),
            }
        )

    return origin_map, used_ids, existing_records


def remove_existing_shiguang_entries() -> int:
    removed = 0
    for path in adapter_config_paths():
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue

        if str(payload.get("source", "")).strip() != "shiguang_warehouse":
            continue

        school_id = str(payload.get("id", "")).strip()
        path.unlink(missing_ok=True)
        removed += 1

        if school_id:
            script_name = f"{school_id}_provider.js"
            for script_dir in (
                ADAPTER_ROOT / "undergraduate" / "scripts",
                ADAPTER_ROOT / "master" / "scripts",
                ADAPTER_ROOT / "general" / "scripts",
            ):
                (script_dir / script_name).unlink(missing_ok=True)

    return removed


def write_migration_map(items: list[dict[str, str]]) -> None:
    lines = ["version: 1", "items:"]
    for item in items:
        lines.append(f"  - source_repo: {yaml_quote(item['source_repo'])}")
        lines.append(f"    source_path: {yaml_quote(item['source_path'])}")
        lines.append(f"    license: {yaml_quote(item['license'])}")
        lines.append(f"    target_path: {yaml_quote(item['target_path'])}")
        lines.append(f"    maintainer: {yaml_quote(item['maintainer'])}")
    if not items:
        lines.append("  []")

    MIGRATION_MAP_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


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


def main() -> int:
    parser = argparse.ArgumentParser(description="Import adapters from shiguang_warehouse into adapters source tree")
    parser.add_argument(
        "--clean",
        action="store_true",
        help="remove previously imported shiguang adapters before importing",
    )
    args = parser.parse_args()

    if not SHIGUANG_INDEX.exists() or not SHIGUANG_RESOURCES.exists():
        print("shiguang_warehouse not found, skip import")
        return 1

    if args.clean:
        removed = remove_existing_shiguang_entries()
        print(f"cleaned previous shiguang adapters: {removed}")

    origin_map, used_ids, existing_records = load_existing_origin_map()
    school_entries = parse_root_index(SHIGUANG_INDEX)

    migration_items: list[dict[str, str]] = [
        {
            "source_repo": "classduck/backend_runtime",
            "source_path": "data/school_configs/sora.json",
            "license": "INTERNAL",
            "target_path": "adapters/general/systems/sora.json",
            "maintainer": "unknown",
        },
        {
            "source_repo": "classduck/backend_runtime",
            "source_path": "data/school_configs/xjtu.json",
            "license": "INTERNAL",
            "target_path": "adapters/undergraduate/schools/xjtu.json",
            "maintainer": "unknown",
        },
    ]

    generated_records: list[dict] = []
    missing_scripts: list[str] = []
    imported = 0

    for school in school_entries:
        resource_folder = school.get("resource_folder", "").strip()
        if not resource_folder:
            continue

        adapters_yaml = SHIGUANG_RESOURCES / resource_folder / "adapters.yaml"
        if not adapters_yaml.exists():
            print(f"skip missing adapters.yaml: {resource_folder}")
            continue

        source_yaml_rel = str(adapters_yaml.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        source_resource_dir = adapters_yaml.parent
        adapters = parse_adapters_yaml(adapters_yaml)

        for adapter in adapters:
            adapter_id = str(adapter.get("adapter_id", "")).strip()
            if not adapter_id:
                continue

            level = normalize_level_from_category(adapter.get("category"))
            config_dir, script_dir = target_paths(level)
            config_dir.mkdir(parents=True, exist_ok=True)
            script_dir.mkdir(parents=True, exist_ok=True)

            source_path = f"{source_yaml_rel}#{adapter_id}"
            origin_key = (source_path, adapter_id)

            if origin_key in origin_map:
                school_id = origin_map[origin_key]
            else:
                base_id = sanitize_school_id(adapter_id)
                if base_id in used_ids:
                    base_id = sanitize_school_id(f"{adapter_id}_{resource_folder}")
                school_id = unique_school_id(base_id, used_ids)

            used_ids.add(school_id)

            title = str(adapter.get("adapter_name") or school.get("name") or school_id)
            import_url = str(adapter.get("import_url") or "")
            system_type = resource_folder.lower()
            maintainer = str(adapter.get("maintainer") or "unknown")
            description = str(adapter.get("description") or "")

            notes = f"Imported from shiguang_warehouse/{resource_folder}/{adapter_id}"
            if description:
                notes = f"{notes} | {description}"

            runtime_payload = default_runtime_payload(
                school_id=school_id,
                title=title,
                level=level,
                import_url=import_url,
                system_type=system_type,
                notes=notes,
            )

            adapter_payload = {
                "id": school_id,
                "level": level,
                "title": title,
                "import_url": import_url,
                "target_url": "",
                "system_type": system_type,
                "delay_seconds": 0,
                "source": "shiguang_warehouse",
                "source_path": source_path,
                "source_adapter_id": adapter_id,
                "source_school_id": school.get("id", ""),
                "resource_folder": resource_folder,
                "license": "MIT",
                "maintainer": maintainer,
                "asset_js_path": str(adapter.get("asset_js_path") or ""),
                "runtime": runtime_payload,
            }

            target_config_path = config_dir / f"{school_id}.json"
            target_config_path.write_text(
                json.dumps(adapter_payload, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            script_rel = str(adapter.get("asset_js_path") or "").strip()
            target_script_name = f"{school_id}_provider.js"
            source_script_path = source_resource_dir / script_rel if script_rel else None
            if source_script_path and source_script_path.exists():
                target_script_path = script_dir / target_script_name
                target_script_path.write_text(source_script_path.read_text(encoding="utf-8"), encoding="utf-8")
            else:
                missing_scripts.append(source_path)

            migration_items.append(
                {
                    "source_repo": "shiguang_warehouse",
                    "source_path": source_path,
                    "license": "MIT",
                    "target_path": str(target_config_path.relative_to(SERVICE_ROOT)).replace("\\", "/"),
                    "maintainer": maintainer,
                }
            )
            generated_records.append(
                {
                    "id": school_id,
                    "level": level,
                    "title": title,
                    "system_type": system_type,
                }
            )
            imported += 1

    index_records: dict[str, dict] = {}
    for record in existing_records:
        index_records[record["id"]] = record
    for record in generated_records:
        index_records[record["id"]] = record

    write_school_index(list(index_records.values()))
    write_migration_map(migration_items)

    print(f"imported shiguang adapters: {imported}")
    if missing_scripts:
        print(f"missing scripts: {len(missing_scripts)}")
        for item in sorted(set(missing_scripts)):
            print(f"  - {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())