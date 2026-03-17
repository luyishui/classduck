import sqlite3
from pathlib import Path

from models.log import ImportLog


DB_PATH = Path(__file__).resolve().parent.parent / "data" / "db" / "logs.db"


class LogService:
    def __init__(self) -> None:
        DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self) -> None:
        with sqlite3.connect(str(DB_PATH)) as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS import_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    trace_id TEXT DEFAULT '',
                    school_id TEXT NOT NULL,
                    device_id TEXT DEFAULT '',
                    status TEXT NOT NULL,
                    error_code TEXT DEFAULT '',
                    error_message TEXT DEFAULT '',
                    error_detail TEXT DEFAULT '',
                    course_count INTEGER DEFAULT 0,
                    raw_data_sample TEXT DEFAULT '',
                    app_version TEXT DEFAULT '',
                    platform TEXT DEFAULT '',
                    occurred_at TEXT DEFAULT '',
                    timestamp TEXT NOT NULL
                )
                """
            )

    def save(self, log: ImportLog) -> None:
        with sqlite3.connect(str(DB_PATH)) as conn:
            conn.execute(
                """
                INSERT INTO import_logs (
                    trace_id, school_id, device_id, status, error_code, error_message,
                    error_detail, course_count, raw_data_sample, app_version, platform,
                    occurred_at, timestamp
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    log.trace_id,
                    log.school_id,
                    log.device_id,
                    log.status,
                    log.error_code,
                    log.error_message,
                    log.error_detail,
                    log.course_count,
                    log.raw_data_sample[:500],
                    log.app_version,
                    log.platform,
                    log.occurred_at.isoformat() if log.occurred_at else "",
                    log.timestamp.isoformat(),
                ),
            )

    def query_recent(self, limit: int = 100) -> list[dict[str, str]]:
        with sqlite3.connect(str(DB_PATH)) as conn:
            cursor = conn.execute(
                "SELECT * FROM import_logs ORDER BY id DESC LIMIT ?",
                (limit,),
            )
            columns = [description[0] for description in cursor.description]
            return [dict(zip(columns, row)) for row in cursor.fetchall()]