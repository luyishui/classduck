from fastapi import APIRouter

from schemas.import_schema import ValidateRequest
from services.validator_service import ValidatorService


router = APIRouter(tags=["import"])
validator_service = ValidatorService()


@router.post("/api/import/validate")
async def validate_and_parse(req: ValidateRequest) -> dict:
    try:
        result = validator_service.validate_and_parse(
            school_id=req.school_id,
            raw_data=req.raw_data,
            year=req.year,
            term=req.term,
        )
        return {"success": True, "data": result.model_dump()}
    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
            "error_type": type(exc).__name__,
        }