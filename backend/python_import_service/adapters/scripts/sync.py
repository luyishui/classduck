from __future__ import annotations

import json
from codecs import BOM_UTF8
from datetime import date
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent
WORKSPACE_ROOT = SERVICE_ROOT.parent.parent
RUNTIME_CONFIG_DIR = SERVICE_ROOT / "data" / "school_configs"
BUILTIN_PATH = WORKSPACE_ROOT / "classduck_app" / "assets" / "config" / "schools.builtin.json"


def normalize_level(level: str | None) -> str:
    raw = (level or "").strip().lower()
    if raw == "junior":
        return "undergraduate"
    if raw in {"undergraduate", "master", "general"}:
        return raw
    return "general"


def build_runtime_summary() -> list[dict]:
    entries: list[dict] = []
    for config_path in sorted(RUNTIME_CONFIG_DIR.glob("*.json")):
        runtime = json.loads(config_path.read_text(encoding="utf-8"))
        school_id = str(runtime.get("id", "")).strip()
        if not school_id:
            continue
        entries.append(
            {
                "id": school_id,
                "delaySeconds": int(runtime.get("pre_extract_delay", 0)),
                "level": normalize_level(runtime.get("level")),
                "targetUrl": runtime.get("target_url", ""),
                "extractScriptUrl": f"/api/schools/{school_id}/script?script_type=provider",
                "title": runtime.get("name", school_id),
                "initialUrl": runtime.get("login_url", ""),
                "systemType": runtime.get("system_type", ""),
                "scriptVersion": runtime.get("script_version", "1.0.0"),
            }
        )
    return entries


def main() -> int:
    if not BUILTIN_PATH.exists():
        print(f"builtin file not found: {BUILTIN_PATH}")
        return 1

    raw = BUILTIN_PATH.read_bytes()
    had_utf8_bom = raw.startswith(BOM_UTF8)
    payload = json.loads(raw.decode("utf-8-sig"))
    existing_data = payload.get("data", [])
    merged: dict[str, dict] = {}

    for item in existing_data:
        school_id = str(item.get("id", "")).strip()
        if school_id:
            merged[school_id] = item

    for item in build_runtime_summary():
        merged[item["id"]] = item

    merged_list = sorted(merged.values(), key=lambda it: str(it.get("title", "")))
    output = {
        "version": str(date.today()),
        "data": merged_list,
    }
    serialized = json.dumps(output, ensure_ascii=False, indent=2) + "\n"
    if had_utf8_bom:
        BUILTIN_PATH.write_bytes(BOM_UTF8 + serialized.encode("utf-8"))
    else:
        BUILTIN_PATH.write_text(serialized, encoding="utf-8")
    print(f"synced builtin entries: {len(merged_list)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
