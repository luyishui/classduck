# Backend — 上课鸭后端服务

## 概述
本目录托管上课鸭（ClassDuck）的后端服务，当前仅保留 **Python FastAPI** 服务。

> 历史说明：早期曾存在 Node.js Express 后端（端口 3100），已在版本合并中移除，所有功能已迁移至 Python 服务。

## 目录结构

```
backend/
├── python_import_service/   # FastAPI 主服务（端口 8000）
│   ├── main.py              # 入口：CORS、异常处理、路由注册
│   ├── api/                 # 路由层（schools / import / logs / release）
│   ├── models/              # Pydantic 领域模型
│   ├── schemas/             # 请求/响应 Schema
│   ├── services/            # 业务逻辑层
│   ├── data/                # 学校配置 JSON + JS 注入脚本
│   └── tests/               # FastAPI TestClient 测试
├── runtime/
│   └── import-logs.ndjson   # 导入日志持久化文件
└── README.md                # 本文件
```

## 核心功能
| 模块 | 说明 |
|------|------|
| 学校配置服务 | 学校列表、字段映射、JS 脚本分发 |
| 导入校验服务 | 原始课表数据标准化与校验 |
| 日志上报服务 | 导入失败诊断日志持久化（SQLite / NDJSON） |
| 版本发布服务 | 版本比对与 Feature Flag |

## 快速启动

```bash
cd backend/python_import_service

# 创建虚拟环境
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux

# 安装依赖
pip install -r requirements.txt

# 启动（开发模式）
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 测试

```bash
cd backend/python_import_service
pytest tests/ -v
```

## 规则
1. 前后端逻辑严格分离
2. 所有外部 API 契约须在 `../contracts/` 中定义
3. API 变更须先更新契约和版本说明
