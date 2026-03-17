# ClassDuck Flutter App

上课鸭前端应用，负责课程表、待办、我的三大主页面，以及教务导入链路的 UI、数据落库和前后端联调。

## 当前导入架构

导入模块目前同时保留两条链路：

1. 旧链路：WebView 抓取当前课表页面 HTML，由 Dart 本地解析。
2. 新链路：WebView 内脚本获取原始 JSON，交给 Python 后端做字段映射、周次/节次解析，再回写本地 SQLite。

当前代码中，学校列表、导入页、导入 API 服务、日志上报和本地课表仓库已经串通；其中新链路的数据抓取桥接仍处于过渡阶段，所以页面中保留了 HTML 抓取兜底。

## 目录重点

```text
lib/
├── app/                       # 应用壳、主题、环境配置
├── data/remote/               # HTTP 基础设施
├── features/import/           # 学校选择、导入执行、导入服务
├── features/schedule/         # 课程表与本地 SQLite 数据层
├── features/todo/             # 待办模块
└── features/profile/          # 我的页面
```

## 本地运行

```bash
flutter pub get
flutter run -d windows
```

Web 调试：

```bash
flutter build web --debug
flutter run -d web-server --web-port=8080
```

如果后端需要联调，请先启动 Python 服务：

```bash
cd backend/python_import_service
h:\WorkSpace_For_VsCode\VUE\classduck\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

## 自动化测试

运行 Flutter 测试：

```bash
flutter test
```

当前新增覆盖点：

1. 学校层级归一化逻辑。
2. 导入 API 请求体和容错逻辑。
3. AppShell 基础导航加载。

## 为什么 Web 端不能直接用 WebView

这不是单纯的插件限制，而是当前导入方案和浏览器安全模型天然冲突：

1. 原生端的 `webview_flutter` 包装的是系统 WebView，能加载学校教务页面、执行脚本、读取当前 DOM/HTML。
2. Web 端对应实现本质上是 `iframe`，不是一个可完全控制的浏览器内核。
3. 教务系统通常与前端站点不同域。浏览器同源策略会阻止我们从页面脚本里读取跨域 iframe 的 DOM、Cookie 和登录态细节。
4. 当前导入核心依赖两种能力：
	- 向已登录页面注入脚本抓取原始数据。
	- 读取当前课表页的完整 HTML 作为 Dart 解析兜底。
5. 这两种能力在跨域 Web 场景下都不可靠，因此 Web 端无法完成“登录教务 → 抓取数据 → 导入”闭环。

所以当前 Web 端的正确策略是“可浏览、不可抓取”：

1. 学校列表可以正常使用。
2. 导入执行页会展示降级说明。
3. 用户可以在浏览器新标签页打开教务系统。
4. 真正导入需要切换到 Windows、Android 或 iOS 客户端完成。
