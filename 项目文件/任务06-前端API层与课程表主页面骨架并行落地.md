# 任务06-前端API层与课程表主页面骨架并行落地

## 1. 任务目标
按“并行推进”要求，在同一阶段完成两块内容：
1. 前端 API Client 与 Repository 基础层。
2. 课程表主页面 PRD 风格骨架与基础交互占位。

## 2. 任务范围
- 新增网络请求依赖与环境配置
- 新增 remote client + 异常模型
- 新增 school config 领域模型与仓储
- 改造 AppShell 为单一 Scaffold 一级容器
- 重写课程表页面为可交互骨架
- 修正 Todo/Profile 页面结构

## 3. 本次改动文件清单与作用说明
### 3.1 依赖与环境
1. `classduck_app/pubspec.yaml`
- 新增依赖：`http`、`intl`
- 分别用于网络请求与日期格式化显示。

2. `classduck_app/lib/app/config/app_env.dart`
- 定义 API 基础地址 `apiBaseUrl`。

### 3.2 API Client 层
3. `classduck_app/lib/data/remote/api_exception.dart`
- 定义统一 API 异常类型。

4. `classduck_app/lib/data/remote/http_json_client.dart`
- 封装 GET JSON 请求与状态码检查。
- 非 2xx 和非对象响应统一抛异常。

### 3.3 Import 仓储层
5. `classduck_app/lib/features/import/domain/school_config.dart`
- 学校配置领域模型与 `fromMap` 工厂。

6. `classduck_app/lib/features/import/data/school_config_repository.dart`
- 封装 `fetchSchoolConfigs()`，从后端读取学校配置列表并映射为领域模型。

### 3.4 壳层与页面
7. `classduck_app/lib/app/router/app_shell.dart`
- 改为单一 Scaffold + `IndexedStack`。
- 消除内层 Scaffold 套嵌，便于统一导航和悬浮控件策略。

8. `classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 升级为 `StatefulWidget`。
- 加入配置加载状态、错误状态、重试入口。
- 按 PRD 构建顶部按钮、周次、日期、网格占位、右下加号。
- 加入统一弹窗占位交互。

9. `classduck_app/lib/features/todo/ui/todo_page.dart`
- 移除内层 Scaffold，改为 `SafeArea + Center`。

10. `classduck_app/lib/features/profile/ui/profile_page.dart`
- 移除内层 Scaffold，改为 `SafeArea + Center`。

## 4. 核心函数/类说明
### 4.1 `HttpJsonClient.getJsonMap(path)`
- 输入：接口路径字符串
- 输出：`Map<String, dynamic>`
- 逻辑：
1. 拼接 `apiBaseUrl + path`
2. 发起 GET
3. 校验状态码
4. 解析 JSON 并校验顶层对象结构

### 4.2 `SchoolConfigRepository.fetchSchoolConfigs()`
- 输入：无
- 输出：`List<SchoolConfig>`
- 逻辑：
1. 调用 `/v1/config/schools`
2. 读取 `data` 列表
3. 转换为 `SchoolConfig` 列表

### 4.3 `SchedulePage._loadSchoolConfigs()`
- 输入：无
- 输出：`Future<void>`
- 逻辑：
1. 置为 loading
2. 调用 repository 获取配置
3. 更新配置数量或错误信息
4. 关闭 loading

### 4.4 `AppShell`（IndexedStack 模式）
- 输入：底部导航索引
- 输出：显示对应 Tab 页面
- 逻辑：
1. 维护 `_tabIndex`
2. `onDestinationSelected` 更新索引
3. `IndexedStack` 保留各页面状态

## 5. 架构设计说明
### 5.1 并行落地策略
- API 层先建立通路，页面层直接消费仓储结果。
- 页面先用占位交互，后续可平滑替换为真实业务动作。

### 5.2 分层依赖
- `schedule/ui` -> `import/data` -> `data/remote`
- `app/router` 只关心导航，不关心业务数据

### 5.3 维护性收益
1. 网络异常统一通过 `ApiException` 表达。
2. 页面不直接写 HTTP 细节。
3. 壳层结构可支持更多一级页面并保持状态稳定。

## 6. 执行方案与关键决策
1. 决策：先实现 GET 配置，不提前接入复杂导入流程。
- 原因：先打通最关键远端配置链路。

2. 决策：课程表页面先做可交互骨架。
- 原因：尽早验证 PRD 布局方向与用户触达路径。

3. 决策：改 AppShell 为 IndexedStack。
- 原因：保持 Tab 状态，减少页面切换重建。

## 7. 验收标准
1. `flutter pub get` 成功。
2. `flutter analyze` 结果为 `No issues found`。
3. 课程表页面具备以下可见结构：
- 顶部菜单/分享按钮
- 周次与日期
- 配置加载状态卡片
- 网格占位区域
- 右下加号按钮
4. API 层可通过 repository 拉取学校配置（后端可用时）。

## 8. 验收结果（本次）
1. 依赖拉取成功。
2. 修复一次路径引用错误后，静态检查已通过。
3. 页面骨架与 API 分层均已落地。

## 9. 风险与后续计划
### 9.1 当前风险
- 课程表网格仍为占位视图，未接入真实课程数据。
- 本地开发 `localhost` 在移动真机场景不可直连。

### 9.2 下一步建议
- 任务07：实现课程表领域模型与本地 SQLite 存储层。
- 任务08：实现导入页面与学校列表选择页，接通后端配置接口。
