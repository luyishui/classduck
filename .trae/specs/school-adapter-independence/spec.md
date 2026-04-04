# 学校适配模块独立化 Spec

## Why

当前项目的学校适配代码分散在多个位置（`wakeup_rule/`、`backend/`、`参考文件/`、`shiguang_warehouse/`），缺乏统一管理。适配工作需要与主体项目分离，便于独立维护、测试和扩展，同时为后续社区贡献提供清晰的入口。

## What Changes

* 在 `backend/python_import_service/adapters/` 创建独立适配目录，统一管理学校适配源码

* 目录结构按前端三层分类：**本/专科（undergraduate）**、**硕士（master）**、**通用（general）**

* 整合 AI Schedule、Class-Schedule-Flutter、wakeup\_rule、shiguang\_warehouse 四个来源的适配规则

* 建立内部规范，确保所有组件符合项目要求

* 建立来源追溯与许可证合规机制，避免第三方规则迁移后失去可追溯性

* 建立 `adapters` 到运行时产物目录（`data/school_configs`、`data/scripts`）的发布流水线

* 建立前后端数据同步机制

* 补充完善所有学校的登录网站信息

* 创建详细的 README 文档

## Impact

* Affected specs: 学校配置服务、前端学校列表

* Affected code:

  * `backend/python_import_service/services/school_service.py`

  * `backend/python_import_service/data/`

  * `classduck_app/assets/config/schools.builtin.json`

***

## 前端架构分析

前端学校列表页面 (`import_school_list_page.dart`) 采用三层分类结构：

| 显示标签 | level 值         | 说明                         |
| ---- | --------------- | -------------------------- |
| 本/专科 | `undergraduate` | 本科院校 + 专科院校（junior 自动归入此类） |
| 硕士   | `master`        | 研究生院/硕士课程                  |
| 通用   | `general`       | 通用教务系统入口                   |

**前端代码定义**：

```dart
static const List<String> _schoolLevelTabs = <String>[
  '本/专科',
  '硕士',
  '通用',
];

static const List<String> _schoolLevelKeys = <String>[
  'undergraduate',
  'master',
  'general',
];
```

***

## 现有资源分析

### 1. 当前项目已有适配 (`backend/python_import_service/data/`)

| 学校     | 系统类型      | 配置文件                       | 脚本文件                       | 状态   |
| ------ | --------- | -------------------------- | -------------------------- | ---- |
| SORA教务 | sora      | `school_configs/sora.json` | `scripts/sora_provider.js` | 样例配置 |
| 西安交通大学 | zhengfang | `school_configs/xjtu.json` | `scripts/xjtu_provider.js` | 已实现  |

### 2. shiguang\_warehouse 仓库 (`shiguang_warehouse/`)

**最完整的适配资源**，包含 70+ 所学校：

| 分类      | 数量  | 说明           |
| ------- | --- | ------------ |
| 通用教务系统  | 4   | 正方、超星、青果、URP |
| 本科/专科院校 | 60+ | 各类高校         |
| 研究生系统   | 若干  | 研究生教务        |

### 3. wakeup\_rule 目录 (`wakeup_rule/parsers/`)

**Kotlin 解析器**，支持 7 种教务系统

### 4. 参考项目：Class-Schedule-Flutter (`参考文件/Class-Shedule-Flutter/`)

支持 8 所学校

### 5. 参考项目：AI Schedule (`参考文件/aishedule-master/`)

**最丰富的适配资源**，100+ 所学校

***

## ADDED Requirements

### Requirement: 独立适配器目录结构（三层分类）

系统 SHALL 提供独立的 `backend/python_import_service/adapters/` 目录，按前端三层分类组织：

