# 任务20-三主页面第三轮精修（PRD+Pen参数对齐）

## 1. 任务目标
按照用户确认的优先级“先主页面再二级页面”，继续精修课程表、待办、我的三个主页面。目标是把第一轮“结构对齐”提升到“参数级对齐”：
- 标题字号、边距、图标尺寸、底栏图标语义
- 颜色使用 Pen 变量
- 逻辑上去除演示数据污染

## 2. 依据与输入
1. PRD 文档：课程表主页面、待办主页面、我的主页面。
2. Pen 节点参数：`KK1oe`、`rIPaG`、`4HXZD` 的 readDepth=4 结构。
3. Pen 变量：`page-bg/text-main/text-muted/duck-yellow/duck-yellow-soft` 等。

## 3. 本次改动文件与作用
### 3.1 全局视觉 Token
文件：`classduck_app/lib/shared/theme/app_tokens.dart`
- 同步 Pen 变量色值（主色、软色、文本色）。
- 新增粉/绿/蓝/紫软色组，供页面卡片标签统一使用。

### 3.2 课程页面
文件：`classduck_app/lib/features/schedule/ui/schedule_page.dart`
- 顶部区域边距调整为 28，与 Pen 头部布局更接近。
- 周标题改为固定 24 号字重 700。
- 网格节次高度从 66 调整为 80，贴近 Pen 的 8 行节次区。
- 保留真实空态逻辑，不自动注入演示课程。
- 加号菜单包含三项（手动/教务/拍照）。
- 课程激活态弹窗支持结构化字段与关联待办展示。

### 3.3 待办页面
文件：`classduck_app/lib/features/todo/ui/todo_page.dart`
- 顶部边距改为 28。
- 标题字体改为 24/700。
- 顶部菜单与分享按钮改为 40x40，图标 20，颜色与 Pen 对齐。
- 列表横向边距改为 28。
- 修复了一处重复 padding 配置。

### 3.4 我的页面
文件：`classduck_app/lib/features/profile/ui/profile_page.dart`
- 顶部边距改为 28。
- 标题改为 24/700。
- 右上分享按钮改为 40x40，图标 20。
- 统计卡与设置区布局继续贴近 Pen 的主间距节奏。

### 3.5 底栏图标语义
文件：`classduck_app/lib/app/router/app_shell.dart`
- 待办图标由 checkbox 改为 `fact_check`，与 Pen 设计一致。

### 3.6 统计与关联能力补充（与本轮视觉同步推进）
文件：
- `classduck_app/lib/features/schedule/data/schedule_repository.dart`
- `classduck_app/lib/features/todo/data/todo_repository.dart`
- `classduck_app/lib/features/profile/ui/profile_page.dart`

- 已上课程改为时间口径统计方法 `getDoneCourseCount()`。
- 新增 `getTodosByCourseName()` 供课程激活态展示关联待办。

## 4. 关键函数说明
### 4.1 `SchedulePage._buildScheduleGrid()`
- 目的：构建课表网格与课程卡定位。
- 本轮调整：节次高度改为 80，提升与 Pen 的视觉一致性。

### 4.2 `SchedulePage._openCourseDetail(...)`
- 目的：弹出课程激活态。
- 本轮增强：拉取课程关联待办并在弹窗中展示。

### 4.3 `ScheduleRepository.getDoneCourseCount()`
- 目的：计算“已上课程”而非“总课程数”。
- 算法：按当前星期与节次推断课程是否已结束。

### 4.4 `TodoRepository.getTodosByCourseName(...)`
- 目的：为课程激活态提供关联待办数据源。

## 5. 验收标准与结果
### 5.1 验收标准
1. 三主页面标题/边距/按钮尺寸接近 Pen 参数。
2. 待办底栏图标语义与 Pen 一致。
3. 无演示课程自动写入。
4. 代码静态检查通过。

### 5.2 验收结果
- 标准 1-4 均达成。
- `flutter analyze`：No issues found。

## 6. 当前仍存在的差距
1. 课程网格目前仍是“功能优先布局”，与 Pen 的绝对像素定位还存在细微差异。
2. 待办卡片细节（字重、次级文本色、标签内边距）仍可继续压缩误差。
3. 我的页统计卡阴影/分隔线长度与 Pen 仍有少量偏差。

## 7. 下一步（已与用户方向一致）
1. 继续主页面最后一轮精修，优先缩小上述三类差距。
2. 完成后再进入二级页面（加号菜单页、选择学校、手动添加、提醒与通知、关于和版本弹窗）。
