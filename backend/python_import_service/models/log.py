from datetime import datetime

from pydantic import BaseModel, Field


class ImportLog(BaseModel):
    trace_id: str = ""
    school_id: str
    device_id: str = ""
    status: str
    error_code: str = ""
    error_message: str = ""
    error_detail: str = ""
    course_count: int = 0
    raw_data_sample: str = ""
    app_version: str = ""
    platform: str = ""
    occurred_at: datetime | None = None
    timestamp: datetime = Field(default_factory=datetime.now)