```
backend/python_import_service/adapters/
├── core/                          # 核心框架
│   ├── __init__.py
│   ├── base_parser.py            # 解析器基类和接口定义
│   ├── test_runner.py            # 测试运行器
│   └── utils.py                  # 通用工具函数
│
├── undergraduate/                 # 本/专科院校
│   ├── schools/                   # 学校配置
│   │   ├── pku.json              # 北京大学
│   │   ├── thu.json              # 清华大学
│   │   ├── whu.json              # 武汉大学
│   │   └── ...
│   ├── scripts/                   # 学校特定脚本
│   │   ├── pku_provider.js
│   │   └── ...
│   └── README.md                  # 本/专科适配说明
│
├── master/                        # 硕士/研究生
│   ├── schools/                   # 学校配置
│   │   ├── nju_master.json       # 南京大学研究生
│   │   ├── sjtu_master.json      # 上海交通大学研究生
│   │   └── ...
│   ├── scripts/                   # 学校特定脚本
│   └── README.md                  # 硕士适配说明
│
├── general/                       # 通用教务系统
│   ├── systems/                   # 系统配置
│   │   ├── zhengfang.json        # 正方教务
│   │   ├── qiangzhi.json         # 强智教务
│   │   ├── urp.json              # URP教务
│   │   ├── chaoxing.json         # 超星
│   │   ├── qingguo.json          # 青果
│   │   └── ...
│   ├── scripts/                   # 通用解析脚本
│   │   ├── zhengfang_base.js
│   │   ├── qiangzhi_base.js
│   │   └── ...
│   └── README.md                  # 通用系统适配说明
│
├── schemas/                       # JSON Schema 定义
│   ├── school_config.schema.json  # 学校配置 Schema
│   └── adapter_test.schema.json   # 测试数据 Schema
│
├── tests/                         # 测试数据和用例
│   ├── fixtures/                  # 测试HTML/JSON数据
│   │   ├── zhengfang/
│   │   ├── qiangzhi/
│   │   └── ...
│   └── results/                   # 预期输出
│
├── index/                         # 索引文件
│   ├── school_index.yaml          # 学校索引
│   ├── school_index.proto         # Protobuf 定义
│   └── migration_map.yaml         # 来源映射与合规追溯
│
├── scripts/                       # 工具脚本
│   ├── validate.py               # 配置验证
│   ├── migrate.py                # 从各来源迁移
│   ├── sync.py                   # 前后端数据同步
│   └── publish.py                # 发布到后端服务
│
└── README.md                      # 项目主文档
```

**运行时兼容约定（过渡期）**：

* `backend/python_import_service/data/school_configs/` 与 `backend/python_import_service/data/scripts/` 继续保留，作为发布产物目录

* 禁止手工直接编辑运行时目录，统一通过 `adapters/scripts/publish.py` 生成

### Requirement: 内部规范

系统 SHALL 建立并执行以下内部规范：

#### 1. 配置格式规范

**学校配置 JSON 格式**：

```json
{
  "id": "whu",
  "level": "undergraduate",
  "title": "武汉大学",
  "initial": "W",
  "system_type": "zhengfang",
  "import_url": "https://jwgl.whu.edu.cn/login",
  "target_url": "https://jwgl.whu.edu.cn/xskbcx",
  "extract_script_url": "local://adapters/undergraduate/scripts/whu_provider.js",
  "delay_seconds": 3,
  "timer_config": {
    "total_week": 20,
    "start_semester": "2026-02-24",
    "sections": [...]
  },
  "maintainer": "contributor_name",
  "source": "ai_schedule",
  "source_path": "schools/whu.js",
  "license": "MIT",
  "version": "1.0.0",
  "status": "active"
}
```

**必填字段**：

* `id`: 唯一标识，使用学校英文缩写

* `level`: 必须为 `undergraduate`、`master`、`general` 之一

* `title`: 学校中文名称

* `initial`: 拼音首字母，用于前端排序

* `import_url`: 登录页面 URL（必须有效）

* `extract_script_url`: 解析脚本路径

**可选字段**：

* `system_type`: 教务系统类型

* `target_url`: 课表页面 URL

* `timer_config`: 时间配置

* `maintainer`: 维护者信息

* `source`: 数据来源

* `source_path`: 来源仓库内相对路径

* `license`: 来源许可证（如 MIT）

**发布字段映射（adapters → runtime）**：

| adapters 字段          | runtime 字段（Python）              | 说明           |
| -------------------- | ------------------------------- | ------------ |
| `title`              | `name`                          | 学校展示名称       |
| `import_url`         | `login_url`                     | 登录地址         |
| `delay_seconds`      | `pre_extract_delay`             | 脚本注入前等待秒数    |
| `extract_script_url` | 由 `/api/schools/{id}/script` 生成 | 运行时走后端脚本分发接口 |

#### 2. 脚本编写规范

**JavaScript 解析脚本模板**：

```javascript
/**
 * 学校课表解析脚本
 * @school 武汉大学
 * @system 正方教务
 * @maintainer contributor_name
 * @version 1.0.0
 */
(async function() {
  try {
    // 1. 数据获取
    const courses = [];
    
    // 2. 解析逻辑
    // ...
    
    // 3. 返回标准格式
    const result = courses.map(course => ({
      name: course.name,           // 课程名称
      teacher: course.teacher,     // 教师
      position: course.position,   // 地点
      day: course.day,             // 星期 (1-7)
      weeks: course.weeks,         // 周次数组
      sections: course.sections    // 节次数组
    }));
    
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: true, data: result })
    );
  } catch (error) {
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: false, error: error.message })
    );
  }
})();
```

