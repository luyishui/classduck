# 任务19-PRD与Pen联合对齐第二轮（去演示数据+激活态增强）

## 1. 任务目标
根据用户新增要求，解决第一轮之后的关键偏差：
1. 不能把 Pen 展示内容作为默认业务数据。
2. 必须同时对照 PRD 与 Pen，而非只看视觉稿。
3. 课程激活态与加号菜单要补齐 PRD 关键结构。
4. 全局颜色与视觉 token 要对齐 Pen 变量。

## 2. 本轮完成内容
### 2.1 Pen 结构化 JSON 可读取（已验证）
通过 Pencil MCP 的 `batch_get` 成功读取节点结构，返回了结构化 JSON 内容（包含节点、颜色变量、字体、坐标等），说明 Pen 文件可以作为结构化基准使用。

### 2.2 全局色板改为 Pen 变量值
文件：`classduck_app/lib/shared/theme/app_tokens.dart`
- 页面底色：`#FFFDF8`
- 主文本：`#40352A`
- 次文本：`#A3978A`
- 主黄：`#FFC93C`
- 软黄：`#FFF4CC`
- 补齐粉/绿/蓝/紫软色与文本色

### 2.3 课程页去除“演示默认数据注入”
文件：`classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 删除“首次进入自动插入演示课程”的逻辑。
- 当无课表数据时改为空态提示，引导用户用加号进行导入或手动添加。
- 保留真实加载逻辑，不再混入展示型假数据。

### 2.4 加号菜单补齐三项入口
文件：`classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 现已包含：手动添加、教务导入、拍照添加。
- 与 PRD `课程表-点击加号(列表菜单)` 的一级菜单一致。

### 2.5 课程激活态弹窗结构增强
文件：`classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 新增 `_CourseActivatedModal`，包含：
  - 顶部关闭按钮
  - 中间课程标题
  - 右上删除按钮
  - 字段区：星期、节次、教师、地点
  - 关联待办区（从数据库按课程名查询）
- 新增 `_CourseInfoLine` 统一字段行样式。

### 2.6 关联待办查询能力
文件：`classduck_app/lib/features/todo/data/todo_repository.dart`
- 新增 `getTodosByCourseName(courseName)` 方法。
- 用于课程激活态中展示课程关联待办。

### 2.7 已上课程统计口径优化
文件：
- `classduck_app/lib/features/schedule/data/schedule_repository.dart`
- `classduck_app/lib/features/profile/ui/profile_page.dart`

变更：
- 新增 `getDoneCourseCount()`，由“总课程数”改为“按当前时间推断已结束课程数”。
- Profile 页改用该方法，贴近 PRD 的“已上课程累计”口径。

### 2.8 弹窗背景贴合 PRD
文件：`classduck_app/lib/shared/widgets/duck_modal.dart`
- 弹窗背景从仅暗化，升级为“暗化 + 模糊”（BackdropFilter）。
- 保留双击空白关闭行为，同时支持遮罩关闭。

## 3. 核心函数说明
### 3.1 `SchedulePage._loadScheduleData()`
- 输入：本地课表仓储数据
- 输出：当前课表名、课程列表
- 关键逻辑：
  - 无课表 -> 空态，不写入演示数据
  - 有课表 -> 按 tableId 加载真实课程

### 3.2 `SchedulePage._openAddMenu()`
- 输入：用户点击 FAB
- 输出：三项入口弹窗
- 关键逻辑：
  - 教务导入会跳转学校选择页，成功后回刷课表
  - 手动添加、拍照添加先提供占位入口，等待下一步能力接入

### 3.3 `SchedulePage._openCourseDetail(...)`
- 输入：节次与课程列表
- 输出：课程激活态弹窗
- 关键逻辑：
  - 查询课程关联待办
  - 按 PRD 结构展示课程字段与待办列表

### 3.4 `ScheduleRepository.getDoneCourseCount()`
- 输入：当前时间（可选）
- 输出：已结束课程计数
- 关键逻辑：
  - 以 weekday + 节次估算课程结束状态
  - 用于“我的页”统计卡

## 4. 本轮验收标准与结果
### 4.1 验收标准
1. 课程页不再自动插入演示课程。
2. 加号菜单有三项入口（手动/教务/拍照）。
3. 课程激活态具备关闭、删除、字段区、关联待办区。
4. 颜色 token 与 Pen 变量一致。
5. 静态检查通过。

### 4.2 验收结果
- 标准 1-5 已达成。
- `flutter analyze`：No issues found。

## 5. 风险与未完成项
1. 课程激活态目前字段是“展示+占位”，编辑提交与删除落库还未接入。
2. 拍照添加尚未接入系统相机权限链路。
3. 已上课程统计当前为本地推断版本，后续可结合周次与学期精确化。
4. 视觉细节仍需第三轮精修（字号、留白、图标大小、阴影强度）。

## 6. 下一步建议
进入第三轮“全页面像素级精修 + 交互收口”：
1. 按 Pen 节点尺寸微调三主页面。
2. 对齐更多二级页（提醒时间弹窗、版本更新弹窗、手动添加页）。
3. 逐条对应 PRD 验收项做 checklist 结果文档。
