# 任务03-新工程骨架与三Tab基础壳

## 1. 任务目标
基于总实施方案，完成上课鸭新项目的首个可运行架构骨架，要求：
1. 结构清晰、可维护。
2. UI、主题、路由具备明确分层。
3. 提供统一弹窗容器，满足后续统一交互规则改造基础。
4. 通过静态检查，确保质量可控。

## 2. 任务范围
- 初始化全新 Flutter 工程：`classduck_app/`
- 重构入口为分层 App 壳结构
- 搭建三 Tab 基础页面（Schedule/Todo/Profile）
- 建立设计 Token 与全局主题
- 建立统一 Modal 组件
- 修复并更新默认测试

## 3. 本次改动文件清单与作用说明
### 3.1 应用入口与壳层
1. `classduck_app/lib/main.dart`
- 应用入口，仅负责 `runApp`，不承载业务逻辑。

2. `classduck_app/lib/app/app.dart`
- 根组件 `ClassDuckApp`，负责：
- `MaterialApp` 基本配置
- 主题挂载
- 首页壳组件挂载

3. `classduck_app/lib/app/router/app_shell.dart`
- 应用主壳 `AppShell`，负责：
- 三 Tab 导航状态管理
- 不同模块页面容器切换
- 顶栏调试入口（打开统一 Modal）

### 3.2 主题与设计 Token
4. `classduck_app/lib/shared/theme/app_tokens.dart`
- 定义颜色、圆角、间距 Token。
- 目标：避免魔法数散落，后续主题调整可集中变更。

5. `classduck_app/lib/app/theme/app_theme.dart`
- 根据 Token 构建全局 `ThemeData`。
- 提供 `AppTheme.light()` 作为统一主题入口。

### 3.3 功能模块占位
6. `classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 课程模块页面脚手架。

7. `classduck_app/lib/features/todo/ui/todo_page.dart`
- 待办模块页面脚手架。

8. `classduck_app/lib/features/profile/ui/profile_page.dart`
- 我的模块页面脚手架。

### 3.4 统一弹窗组件
9. `classduck_app/lib/shared/widgets/duck_modal.dart`
- `DuckModal.show`：统一弹窗展示入口。
- `DuckModalFrame`：统一弹窗容器（标题+关闭按钮+内容区）。

### 3.5 测试文件
10. `classduck_app/test/widget_test.dart`
- 从默认计数器测试改为应用壳加载测试。
- 验证三 Tab 标签可见，保证基础壳已工作。

## 4. 核心函数/类说明
### 4.1 `ClassDuckApp`（`app.dart`）
- 输入：无外部入参。
- 输出：返回已挂载主题与主壳的 `MaterialApp`。
- 作用：统一应用装配点，降低入口复杂度。

### 4.2 `AppShell`（`app_shell.dart`）
- 状态：`_tabIndex`（当前 Tab）。
- 核心方法：
- `_titleForTab(int index)`：按 Tab 返回标题文本。
- `onDestinationSelected` 回调：更新 `_tabIndex` 并刷新页面。
- 作用：作为一级信息架构容器，后续可扩展为路由分发层。

### 4.3 `AppTheme.light()`（`app_theme.dart`）
- 输入：无。
- 输出：`ThemeData`。
- 逻辑：通过 `ColorScheme.fromSeed` 与 `AppTokens` 生成统一主题。

### 4.4 `DuckModal.show<T>()`（`duck_modal.dart`）
- 输入：
- `BuildContext context`
- `Widget child`
- 输出：`Future<T?>`
- 逻辑：统一 showGeneralDialog 行为，包含遮罩、淡入动画与双击空白关闭入口。

### 4.5 `DuckModalFrame`（`duck_modal.dart`）
- 输入：`title`、`child`
- 输出：标准弹窗容器 Widget
- 逻辑：统一标题、关闭按钮、内容区域与圆角视觉。

## 5. 架构设计说明
### 5.1 分层边界
- `app/`：应用装配与壳层导航
- `shared/`：跨模块复用能力（Token、组件）
- `features/*/ui`：模块页面

### 5.2 依赖方向
- `main.dart` -> `app/`
- `app/` -> `shared/` + `features/`
- `features/` 不反向依赖 `app/`

该依赖方向可减少耦合，便于后续引入 application/domain/data 子层。

## 6. 执行方案与关键决策
1. 决策：先落基础壳，再接业务模块。
- 原因：先稳定壳层与规范，避免后续重复改入口与主题。

2. 决策：先提供统一 Modal 组件。
- 原因：PRD 强调弹窗统一行为，需提前抽象，避免后续重复改造。

3. 决策：保留各模块为轻量占位页面。
- 原因：确保下一阶段可并行推进课程、待办、我的业务逻辑。

## 7. 验收标准
1. 工程可静态检查通过：
- 执行 `flutter analyze`，结果为 `No issues found`。

2. 三 Tab 基础壳可用：
- 可看到 `Schedule`、`Todo`、`Profile` 导航项。

3. 统一弹窗容器可调用：
- 在 AppShell 顶栏点击信息按钮可打开统一样式弹窗。

4. 测试用例与入口一致：
- `widget_test.dart` 已改为新入口 `ClassDuckApp`。

## 8. 风险与后续计划
### 8.1 当前风险
- 弹窗“双击空白关闭”目前为基础实现，后续需按 PRD 场景细化手势冲突与确认逻辑。

### 8.2 下一步建议
- 任务04（推荐）：课程表主页面骨架（顶栏、周次、网格容器、底栏交互）
- 同步产出任务04文档并附验收清单。
