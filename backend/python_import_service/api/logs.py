from fastapi import APIRouter, Request, status
from fastapi.responses import JSONResponse

from models.log import ImportLog
from services.log_service import LogService


router = APIRouter(tags=["logs"])
log_service = LogService()


@router.post("/v1/import/logs")
async def report_import_failure_v1(request: Request) -> JSONResponse:
    payload = await request.json()
    trace_id = str(payload.get("traceId", ""))
    log = ImportLog(
        trace_id=trace_id,
        school_id=str(payload.get("schoolId", "unknown")),
        status="validate_failed" if payload.get("errorCode") else "reported",
        error_code=str(payload.get("errorCode", "")),
        error_message=str(payload.get("message", "")),
        app_version=str(payload.get("appVersion", "")),
        platform=str(payload.get("platform", "")),
    )
    log_service.save(log)
    return JSONResponse(
        status_code=status.HTTP_202_ACCEPTED,
        content={"accepted": True, "traceId": trace_id or "python-import-trace"},
    )


@router.post("/api/import/log")
async def report_log(log: ImportLog) -> dict:
    log_service.save(log)
    return {"received": True}