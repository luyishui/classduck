# 任务07-课程表SQLite数据层落地

## 1. 任务目标
建立课程表模块可维护的数据层，为后续导入落库、课程渲染和统计联动提供稳定基础：
1. 设计课程表与课程两张核心表。
2. 完成实体模型与 Repository。
3. 保证数据库外键约束与基础 CRUD 可用。

## 2. 任务范围
- 新增 SQLite 依赖
- 新增数据库帮助类（建表、版本、外键）
- 新增课程表实体与课程实体
- 新增课程仓储（创建、查询、批量写入、删除）
- 执行静态检查验收

## 3. 本次改动文件清单与作用说明
1. `classduck_app/pubspec.yaml`
- 新增 `sqflite`、`path` 依赖。

2. `classduck_app/lib/data/local/db_helper.dart`
- 数据库入口与建表 SQL。
- 维护版本号、外键开启、onCreate 逻辑。

3. `classduck_app/lib/features/schedule/domain/course_table.dart`
- 课程表实体 `CourseTableEntity`。
- 提供 `toMap/fromMap` 映射。

4. `classduck_app/lib/features/schedule/domain/course.dart`
- 课程实体 `CourseEntity`。
- 覆盖导入所需核心字段，提供 `toMap/fromMap`。

5. `classduck_app/lib/features/schedule/data/schedule_repository.dart`
- 课程数据访问入口：
- 创建课表
- 查询课表列表
- 批量写入课程
- 按课表查询课程
- 删除课表

## 4. 数据库设计说明
### 4.1 表结构
1. `course_table`
- 主键：`id`
- 核心字段：`name`、`semester_start_monday`、`class_time_list_json`
- 审计字段：`created_at`、`updated_at`

2. `course`
- 主键：`id`
- 外键：`table_id -> course_table(id)`，`ON DELETE CASCADE`
- 核心字段：课程信息、周次节次、导入来源、颜色、扩展信息
- 审计字段：`created_at`、`updated_at`

### 4.2 约束策略
- 开启 `PRAGMA foreign_keys = ON`。
- 删除课表时自动级联删除课程，避免脏数据。

## 5. 核心函数说明
### 5.1 `DbHelper.open()`
- 输入：无
- 输出：`Future<Database>`
- 逻辑：
1. 拼接数据库路径
2. 打开数据库
3. 配置外键
4. 首次创建两张表

### 5.2 `ScheduleRepository.createCourseTable(...)`
- 输入：课表名、开学周一、节次时间列表（可选）
- 输出：创建后的 `CourseTableEntity`
- 逻辑：写入课表并返回带主键实体

### 5.3 `ScheduleRepository.getCourseTables()`
- 输入：无
- 输出：课表列表（按 id 倒序）

### 5.4 `ScheduleRepository.addCourses(...)`
- 输入：`tableId`、课程列表
- 输出：无
- 逻辑：事务内批量写入，保证一致性

### 5.5 `ScheduleRepository.getCoursesByTableId(tableId)`
- 输入：课表 id
- 输出：课程列表（按周几+开始节排序）

### 5.6 `ScheduleRepository.deleteCourseTable(tableId)`
- 输入：课表 id
- 输出：无
- 逻辑：删除课表，触发外键级联删除课程

## 6. 架构设计说明
### 6.1 分层职责
- `data/local`：数据库生命周期与表定义
- `features/schedule/domain`：业务实体定义
- `features/schedule/data`：仓储与数据访问编排

### 6.2 可维护性收益
1. 领域模型与存储映射分离。
2. 页面层不直接操作 SQL。
3. 导入模块后续可直接复用仓储写入。

## 7. 执行方案与关键决策
1. 决策：表字段覆盖导入主链路必需数据。
- 原因：避免后续频繁迁移。

2. 决策：`weeks` 使用 JSON 字符串保存。
- 原因：简化首版模型，后续可拆分成标准化关系表。

3. 决策：`addCourses` 使用事务。
- 原因：避免部分写入导致数据不一致。

## 8. 验收标准
1. 依赖安装成功：`flutter pub get` 完成。
2. 数据层代码通过静态检查：`flutter analyze` 为 `No issues found`。
3. Repository 提供完整基础能力：建课表、查课表、写课程、查课程、删课表。

## 9. 验收结果（本次）
1. 依赖安装完成。
2. `flutter analyze` 已通过，无报错。
3. SQLite 数据层核心文件已落地。

## 10. 风险与后续计划
### 10.1 当前风险
- 尚未加入数据库迁移策略（当前 version=1）。
- 尚未补充 repository 单元测试。

### 10.2 下一步建议
- 任务08：导入页面与学校列表页面（读取 backend 配置并驱动导入入口）。
- 任务09：课程表页面接入本地课程数据渲染。