**脚本要求**：

* 必须使用 IIFE 模式

* 必须包含错误处理

* 必须通过 `flutter_inappwebview.callHandler` 返回结果

* 返回数据必须符合标准格式

#### 3. 命名规范

| 类型      | 规则                 | 示例                  |
| ------- | ------------------ | ------------------- |
| 学校 ID   | 小写英文缩写             | `whu`, `pku`, `thu` |
| 配置文件    | `{id}.json`        | `whu.json`          |
| 脚本文件    | `{id}_provider.js` | `whu_provider.js`   |
| 通用系统 ID | `generic-{system}` | `generic-zhengfang` |

#### 4. 质量规范

* 所有 URL 必须经过可访问性验证

* 脚本必须包含测试数据

* 配置变更必须更新版本号

* 必须标注数据来源和维护者

* 必须记录来源路径和许可证信息，支持发布前审计

### Requirement: README 文档规范

系统 SHALL 创建详细的 README 文档，包含：

#### 1. 内部规范说明

```markdown
# ClassDuck 学校适配器

## 内部规范

### 设计原则

1. **三层分类架构**
   - 本/专科 (undergraduate): 包含所有本科和专科院校
   - 硕士 (master): 研究生院和硕士课程
   - 通用 (general): 通用教务系统入口

2. **配置驱动**
   - 所有学校配置采用 JSON 格式
   - 解析逻辑采用 JavaScript 脚本
   - 支持热更新，无需重新编译

3. **数据来源标注**
   - 所有适配必须标注来源
   - 维护者信息必须完整
   - 版本变更必须记录

### 实现细节

[详细的技术实现说明]
```

#### 2. 贡献者指南

```markdown
## 如何贡献

### 添加新学校适配

1. 确定学校分类（undergraduate/master/general）
2. 在对应目录创建配置文件
3. 编写解析脚本
4. 添加测试数据
5. 提交 Pull Request

### 配置文件模板

[模板内容]

### 脚本模板

[模板内容]

### 测试要求

[测试要求]
```

#### 3. 贡献者署名

```markdown
## 贡献者

感谢以下贡献者的付出：

### 核心团队
- [名单]

### 适配贡献者
- [按学校列出贡献者]

### 数据来源
- AI Schedule 项目
- Class-Schedule-Flutter 项目
- WakeupSchedule 项目
- ShiguangSchedule 项目
```

#### 4. SHIGUANG 项目声明

```markdown
## SHIGUANG 项目声明

本项目部分适配规则来源于 [ShiguangSchedule](https://github.com/XingHeYuZhuan/shiguang_warehouse) 项目。

### 使用条款

1. **开源协议**: SHIGUANG 项目采用 MIT 协议开源
2. **署名要求**: 使用 SHIGUANG 适配规则时，必须保留原始贡献者署名
3. **责任声明**: 
   - 本项目对 SHIGUANG 规则的使用遵循其 MIT 协议
   - 第三方分支或衍生项目行为与本项目无关
   - 原始贡献者不承担连带责任

### SHIGUANG 贡献者

[列出 SHIGUANG 项目的贡献者]

### 变更记录

| 原始文件 | 本项目文件 | 变更说明 |
|----------|------------|----------|
| ... | ... | ... |
```

### Requirement: 来源隔离与许可证合规

系统 SHALL 确保第三方来源迁移过程可追溯且合规：

* 原始来源目录（`参考文件/`、`shiguang_warehouse/`、`wakeup_rule/`）仅作为只读参考，不直接作为运行时目录

* 所有迁移记录必须写入 `backend/python_import_service/adapters/index/migration_map.yaml`，至少包含 `source_repo`、`source_path`、`license`、`target_path`、`maintainer`

* 发布前必须运行许可证审计脚本，生成审计报告并阻断缺失许可证或缺失署名的发布

### Requirement: 渐进迁移与兼容层

系统 SHALL 采用渐进迁移策略，避免一次性切换影响现有导入链路：

* 第一阶段保持 `SchoolService` 读取 `data/school_configs` 与 `data/scripts`，由 `publish.py` 从 `adapters/` 生成产物

* `publish.py` 必须执行 adapters 字段到 runtime 字段的显式映射，禁止隐式字段猜测

* 保持现有 `/v1/config/schools`、`/v1/config/adapters`、`/api/schools/*` 契约稳定，禁止破坏前端兼容字段

