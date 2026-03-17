# Python Import Service

上课鸭课堂导入链路的 Python/FastAPI 后端，负责学校配置管理、JS 脚本分发、原始课表数据校验与标准化、导入日志持久化。与现有 Flutter 前端的 `/v1` 合同保持兼容，同时提供新的 `/api` 系列接口。

## 架构

```
python_import_service/
├── main.py                  # FastAPI 入口（CORS、异常、路由注册）
├── api/                     # 路由层
│   ├── schools.py           # 学校列表/配置/脚本下载
│   ├── import_handler.py    # 导入校验
│   ├── logs.py              # 日志上报
│   └── release.py           # 版本检查
├── models/                  # Pydantic 领域模型
│   ├── school.py            # SchoolConfig / FieldMapping / TimerConfig 等
│   ├── course.py            # StandardCourse / ImportResult（带校验器）
│   └── log.py               # ImportLog
├── schemas/                 # 请求/响应 Schema
│   └── import_schema.py     # ValidateRequest
├── services/                # 业务逻辑层
│   ├── school_service.py    # 学校配置文件加载与缓存
│   ├── validator_service.py # 字段映射、周次/节次解析、标准化
│   ├── log_service.py       # SQLite 日志持久化
│   └── release_service.py   # 版本比对
├── data/
│   ├── school_configs/      # 学校配置 JSON（如 xjtu.json）
│   └── scripts/             # JS 注入脚本（如 xjtu_provider.js）
└── tests/                   # FastAPI TestClient 测试
    ├── test_schools.py
    └── test_import.py
```

## 运行

```bash
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
pytest tests/ -v
```

当前 6/6 测试通过，覆盖学校列表、配置读取、脚本下载、导入校验成功/失败、日志上报。

当前扩展后，测试已覆盖：

1. 学校接口与脚本读取。
2. 导入校验成功、非法 JSON、空数据与部分坏数据跳过。
3. 周次与节次解析细节。
4. 版本比较与版本检查返回结构。
5. SQLite 日志持久化与样本截断。

新增建议重点测试方向：

1. `ValidatorService` 的周次解析，包括单周/双周/分段范围。
2. 节次解析对 `1-2节`、`3,4`、空值的处理。
3. 半结构化数据在 `data_path` 提取和单条跳过逻辑上的稳定性。

## API 清单

### Flutter 兼容接口（/v1）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/v1/config/schools` | 学校列表（含 level/targetUrl/extractScriptUrl） |
| GET | `/v1/config/adapters` | 适配规则列表（兼容旧前端调用） |
| POST | `/v1/import/logs` | 导入日志上报（traceId/errorCode 语义） |
| GET | `/v1/release/check` | 版本检查（?platform=&currentVersion=） |

### 新接口（/api）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/schools` | 学校列表 |
| GET | `/api/schools/{id}/config` | 学校完整配置（含 field_mapping / timer_config） |
| GET | `/api/schools/{id}/script` | 下载 JS 注入脚本 |
| POST | `/api/import/validate` | 原始 JSON → 标准化课程（核心校验接口） |
| POST | `/api/import/log` | 导入日志上报 |
| GET | `/health` | 健康检查 |

### 导入校验接口详情

**请求** `POST /api/import/validate`
```json
{
  "school_id": "xjtu",
  "raw_data": "[{\"kcmc\":\"高等数学\",\"cdmc\":\"A101\",...}]",
  "year": "2025",
  "term": "first"
}
```
> `raw_data` 为 JSON **字符串**（不是数组对象）

**响应**
```json
{
  "success": true,
  "data": {
    "semester_name": "2025-2026 第first学期",
    "school_id": "xjtu",
    "courses": [
      {
        "name": "高等数学",
        "position": "A101",
        "teacher": "张老师",
        "weeks": [1,2,3,...,16],
        "day": 1,
        "start_section": 1,
        "duration": 2
      }
    ],
    "total_count": 1,
    "valid_count": 1,
    "invalid_count": 0,
    "warnings": []
  }
}
```

## 新增学校

1. 在 `data/school_configs/` 下新建 `{school_id}.json`（参考 `xjtu.json` 格式）
2. 在 `data/scripts/` 下新建对应的 JS 脚本
3. 重启服务即可自动加载

## 为什么 Web 端不能直接完成导入

Python 服务本身可以给 Web 端提供学校列表、配置和校验接口，但 Web 端仍然不能完成真正的课表抓取，原因在于抓取动作发生在浏览器里，而不是后端里。

导入必须先拿到用户登录后的教务数据。当前方案需要前端做到下面至少一项：

1. 在教务页面里执行注入脚本，读取原始 JSON。
2. 读取当前课表页 HTML，回传给 Dart/Python 解析。

在 Web 平台上，`webview_flutter_web` 的实现本质是 iframe。对于跨域教务系统，浏览器同源策略会阻止应用安全地读取 iframe 内部 DOM、Cookie 和登录态，因此即使页面能打开，也无法稳定完成抓取。

这也是为什么当前产品把 Web 端定义为“查看与演示入口”，而把真实导入能力放在 Windows / Android / iOS 客户端。
