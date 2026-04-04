"""
学校配置服务

【设计思路】
从 data/school_configs/*.json 文件加载学校配置到内存缓存，
从 data/scripts/*.js 读取对应的 JS 注入脚本。

配置通过文件驱动：新增学校只需添加一个 JSON + 一个 JS 文件，无需改代码。
服务启动时一次性加载所有配置到内存（SchoolConfig Pydantic 模型），
后续请求直接从缓存读取，避免每次 IO。

兼容层：
- list_summary() 返回 /v1/config/schools 兼容格式（Flutter 旧版调用）
- build_adapter_rules() 返回 /v1/config/adapters 兼容格式
"""

import json
from pathlib import Path
from typing import Any

from models.school import SchoolConfig


BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
CONFIG_DIR = DATA_DIR / "school_configs"
SCRIPT_DIR = DATA_DIR / "scripts"


class SchoolService:
    def __init__(self) -> None:
        self._cache: dict[str, SchoolConfig] = {}
        self._load_all()

    def _load_all(self) -> None:
        """从磁盘加载全部学校配置到内存缓存。"""
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        for file_path in CONFIG_DIR.glob("*.json"):
            with file_path.open("r", encoding="utf-8") as fp:
                data = json.load(fp)
            config = SchoolConfig(**data)
            self._cache[config.id] = config

    def reload(self) -> None:
        """热重载配置文件，用于开发阶段调试新增学校配置。"""
        self._cache.clear()
        self._load_all()

    def list_all(self) -> list[SchoolConfig]:
        """返回按学校名称排序后的全部配置。"""
        return sorted(self._cache.values(), key=lambda item: item.name)

    def list_summary(self) -> dict[str, Any]:
        def normalize_level(raw_level: str) -> str:
            level = (raw_level or "").strip().lower()
            if level == "junior":
                return "undergraduate"
            if level in {"undergraduate", "master", "general"}:
                return level
            return "general"

        return {
            "version": "2026-03-17",
            "data": [
                {
                    "id": config.id,
                    "delaySeconds": config.pre_extract_delay,
                    "level": normalize_level(config.level),
                    "targetUrl": config.target_url,
                    "extractScriptUrl": f"/api/schools/{config.id}/script?script_type=provider",
                    "title": config.name,
                    "initialUrl": config.login_url,
                    "systemType": config.system_type,
                    "scriptVersion": config.script_version,
                }
                for config in self.list_all()
            ],
        }

    def get_config(self, school_id: str) -> SchoolConfig | None:
        """按 school_id 获取单个学校配置。"""
        return self._cache.get(school_id)

    def get_script(self, school_id: str, script_type: str = "provider") -> str | None:
        """读取学校对应的脚本文件内容。"""
        script_path = SCRIPT_DIR / f"{school_id}_{script_type}.js"
        if not script_path.exists():
            return None
        return script_path.read_text(encoding="utf-8")

    def build_adapter_rules(self) -> dict[str, Any]:
        rules: list[dict[str, Any]] = []
        for config in self.list_all():
            rules.append(
                {
                    "adapterId": config.id,
                    "name": f"{config.name} 适配器",
                    "match": {
                        "hostIncludes": [config.login_url.split("//")[-1].split("/")[0]],
                        "pathIncludes": ["/"],
                    },
                    "extract": {
                        "scriptUrl": f"/api/schools/{config.id}/script?script_type=provider",
                        "delaySeconds": config.pre_extract_delay,
                        "needsLogin": True,
                    },
                }
            )
        return {"version": "2026-03-17", "rules": rules}