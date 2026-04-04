from __future__ import annotations

import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent
RUNTIME_CONFIG_DIR = SERVICE_ROOT / "data" / "school_configs"
RUNTIME_SCRIPT_DIR = SERVICE_ROOT / "data" / "scripts"
INDEX_YAML = ADAPTER_ROOT / "index" / "school_index.yaml"


def normalize_level(level: str | None) -> str:
    raw = (level or "").strip().lower()
    if raw == "junior":
        return "undergraduate"
    if raw in {"undergraduate", "master", "general"}:
        return raw
    return "general"


def adapter_config_paths() -> list[Path]:
    return sorted(
        [
            * (ADAPTER_ROOT / "undergraduate" / "schools").glob("*.json"),
            * (ADAPTER_ROOT / "master" / "schools").glob("*.json"),
            * (ADAPTER_ROOT / "general" / "systems").glob("*.json"),
        ]
    )


def ensure_runtime_defaults(runtime: dict, adapter: dict) -> dict:
    school_id = str(adapter.get("id", "")).strip()
    title = str(adapter.get("title") or runtime.get("name") or school_id)
    level = normalize_level(adapter.get("level") or runtime.get("level"))
    import_url = str(adapter.get("import_url") or runtime.get("login_url") or "")
    target_url = str(adapter.get("target_url") or runtime.get("target_url") or "")
    system_type = str(adapter.get("system_type") or runtime.get("system_type") or "")
    delay_seconds = int(adapter.get("delay_seconds") or runtime.get("pre_extract_delay") or 0)

    out = dict(runtime)
    out["id"] = school_id
    out["name"] = title
    out["level"] = level
    out["system_type"] = system_type
    out["login_url"] = import_url
    out["target_url"] = target_url
    out["script_version"] = str(out.get("script_version") or "1.0.0")
    out["pre_extract_delay"] = delay_seconds

    out.setdefault(
        "fetch_config",
        {
            "url": "",
            "method": "POST",
            "headers": {},
            "body_template": "",
            "credentials": "include",
        },
    )
    out.setdefault("term_mapping", {"first": "1", "second": "2", "short": ""})
    out.setdefault("data_path", "")
    out.setdefault(
        "field_mapping",
        {
            "name": "name",
            "position": "position",
            "teacher": "teacher",
            "weeks": "weeks",
            "day": "day",
            "sections": "sections",
        },
    )
    out.setdefault(
        "timer_config",
        {
            "total_week": 20,
            "start_semester": "2026-02-24",
            "start_with_sunday": False,
            "forenoon": 5,
            "afternoon": 4,
            "night": 3,
            "sections": [],
        },
    )
    out.setdefault("notes", "")
    return out


def write_index_yaml(items: list[dict]) -> None:
    lines = ["version: 1", "schools:"]
    for item in items:
        lines.append(f"  - id: \"{item['id']}\"")
        lines.append(f"    title: \"{item['title']}\"")
        lines.append(f"    level: \"{item['level']}\"")
        lines.append(f"    system_type: \"{item['systemType']}\"")
    if not items:
        lines.append("  []")
    INDEX_YAML.write_text("\n".join(lines) + "\n", encoding="utf-8")


def copy_scripts_for_school(school_id: str) -> None:
    script_name = f"{school_id}_provider.js"
    for source_dir in (
        ADAPTER_ROOT / "undergraduate" / "scripts",
        ADAPTER_ROOT / "master" / "scripts",
        ADAPTER_ROOT / "general" / "scripts",
    ):
        candidate = source_dir / script_name
        if candidate.exists():
            RUNTIME_SCRIPT_DIR.mkdir(parents=True, exist_ok=True)
            (RUNTIME_SCRIPT_DIR / script_name).write_text(
                candidate.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            return


def main() -> int:
    RUNTIME_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_SCRIPT_DIR.mkdir(parents=True, exist_ok=True)

    summary_items: list[dict] = []
    published = 0

    for adapter_path in adapter_config_paths():
        adapter = json.loads(adapter_path.read_text(encoding="utf-8"))
        school_id = str(adapter.get("id", "")).strip()
        if not school_id:
            print(f"skip invalid adapter file (missing id): {adapter_path.name}")
            continue

        runtime = adapter.get("runtime") if isinstance(adapter.get("runtime"), dict) else {}
        runtime_out = ensure_runtime_defaults(runtime, adapter)

        (RUNTIME_CONFIG_DIR / f"{school_id}.json").write_text(
            json.dumps(runtime_out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        copy_scripts_for_school(school_id)

        level = normalize_level(runtime_out.get("level"))
        summary_items.append(
            {
                "id": school_id,
                "delaySeconds": int(runtime_out.get("pre_extract_delay", 0)),
                "level": level,
                "targetUrl": runtime_out.get("target_url", ""),
                "extractScriptUrl": f"/api/schools/{school_id}/script?script_type=provider",
                "title": runtime_out.get("name", school_id),
                "initialUrl": runtime_out.get("login_url", ""),
                "systemType": runtime_out.get("system_type", ""),
                "scriptVersion": runtime_out.get("script_version", "1.0.0"),
            }
        )
        published += 1

    write_index_yaml(summary_items)
    print(f"published adapters: {published}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
