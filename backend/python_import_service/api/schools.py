from fastapi import APIRouter, HTTPException

from services.school_service import SchoolService


router = APIRouter(tags=["schools"])
school_service = SchoolService()


@router.get("/v1/config/schools")
async def list_schools_v1() -> dict:
    return school_service.list_summary()


@router.get("/v1/config/adapters")
async def list_adapters_v1() -> dict:
    return school_service.build_adapter_rules()


@router.get("/api/schools")
@router.get("/api/schools/")
async def list_schools() -> list[dict]:
    return [
        {
            "id": config.id,
            "name": config.name,
            "system_type": config.system_type,
            "script_version": config.script_version,
        }
        for config in school_service.list_all()
    ]


@router.get("/api/schools/{school_id}/config")
async def get_school_config(school_id: str) -> dict:
    config = school_service.get_config(school_id)
    if config is None:
        raise HTTPException(status_code=404, detail=f"学校 {school_id} 未找到")
    return config.model_dump()


@router.get("/api/schools/{school_id}/script")
async def get_school_script(school_id: str, script_type: str = "provider") -> dict:
    script = school_service.get_script(school_id, script_type)
    config = school_service.get_config(school_id)
    if script is None or config is None:
        raise HTTPException(status_code=404, detail=f"脚本未找到: {school_id}/{script_type}")
    return {
        "script": script,
        "version": config.script_version,
    }