* 第二阶段在测试与回归通过后，再评估 `SchoolService` 直接读取 `adapters/` 的可行性

### Requirement: 前后端数据同步机制

系统 SHALL 建立前后端数据同步机制：

**后端职责**：

* 存储完整的学校配置和适配脚本

* 提供 REST API 供前端查询学校列表和配置

* 支持配置热更新，无需重启服务

* 返回数据按 level 字段分类

**前端职责**：

* 启动时从后端获取学校列表

* 按三层分类显示学校

* 缓存学校配置到本地

* 定期检查更新

**同步流程**：

```
后端 adapters 源目录 (source of truth)
  ↓ publish.py
后端运行时产物 (data/school_configs + data/scripts)
  ↓ SchoolService
后端 API (/v1/config/schools + /api/schools/*)
    ↓ HTTP 请求
前端缓存 (schools.builtin.json + 运行时更新)
    ↓
前端三层分类显示
```

### Requirement: 登录网站信息完善

系统 SHALL 为每个学校补充登录网站信息：

**数据来源优先级**：

1. shiguang\_warehouse 的 `import_url` 字段
2. AI Schedule 的 `initialUrl` 字段
3. Class-Schedule-Flutter 的 `initialUrl` 字段
4. wakeup\_rule 的 `accessible_schools_verified.md`
5. 手动查找补充

### Requirement: 生产就绪交付

系统 SHALL 确保交付状态生产就绪：

1. **前端可见性**

   * 所有学校配置正确注入到前端

   * 三层分类正确显示

   * 搜索功能正常工作

2. **立即可用**

   * 所有配置经过验证

   * 关键学校已测试通过

   * 文档完整可用

3. **长期可维护**

   * 代码组织清晰

   * 文档完整

   * 贡献流程明确

## MODIFIED Requirements

### Requirement: 后端学校服务改造

现有 `SchoolService` SHALL 先保持读取运行时产物目录，并通过发布脚本接入 `adapters/`：

* `/v1/config/schools` 返回值必须使用真实 `level` 字段（不允许硬编码）

* 支持热重载发布后的运行时产物

* 保持学校列表和配置查询 API 兼容

### Requirement: 前端学校列表生成

前端 `schools.builtin.json` SHALL 由同步机制管理：

* 初始数据由发布脚本生成

* 包含正确的 level 分类

* 支持离线模式使用缓存数据

## REMOVED Requirements

### Requirement: 手工维护运行时目录

**Reason**: `data/school_configs` 和 `data/scripts` 应作为发布产物，不应人工编辑
**Migration**:

* 手工编辑 `backend/python_import_service/data/school_configs/` / `data/scripts/` → 统一迁移到 `backend/python_import_service/adapters/` 维护并生成

* `classduck_app/assets/config/schools.builtin.json` → 由同步机制管理

***

## 实施建议

### 阶段零：基线与兼容收敛（优先级：最高）

1. 明确 `adapters/` 为源码目录、`data/` 为发布产物目录
2. 对齐 `/v1` 与 `/api` 契约字段，确保 `level` 不再硬编码
3. 增加契约回归测试，确保现有 Flutter 导入链路不回归

### 阶段一：框架搭建（优先级：最高）

1. 创建 `adapters/` 目录结构（三层分类）
2. 定义配置 Schema
3. 实现基础测试框架
4. 创建 README 文档框架

### 阶段二：数据迁移（优先级：最高）

1. 迁移 shiguang\_warehouse 全部学校（按 level 分类）
2. 迁移当前项目已有配置
3. 迁移 Class-Schedule-Flutter 学校
4. 迁移 AI Schedule 重点学校

### 阶段三：规范实施（优先级：高）

1. 验证所有配置符合规范
2. 补充缺失字段
3. 标注数据来源和维护者
4. 建立 migration\_map 映射台账与许可证字段补齐
5. 添加 SHIGUANG 声明

### 阶段四：前后端同步（优先级：高）

1. 改造后端学校服务
2. 实现前端同步机制
3. 验证前端三层分类显示

### 阶段五：生产验证（优先级：高）

1. 验证所有学校在前端可见
2. 测试关键学校导入流程
3. 生成许可证与署名审计报告
4. 完善文档

***

## 预期成果

| 指标       | 目标   |
| -------- | ---- |
| 支持学校总数   | 150+ |
| 包含登录 URL | 100% |
| 前端三层分类正确 | 100% |
| 前后端同步延迟  | < 5秒 |
| 配置格式统一   | 100% |
| 文档完整性    | 100% |
| 生产就绪     | 是    |

