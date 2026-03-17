import json
from pathlib import Path
import sys

from fastapi.testclient import TestClient


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from main import app


client = TestClient(app)
SAMPLE_FILE = Path(__file__).resolve().parent / "test_data" / "sample_schedule.json"


def test_validate_import_success() -> None:
    raw_data = SAMPLE_FILE.read_text(encoding="utf-8")
    response = client.post(
        "/api/import/validate",
        json={
            "school_id": "xjtu",
            "raw_data": raw_data,
            "year": "2025",
            "term": "1",
        },
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert payload["data"]["valid_count"] == 2
    assert payload["data"]["invalid_count"] == 0


def test_validate_import_invalid_json() -> None:
    response = client.post(
        "/api/import/validate",
        json={
            "school_id": "xjtu",
            "raw_data": "{bad json",
            "year": "2025",
            "term": "1",
        },
    )
    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is False
    assert payload["error_type"] == "ValueError"


def test_report_log_v1() -> None:
    response = client.post(
        "/v1/import/logs",
        json={
            "traceId": "flutter-123",
            "schoolId": "xjtu",
            "errorCode": "FETCH_FAILED",
            "message": "timeout",
            "appVersion": "1.0.0",
            "platform": "windows",
            "occurredAt": "2026-03-17T00:00:00Z"
        },
    )
    assert response.status_code == 202
    payload = response.json()
    assert payload["accepted"] is True
    assert payload["traceId"] == "flutter-123"