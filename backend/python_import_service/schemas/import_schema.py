from pydantic import BaseModel


class ValidateRequest(BaseModel):
    school_id: str
    raw_data: str
    year: str = ""
    term: str = ""