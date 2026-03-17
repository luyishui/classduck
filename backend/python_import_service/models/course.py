from pydantic import BaseModel, Field, field_validator


class StandardCourse(BaseModel):
    name: str
    position: str = ""
    teacher: str = ""
    weeks: list[int] = Field(default_factory=list)
    day: int
    start_section: int
    duration: int

    @field_validator("day")
    @classmethod
    def validate_day(cls, value: int) -> int:
        if value < 1 or value > 7:
            raise ValueError(f"星期必须在1-7之间，收到: {value}")
        return value

    @field_validator("weeks")
    @classmethod
    def validate_weeks(cls, value: list[int]) -> list[int]:
        return [week for week in value if 1 <= week <= 30]

    @field_validator("start_section")
    @classmethod
    def validate_section(cls, value: int) -> int:
        if value < 1 or value > 15:
            raise ValueError(f"节次必须在1-15之间，收到: {value}")
        return value


class ImportResult(BaseModel):
    semester_name: str = ""
    school_id: str = ""
    courses: list[StandardCourse] = Field(default_factory=list)
    total_count: int = 0
    valid_count: int = 0
    invalid_count: int = 0
    warnings: list[str] = Field(default_factory=list)