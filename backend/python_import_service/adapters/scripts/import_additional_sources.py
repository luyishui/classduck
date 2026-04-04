from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent
SERVICE_ROOT = ADAPTER_ROOT.parent
WORKSPACE_ROOT = SERVICE_ROOT.parent.parent

CLASS_SOURCE = "class_schedule_flutter"
AIS_SOURCE = "aishedule_master"

CLASS_ROOT = WORKSPACE_ROOT / "参考文件" / "Class-Shedule-Flutter"
CLASS_SCHOOL_LIST = CLASS_ROOT / "api" / "schoolList.json"
CLASS_TOOLS_DIR = CLASS_ROOT / "api" / "tools"

AIS_ROOT = WORKSPACE_ROOT / "参考文件" / "aishedule-master"
AIS_IGNORE_DIRS = {"node_modules", "localTools", ".git", ".vscode"}

CLASS_MASTER_PINYIN = {
    "1nanjingdaxueyanjiujiaowu",
    "1nanjingdaxueyanjiuxuanke",
    "shanghaijiaotongdaxueyanjiu",
    "zhongguorenmindaxuejiaowu",
}

FOCUS_AI_SCHOOLS = {"武汉大学", "山东大学", "郑州大学", "哈尔滨工业大学"}
FOCUS_AI_IDS = {
    "武汉大学": "ais_whu",
    "山东大学": "ais_sdu",
    "郑州大学": "ais_zzu",
    "哈尔滨工业大学": "ais_hit",
}

GENERIC_PATH_PARTS = {
    "iframe强智",
    "新正方教务",
    "旧版",
    "新版",
    "正常版本",
    "版本一",
    "版本二",
    "版本三",
    "版本四",
    "本部",
    "辅修-班级",
    "辅修-班级provider",
    "测试",
}

SCHOOL_NOISE_TOKENS = [
    "教务系统",
    "教务",
    "系统",
    "适配",
    "课表",
    "课程表",
    "教育信息",
    "信息系统",
    "本科生",
    "本科",
    "研究生",
    "本研",
    "选课",
    "导入",
    "beta",
    "test",
    "新版",
    "旧版",
    "本部",
    "分校",
    "校区",
]


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


def all_config_dirs() -> list[Path]:
    return [
        ADAPTER_ROOT / "undergraduate" / "schools",
        ADAPTER_ROOT / "master" / "schools",
        ADAPTER_ROOT / "general" / "systems",
    ]


def all_script_dirs() -> list[Path]:
    return [
        ADAPTER_ROOT / "undergraduate" / "scripts",
        ADAPTER_ROOT / "master" / "scripts",
        ADAPTER_ROOT / "general" / "scripts",
    ]


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


def hash_suffix(text: str, length: int = 8) -> str:
    return hashlib.md5(text.encode("utf-8")).hexdigest()[:length]


