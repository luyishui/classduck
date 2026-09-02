# 上课鸭 ClassDuck

上课鸭是一款面向校园场景的课表应用：支持 **AI 截图导入**与教务网页导入、**多课表管理**、**上课提醒**与**待办联动**，数据全部存储在本地，轻量、免费、无广告。

- 下载页面：<https://luyishui.github.io/classduck/>
- 源码仓库：<https://github.com/luyishui/classduck>
- 当前平台：Android（iOS / HarmonyOS 筹备中）

## 功能特性

- **多课表管理**：多学期课表独立管理，周次、节次语义清晰，课程颜色自动区分，长按拖动调整课程布局与周数范围。
- **AI 截图导入**：把课表截图发给 AI（豆包专家模式），复制返回的 JSON 粘贴回来即可导入，无需逐条手打课程。
- **教务网页导入**：WebView 打开教务系统，登录后自动抓取并标准化课表数据（按学校适配脚本）。
- **上课提醒**：课程开始前准时提醒，提醒时间可自定义，也可按课程单独设置。
- **待办联动**：作业、考试、会议随手记下，与课表时间线并列展示。
- **深色模式**：浅色/深色两套外观，跟随系统或手动切换。

## 下载与更新

Android 安装包发布在 [GitHub Releases](https://github.com/luyishui/classduck/releases)，下载页会自动同步最新版本信息：

- 通用版 APK：包含全部 CPU 架构，适配主流机型
- arm64 高性能版：体积更小、启动更快
- 镜像下载：国内网络加速通道

应用内"版本更新"入口会检查最新版本，发现新版后引导到下载页更新。

## 技术架构

| 模块 | 说明 |
| --- | --- |
| `classduck_app/` | Flutter 客户端（Android / iOS / 桌面 / Web），SQLite 本地存储 |
| `backend/python_import_service/` | Python FastAPI 导入服务：学校配置、导入标准化、日志上报、版本检查 |
| `backend/src/` | 旧 Node.js（Express）服务，过渡参考 |
| `contracts/` | 前后端契约（OpenAPI / JSON Schema / 变更记录） |
| `docs/` | GitHub Pages 下载页与静态版本信息（release.json） |
| `.github/workflows/` | Android 打包发布流水线 |

## 仓库结构

```text
classduck/
├── classduck_app/                # Flutter 客户端主工程
├── backend/
│   ├── python_import_service/    # 主力后端（FastAPI）
│   └── src/                      # 旧 Node.js 服务（过渡）
├── contracts/                    # 契约与 schema
├── docs/                         # 下载页 + release.json
├── deploy/                       # 部署模板与说明
└── .github/workflows/            # 打包发布 CI
```

## 本地开发

### 启动 Python 导入服务

```bash
cd backend/python_import_service
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

- 健康检查：`http://localhost:8000/health`
- 接口文档：`http://localhost:8000/docs`

### 启动 Flutter 客户端

```bash
cd classduck_app
flutter pub get
flutter run -d <windows | chrome | android设备id>
```

### 运行测试

```bash
# Python 后端
cd backend/python_import_service && pytest tests/ -v

# Flutter 客户端
cd classduck_app && flutter test
```