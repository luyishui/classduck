from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from services.release_service import compare_versions, check_release


def test_compare_versions_handles_different_segment_lengths() -> None:
    assert compare_versions("1.2", "1.2.0") == 0
    assert compare_versions("1.2.1", "1.2.0") == 1
    assert compare_versions("1.1.9", "1.2") == -1


def test_check_release_returns_platform_specific_url() -> None:
    payload = check_release("0.0.1", "android")

    assert payload["hasNewVersion"] is True
    assert "latestVersion" in payload
    assert "updateUrl" in payload