def read_text_with_fallback(path: Path) -> str:
    for encoding in ("utf-8", "utf-8-sig", "gb18030", "gbk"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    return path.read_text(encoding="utf-8", errors="ignore")


def normalize_school_name(raw: str) -> str:
    value = raw.strip().lower()
    value = re.sub(r"[（(][^）)]*[）)]", "", value)
    for token in SCHOOL_NOISE_TOKENS:
        value = value.replace(token, "")
    value = re.sub(r"[^0-9a-z\u4e00-\u9fff]+", "", value)
    return value


def default_runtime_payload(
    school_id: str,
    title: str,
    level: str,
    import_url: str,
    target_url: str,
    system_type: str,
    delay_seconds: int,
    notes: str,
) -> dict:
    return {
        "id": school_id,
        "name": title,
        "level": level,
        "system_type": system_type,
        "login_url": import_url,
        "target_url": target_url,
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
        "pre_extract_delay": delay_seconds,
        "notes": notes,
    }


def extract_first_url(text: str) -> str:
    match = re.search(r"https?://[^\s\"'`<>]+", text)
    if not match:
        return ""
    return match.group(0).rstrip("),.;\"'")


def infer_school_name(parts: tuple[str, ...]) -> str:
    if len(parts) < 2:
        return "unknown_school"

    candidates = list(parts[1:-1])
    for part in reversed(candidates):
        text = part.strip()
        if not text or text in GENERIC_PATH_PARTS:
            continue
        if re.search(r"(大学|学院|学校|职业|技术|中医药)", text):
            return text

    for part in reversed(candidates):
        text = part.strip()
        if text and text not in GENERIC_PATH_PARTS:
            return text

    return (candidates[-1] if candidates else "unknown_school").strip() or "unknown_school"


def find_peer_script(parent: Path, script_name: str) -> Path | None:
    lower_name = script_name.lower()
    for child in parent.iterdir():
        if child.is_file() and child.name.lower() == lower_name:
            return child
    return None


def remove_existing_config_by_id(school_id: str) -> None:
    for config_dir in all_config_dirs():
        (config_dir / f"{school_id}.json").unlink(missing_ok=True)


def remove_existing_script_by_id(school_id: str) -> None:
    script_name = f"{school_id}_provider.js"
    for script_dir in all_script_dirs():
        (script_dir / script_name).unlink(missing_ok=True)


def write_adapter_and_script(
    school_id: str,
    level: str,
    payload: dict,
    script_content: str | None,
) -> None:
    config_dir, script_dir = target_paths(level)
    config_dir.mkdir(parents=True, exist_ok=True)
    script_dir.mkdir(parents=True, exist_ok=True)

    remove_existing_config_by_id(school_id)
    remove_existing_script_by_id(school_id)

    target_config = config_dir / f"{school_id}.json"
    target_config.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if script_content is not None:
        target_script = script_dir / f"{school_id}_provider.js"
        target_script.write_text(script_content, encoding="utf-8")


def load_existing_state() -> tuple[dict[tuple[str, str], str], set[str], set[str]]:
    origin_map: dict[tuple[str, str], str] = {}
    used_ids: set[str] = set()
    normalized_titles: set[str] = set()

    for config_path in adapter_config_paths():
        try:
            payload = json.loads(config_path.read_text(encoding="utf-8"))
        except Exception:
            continue

        school_id = str(payload.get("id", "")).strip()
        if not school_id:
            continue

        used_ids.add(school_id)

        title = str(payload.get("title") or school_id)
        normalized = normalize_school_name(title)
        if normalized:
            normalized_titles.add(normalized)

        source = str(payload.get("source") or "").strip()
        source_path = str(payload.get("source_path") or "").strip()
        source_adapter_id = str(payload.get("source_adapter_id") or "").strip()
        if source in {CLASS_SOURCE, AIS_SOURCE} and source_path:
            origin_map[(source_path, source_adapter_id)] = school_id

    return origin_map, used_ids, normalized_titles


def remove_existing_entries_by_source(sources: set[str]) -> int:
    removed = 0
    for config_path in adapter_config_paths():
        try:
            payload = json.loads(config_path.read_text(encoding="utf-8"))
        except Exception:
            continue

        source = str(payload.get("source") or "").strip()
        if source not in sources:
            continue

        school_id = str(payload.get("id") or "").strip()
        config_path.unlink(missing_ok=True)
        if school_id:
            remove_existing_script_by_id(school_id)
        removed += 1

    return removed


def import_class_schedule(
    origin_map: dict[tuple[str, str], str],
    used_ids: set[str],
    normalized_titles: set[str],
) -> tuple[int, list[str]]:
    if not CLASS_SCHOOL_LIST.exists():
        print("skip class schedule import: schoolList.json not found")
        return 0, []

    payload = json.loads(CLASS_SCHOOL_LIST.read_text(encoding="utf-8"))
    entries = payload.get("data") if isinstance(payload, dict) else []
    if not isinstance(entries, list):
        print("skip class schedule import: invalid schoolList.json")
        return 0, []

    imported = 0
    missing_scripts: list[str] = []

    for index, entry in enumerate(entries, start=1):
        if not isinstance(entry, dict):
            continue

        title = str(entry.get("title") or "").strip() or f"ClassSchedule School {index}"
        pinyin = str(entry.get("pinyin") or "").strip() or f"entry_{index}"
        source_path = f"参考文件/Class-Shedule-Flutter/api/schoolList.json#{pinyin}"
        origin_key = (source_path, pinyin)

        if pinyin in CLASS_MASTER_PINYIN or "研究生" in title:
            level = "master"
        else:
            level = "undergraduate"

        if origin_key in origin_map:
            school_id = origin_map[origin_key]
        else:
            base = sanitize_school_id(f"csf_{pinyin}")
            school_id = unique_school_id(base, used_ids)

        used_ids.add(school_id)

        delay_seconds = int(entry.get("delayTime") or 0)
        import_url = str(entry.get("initialUrl") or "")
        target_url = str(entry.get("targetUrl") or "")

        notes = f"Imported from Class-Shedule-Flutter ({pinyin})"
        runtime = default_runtime_payload(
            school_id=school_id,
            title=title,
            level=level,
            import_url=import_url,
            target_url=target_url,
            system_type="class_schedule_flutter",
            delay_seconds=delay_seconds,
            notes=notes,
        )

        class_time_list = entry.get("class_time_list")
        if isinstance(class_time_list, list):
            sections: list[dict] = []
            for section_index, section in enumerate(class_time_list, start=1):
                if not isinstance(section, dict):
                    continue
                start = str(section.get("start") or "").strip()
                end = str(section.get("end") or "").strip()
                if start and end:
                    sections.append(
                        {
                            "section": section_index,
                            "start_time": start,
                            "end_time": end,
                        }
                    )
            runtime["timer_config"]["sections"] = sections

        semester_start = str(entry.get("semester_start_monday") or "").strip()
        if semester_start:
            runtime["timer_config"]["start_semester"] = semester_start

        script_url = (
            str(entry.get("extractJSfileAndroid") or "").strip()
            or str(entry.get("extractJSfileiOS") or "").strip()
            or str(entry.get("extractJSfileOHOS") or "").strip()
        )
        script_name = Path(script_url).name if script_url else ""
        source_script_path = CLASS_TOOLS_DIR / script_name if script_name else None
        script_content: str | None = None
        if source_script_path and source_script_path.exists():
            script_content = read_text_with_fallback(source_script_path)
        else:
            missing_scripts.append(source_path)

        adapter_payload = {
            "id": school_id,
            "level": level,
            "title": title,
            "import_url": import_url,
            "target_url": target_url,
            "system_type": "class_schedule_flutter",
            "delay_seconds": delay_seconds,
            "source": CLASS_SOURCE,
            "source_path": source_path,
            "source_adapter_id": pinyin,
            "resource_folder": "api/tools",
            "license": "Apache-2.0",
            "maintainer": "idealclover",
            "asset_js_path": script_name,
            "runtime": runtime,
        }

        write_adapter_and_script(
            school_id=school_id,
            level=level,
            payload=adapter_payload,
            script_content=script_content,
        )

        normalized = normalize_school_name(title)
        if normalized:
            normalized_titles.add(normalized)
        imported += 1

    return imported, missing_scripts


def import_aishedule(
    origin_map: dict[tuple[str, str], str],
    used_ids: set[str],
    normalized_titles: set[str],
) -> tuple[int, int, list[str]]:
    if not AIS_ROOT.exists():
        print("skip ai schedule import: aishedule root not found")
        return 0, 0, sorted(FOCUS_AI_SCHOOLS)

    provider_files: list[Path] = []
    for path in AIS_ROOT.rglob("*"):
        if not path.is_file() or path.name.lower() != "provider.js":
            continue
        rel = path.relative_to(AIS_ROOT)
        if any(part in AIS_IGNORE_DIRS for part in rel.parts):
            continue
        provider_files.append(path)

    provider_files.sort()

    imported = 0
    skipped_duplicates = 0
    focus_imported: set[str] = set()
    seen_ai_names: set[str] = set()

    for provider_path in provider_files:
        rel = provider_path.relative_to(AIS_ROOT)
        school_name = infer_school_name(rel.parts)
        normalized_school = normalize_school_name(school_name)
        if not normalized_school:
            continue

        is_focus = school_name in FOCUS_AI_SCHOOLS
        if normalized_school in normalized_titles and not is_focus:
            skipped_duplicates += 1
            continue
        if normalized_school in seen_ai_names and not is_focus:
            skipped_duplicates += 1
            continue

        rel_path = rel.as_posix()
        source_path = f"参考文件/aishedule-master/{rel_path}"
        source_adapter_id = school_name
        origin_key = (source_path, source_adapter_id)

        if "研究生" in rel_path or "研究生" in school_name:
            level = "master"
        else:
            level = "undergraduate"

        if origin_key in origin_map:
            school_id = origin_map[origin_key]
        else:
            base = FOCUS_AI_IDS.get(school_name)
            if not base:
                system_slug = sanitize_school_id(rel.parts[0])
                if system_slug == "adapter":
                    system_slug = "system"
                base = f"ais_{system_slug}_{hash_suffix(school_name, 6)}"
            school_id = unique_school_id(base, used_ids)

        used_ids.add(school_id)
        normalized_titles.add(normalized_school)
        seen_ai_names.add(normalized_school)

        provider_content = read_text_with_fallback(provider_path)
        parser_path = find_peer_script(provider_path.parent, "parser.js")
        timer_path = find_peer_script(provider_path.parent, "timer.js")
        parser_content = read_text_with_fallback(parser_path) if parser_path else ""
        timer_content = read_text_with_fallback(timer_path) if timer_path else ""

        merged_parts: list[str] = [
            f"// Source: {source_path}",
            provider_content.strip(),
        ]
        if parser_content.strip():
            merged_parts.append("// Merged parser.js")
            merged_parts.append(parser_content.strip())
        if timer_content.strip():
            merged_parts.append("// Merged timer.js")
            merged_parts.append(timer_content.strip())
        merged_script = "\n\n".join(part for part in merged_parts if part) + "\n"

        import_url = extract_first_url(provider_content)
        if not import_url and parser_content:
            import_url = extract_first_url(parser_content)
        if not import_url and timer_content:
            import_url = extract_first_url(timer_content)

        title = f"{school_name}（AIShedule）"
        notes = f"Imported from AIShedule ({rel_path})"
        runtime = default_runtime_payload(
            school_id=school_id,
            title=title,
            level=level,
            import_url=import_url,
            target_url="",
            system_type=str(rel.parts[0]),
            delay_seconds=0,
            notes=notes,
        )

        adapter_payload = {
            "id": school_id,
            "level": level,
            "title": title,
            "import_url": import_url,
            "target_url": "",
            "system_type": str(rel.parts[0]),
            "delay_seconds": 0,
            "source": AIS_SOURCE,
            "source_path": source_path,
            "source_adapter_id": source_adapter_id,
            "resource_folder": str(rel.parts[0]),
            "license": "MIT",
            "maintainer": "xiaoxiao",
            "asset_js_path": rel.name,
            "runtime": runtime,
        }

        write_adapter_and_script(
            school_id=school_id,
            level=level,
            payload=adapter_payload,
            script_content=merged_script,
        )

        if is_focus:
            focus_imported.add(school_name)
        imported += 1

    missing_focus = sorted(FOCUS_AI_SCHOOLS - focus_imported)
    return imported, skipped_duplicates, missing_focus


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import additional adapters from Class-Shedule-Flutter and AIShedule"
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="remove previously imported entries from class_schedule_flutter and aishedule_master first",
    )
    args = parser.parse_args()

    if args.clean:
        removed = remove_existing_entries_by_source({CLASS_SOURCE, AIS_SOURCE})
        print(f"cleaned previous class/ai adapters: {removed}")

    origin_map, used_ids, normalized_titles = load_existing_state()

    class_imported, class_missing_scripts = import_class_schedule(
        origin_map=origin_map,
        used_ids=used_ids,
        normalized_titles=normalized_titles,
    )
    print(f"imported class schedule adapters: {class_imported}")
    if class_missing_scripts:
        print(f"class schedule missing scripts: {len(class_missing_scripts)}")
        for item in class_missing_scripts:
            print(f"  - {item}")

    origin_map, used_ids, normalized_titles = load_existing_state()
    ai_imported, ai_skipped_duplicates, ai_missing_focus = import_aishedule(
        origin_map=origin_map,
        used_ids=used_ids,
        normalized_titles=normalized_titles,
    )
    print(f"imported ai schedule adapters: {ai_imported}")
    print(f"skipped ai schedule duplicates: {ai_skipped_duplicates}")
    if ai_missing_focus:
        print("ai focus schools not imported:")
        for item in ai_missing_focus:
            print(f"  - {item}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
