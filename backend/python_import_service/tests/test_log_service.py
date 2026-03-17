from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from models.log import ImportLog
from services.log_service import LogService


def test_save_and_query_recent_log() -> None:
    service = LogService()
    sample = "x" * 600
    log = ImportLog(
        trace_id="pytest-trace",
        school_id="xjtu",
        status="validate_failed",
        error_code="FETCH_FAILED",
        error_message="timeout",
        raw_data_sample=sample,
        app_version="1.0.0",
        platform="windows",
    )

    service.save(log)
    rows = service.query_recent(limit=5)

    assert rows
    latest = rows[0]
    assert latest["trace_id"] == "pytest-trace"
    assert latest["school_id"] == "xjtu"
    assert len(latest["raw_data_sample"]) == 500
