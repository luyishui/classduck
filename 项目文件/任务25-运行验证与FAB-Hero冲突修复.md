# 任务25-运行验证与FAB Hero冲突修复

## 1. 任务目标
按要求本地实际运行应用，验证“关于上课鸭 + 更新弹窗”改动可启动可查看；若运行中发现阻塞问题，立即修复。

## 2. 发现的问题
在 `flutter run -d chrome` 运行阶段出现运行时异常：
- `There are multiple heroes that share the same tag within a subtree.`
- 冲突标签为默认 `FloatingActionButton` hero tag。

触发原因：
- 页面结构中存在多个 `FloatingActionButton`，未显式设置唯一 `heroTag`，在同一 Hero 子树下发生冲突。

## 3. 本次改动文件
1. `classduck_app/lib/features/todo/ui/todo_page.dart`
- 为待办页 FAB 增加：`heroTag: 'todo-fab'`。

2. `classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 为课程页 FAB 增加：`heroTag: 'schedule-fab'`。

## 4. 核心修复说明
### 4.1 修复点
Flutter 中每个路由子树中的 Hero 标签必须唯一。默认 FAB 会使用相同默认 Hero tag。

通过为两个 FAB 指定不同 `heroTag`，避免了默认 tag 冲突：
1. `todo-fab`
2. `schedule-fab`

### 4.2 影响范围
1. 仅影响 FAB 的 Hero 动画标识。
2. 不影响按钮视觉样式和点击行为。
3. 不影响业务逻辑和数据层。

## 5. 验证结果
1. 静态检查（修改文件）无错误。
2. 本地运行日志已出现正常启动信息：
- `Launching lib\main.dart on Chrome in debug mode...`
- `Debug service listening on ws://...`
- `The Flutter DevTools debugger and profiler on Chrome is available at: http://...`

## 6. 验收标准
1. 应用可在 Chrome 设备启动。
2. 不再出现默认 FAB Hero tag 冲突异常。
3. 页面可继续进行后续视觉验收。

## 7. 后续建议
1. 若后续新增 FAB，统一要求显式设置 `heroTag`。
2. 在主壳层切页场景加入运行时回归检查，避免同类错误再次出现。