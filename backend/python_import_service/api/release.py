from fastapi import APIRouter, Request

from services.release_service import check_release


router = APIRouter(tags=["release"])


@router.get("/v1/release/check")
async def release_check(currentVersion: str, platform: str, request: Request) -> dict:
    return {
        "traceId": request.headers.get("x-trace-id", "python-import-service"),
        "data": check_release(currentVersion, platform),
    }