"""
上课鸭 Python 导入后端 —— FastAPI 入口模块

【设计思路】
本模块是整个后端的入口和组装点，职责包括：
1. 创建 FastAPI 应用实例并注册元信息（标题、描述、版本）。
2. 注册 CORS 中间件——因为 Flutter Web 端 / 调试工具会跨域访问，
   开发阶段允许全部来源（生产部署应收紧 allow_origins）。
3. 挂载四个功能路由模块：
   - schools：学校配置列表 / 详情 / JS 脚本下载
   - import_handler：原始 JSON → 标准化课程的校验接口
   - logs：导入日志上报（兼容 /v1 旧格式和 /api 新格式）
   - release：版本检查
4. 提供 /health 端点供容器探活或 Flutter 端连通性测试。
5. 全局异常处理：所有未捕获异常统一返回 500 + traceId + errorCode，
   保证前端总能拿到结构化错误，不会收到 HTML 500 页。

【启动方式】
  uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from api import import_handler, logs, release, schools


app = FastAPI(
    title="ClassDuck Python Import Service",
    description="课表导入配置、脚本下发、数据校验与日志收集服务",
    version="1.0.0",
)

# CORS 中间件：开发阶段允许全部来源，生产环境应收紧为实际前端域名。
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 按功能领域挂载路由，每个 router 在自己的模块里声明 path 和 tag。
app.include_router(schools.router)
app.include_router(import_handler.router)
app.include_router(logs.router)
app.include_router(release.router)


@app.get("/")
async def root() -> dict[str, str]:
    """根路径信息——方便浏览器直接访问时确认服务版本。"""
    return {"service": "ClassDuck Python Import Service", "version": "1.0.0"}


@app.get("/health")
@app.get("/healthz")
async def health() -> dict[str, str]:
    """健康检查——容器编排和 Flutter 端用来判断后端是否在线。"""
    return {"status": "ok"}


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    全局异常兜底：所有未被路由层自行处理的异常在这里统一转换为
    结构化 JSON 500 响应，包含 traceId（优先从请求头取）和 errorCode。
    这样前端不会因为后端 bug 收到非 JSON 内容而 crash。
    """
    return JSONResponse(
        status_code=500,
        content={
            "traceId": request.headers.get("x-trace-id", "python-import-service"),
            "errorCode": "INTERNAL_SERVER_ERROR",
            "message": str(exc),
        },
    )


if __name__ == "__main__":
    # 兼容直接运行 `python main.py` 的开发习惯，避免服务未起导致连接拒绝。
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)