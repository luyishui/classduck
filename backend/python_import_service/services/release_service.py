from pathlib import Path
import json


RELEASE_FILE = Path(__file__).resolve().parent.parent / "data" / "release.sample.json"


def compare_versions(a: str, b: str) -> int:
    a_parts = [int(part) if part.isdigit() else 0 for part in str(a).split(".")]
    b_parts = [int(part) if part.isdigit() else 0 for part in str(b).split(".")]
    max_len = max(len(a_parts), len(b_parts))
    for index in range(max_len):
        left = a_parts[index] if index < len(a_parts) else 0
        right = b_parts[index] if index < len(b_parts) else 0
        if left > right:
            return 1
        if left < right:
            return -1
    return 0


def load_release_info() -> dict:
    if not RELEASE_FILE.exists():
        return {
            "latestVersion": "0.0.0",
            "androidStoreUrl": "",
            "iosStoreUrl": "",
            "releaseNotes": [],
        }
    return json.loads(RELEASE_FILE.read_text(encoding="utf-8"))


def check_release(current_version: str, platform: str) -> dict:
    release = load_release_info()
    latest_version = str(release.get("latestVersion", "0.0.0"))
    cmp = compare_versions(current_version, latest_version)
    return {
        "hasNewVersion": cmp < 0,
        "latestVersion": latest_version,
        "currentVersion": current_version,
        "updateUrl": release.get("iosStoreUrl", "") if platform == "ios" else release.get("androidStoreUrl", ""),
        "releaseNotes": "\n".join(release.get("releaseNotes", [])),
    }