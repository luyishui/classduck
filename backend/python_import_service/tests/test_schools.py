import json
from pathlib import Path
import sys

from fastapi.testclient import TestClient


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from main import app


client = TestClient(app)


def test_list_schools_v1() -> None:
    response = client.get("/v1/config/schools")
    assert response.status_code == 200
    payload = response.json()
    assert "data" in payload
    assert any(item["id"] == "xjtu" for item in payload["data"])


def test_get_school_config() -> None:
    response = client.get("/api/schools/xjtu/config")
    assert response.status_code == 200
    payload = response.json()
    assert payload["id"] == "xjtu"
    assert payload["field_mapping"]["name"] == "kcmc"


def test_get_provider_script() -> None:
    response = client.get("/api/schools/xjtu/script?script_type=provider")
    assert response.status_code == 200
    payload = response.json()
    assert "script" in payload
    assert "fetch(" in payload["script"]