from __future__ import annotations

import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ADAPTER_ROOT = SCRIPT_DIR.parent

REQUIRED_FIELDS = {"id", "level", "title", "import_url"}
VALID_LEVELS = {"undergraduate", "master", "general", "junior"}


def adapter_config_paths() -> list[Path]:
    return sorted(
        [
            * (ADAPTER_ROOT / "undergraduate" / "schools").glob("*.json"),
            * (ADAPTER_ROOT / "master" / "schools").glob("*.json"),
            * (ADAPTER_ROOT / "general" / "systems").glob("*.json"),
        ]
    )


def validate_config(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - defensive parse branch
        return [f"invalid json: {exc}"]

    missing = [k for k in sorted(REQUIRED_FIELDS) if k not in data]
    if missing:
        errors.append(f"missing required fields: {', '.join(missing)}")

    level = str(data.get("level", "")).strip().lower()
    if level not in VALID_LEVELS:
        errors.append(f"invalid level: {level}")

    school_id = str(data.get("id", "")).strip()
    if school_id and path.stem != school_id:
        errors.append(f"filename mismatch: expected {school_id}.json")

    return errors


def main() -> int:
    has_error = False
    for path in adapter_config_paths():
        errors = validate_config(path)
        if errors:
            has_error = True
            print(f"[FAIL] {path.relative_to(ADAPTER_ROOT)}")
            for err in errors:
                print(f"  - {err}")
        else:
            print(f"[OK]   {path.relative_to(ADAPTER_ROOT)}")

    if has_error:
        return 1

    print("adapter validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
