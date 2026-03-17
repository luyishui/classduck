import json
from pathlib import Path
import sys

from fastapi.testclient import TestClient


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from main import app


client = TestClient(app)


def test_validate_import_unknown_school_returns_error_payload() -> None:
    response = client.post(
        "/api/import/validate",
        json={
            "school_id": "unknown-school",
            "raw_data": "[]",
            "year": "2025",
            "term": "1",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is False
    assert payload["error_type"] == "ValueError"


def test_validate_import_empty_course_list_returns_error_payload() -> None:
    response = client.post(
        "/api/import/validate",
        json={
            "school_id": "xjtu",
            "raw_data": json.dumps({"kbList": []}, ensure_ascii=False),
            "year": "2025",
            "term": "1",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is False
    assert payload["error_type"] == "ValueError"
    assert "课表数据为空" in payload["error"]