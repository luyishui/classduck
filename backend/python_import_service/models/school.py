from pydantic import BaseModel, Field


class FetchConfig(BaseModel):
    url: str
    method: str = "POST"
    headers: dict[str, str] = Field(default_factory=dict)
    body_template: str = ""
    credentials: str = "include"


class TermMapping(BaseModel):
    first: str
    second: str
    short: str = ""


class FieldMapping(BaseModel):
    name: str
    position: str
    teacher: str
    weeks: str
    day: str
    sections: str


class SectionTime(BaseModel):
    section: int
    start_time: str
    end_time: str


class TimerConfig(BaseModel):
    total_week: int
    start_semester: str
    start_with_sunday: bool = False
    forenoon: int = 5
    afternoon: int = 4
    night: int = 3
    sections: list[SectionTime] = Field(default_factory=list)


class SchoolConfig(BaseModel):
    id: str
    name: str
    level: str = "general"
    system_type: str
    login_url: str
    target_url: str = ""
    fetch_config: FetchConfig
    term_mapping: TermMapping
    data_path: str = ""
    field_mapping: FieldMapping
    timer_config: TimerConfig
    script_version: str = "1.0.0"
    pre_extract_delay: int = 0
    notes: str = ""