# Tasks

## 阶段零：基线与兼容收敛

- [ ] Task 0: 明确源码目录与发布产物目录边界
  - [ ] SubTask 0.1: 约定 `backend/python_import_service/adapters/` 为唯一源码目录
  - [ ] SubTask 0.2: 约定 `backend/python_import_service/data/school_configs/` 与 `data/scripts/` 为发布产物目录
  - [ ] SubTask 0.3: 梳理并锁定 `/v1` 与 `/api` 兼容字段清单（含 level/initialUrl/extractScriptUrl）
  - [ ] SubTask 0.4: 增加兼容性回归检查项，确保现有 Flutter 导入链路不回归

## 阶段一：框架搭建

- [ ] Task 1: 创建适配器目录结构（三层分类）
  - [ ] SubTask 1.1: 创建 `backend/python_import_service/adapters/` 根目录
  - [ ] SubTask 1.2: 创建 `adapters/core/` 核心框架目录
  - [ ] SubTask 1.3: 创建 `adapters/undergraduate/` 本/专科目录（schools/、scripts/）
  - [ ] SubTask 1.4: 创建 `adapters/master/` 硕士目录（schools/、scripts/）
  - [ ] SubTask 1.5: 创建 `adapters/general/` 通用目录（systems/、scripts/）
  - [ ] SubTask 1.6: 创建 `adapters/schemas/` Schema 定义目录
  - [ ] SubTask 1.7: 创建 `adapters/tests/` 测试目录
  - [ ] SubTask 1.8: 创建 `adapters/index/` 索引目录
  - [ ] SubTask 1.9: 创建 `adapters/scripts/` 工具脚本目录

- [ ] Task 2: 定义配置 Schema
  - [ ] SubTask 2.1: 创建 `school_config.schema.json` 学校配置 Schema
  - [ ] SubTask 2.2: 创建 `adapter_test.schema.json` 测试数据 Schema
  - [ ] SubTask 2.3: 创建 `school_index.proto` Protobuf 索引定义
  - [ ] SubTask 2.4: 编写 Schema 文档说明

- [ ] Task 3: 实现核心框架
  - [ ] SubTask 3.1: 创建 `base_parser.py` 解析器基类
  - [ ] SubTask 3.2: 创建 `utils.py` 通用工具函数（周次解析、节次解析等）
  - [ ] SubTask 3.3: 创建 `test_runner.py` 测试运行器

- [ ] Task 4: 创建 README 文档框架
  - [ ] SubTask 4.1: 创建主 README.md（项目概述、内部规范说明）
  - [ ] SubTask 4.2: 创建 `undergraduate/README.md`（本/专科适配说明）
  - [ ] SubTask 4.3: 创建 `master/README.md`（硕士适配说明）
  - [ ] SubTask 4.4: 创建 `general/README.md`（通用系统适配说明）
  - [ ] SubTask 4.5: 添加贡献者指南
  - [ ] SubTask 4.6: 添加 SHIGUANG 项目声明

## 阶段二：数据迁移

### 2.1 迁移 shiguang_warehouse（最高优先级）

- [ ] Task 5: 迁移 shiguang_warehouse 索引和配置
  - [ ] SubTask 5.1: 复制 `root_index.yaml` 到 `adapters/index/`
  - [ ] SubTask 5.2: 创建迁移脚本解析 YAML 格式
  - [ ] SubTask 5.3: 批量转换 adapters.yaml 为 JSON 格式
  - [ ] SubTask 5.4: 按 category 字段分类到 undergraduate/master/general
  - [ ] SubTask 5.5: 生成 `backend/python_import_service/adapters/index/migration_map.yaml`（source_repo/source_path/license/target_path/maintainer）

- [ ] Task 6: 迁移 shiguang_warehouse 通用教务系统（general）
  - [ ] SubTask 6.1: 迁移正方教务通用适配
  - [ ] SubTask 6.2: 迁移超星教务通用适配
  - [ ] SubTask 6.3: 迁移青果教务通用适配
  - [ ] SubTask 6.4: 迁移URP教务通用适配
  - [ ] SubTask 6.5: 迁移或补齐强智教务通用适配（来源缺失时从其他仓库补齐）

- [ ] Task 7: 迁移 shiguang_warehouse 本/专科学校（undergraduate）
  - [ ] SubTask 7.1: 迁移 A-F 开头学校
  - [ ] SubTask 7.2: 迁移 G-L 开头学校
  - [ ] SubTask 7.3: 迁移 M-R 开头学校
  - [ ] SubTask 7.4: 迁移 S-Z 开头学校

- [ ] Task 8: 迁移 shiguang_warehouse 硕士学校（master）
  - [ ] SubTask 8.1: 识别并迁移研究生系统适配

### 2.2 迁移当前项目已有配置

- [ ] Task 9: 迁移 sora 和 xjtu 配置
  - [ ] SubTask 9.1: 将 `sora.json` 迁移到 `adapters/general/systems/`
  - [ ] SubTask 9.2: 将 `xjtu.json` 迁移到 `adapters/undergraduate/schools/`
  - [ ] SubTask 9.3: 迁移对应的 provider 脚本

### 2.3 迁移 Class-Schedule-Flutter 学校

- [ ] Task 10: 迁移南京大学适配
  - [ ] SubTask 10.1: 创建本科教务配置（undergraduate）
  - [ ] SubTask 10.2: 创建研究生教务配置（master）
  - [ ] SubTask 10.3: 迁移所有脚本文件

- [ ] Task 11: 迁移其他 Class-Schedule-Flutter 学校
  - [ ] SubTask 11.1: 迁移东南大学（undergraduate）
  - [ ] SubTask 11.2: 迁移上海交通大学（master）
  - [ ] SubTask 11.3: 迁移西北农林科技大学（undergraduate）
  - [ ] SubTask 11.4: 迁移中国人民大学（master）

### 2.4 迁移 AI Schedule 重点学校（去重）

- [ ] Task 12: 分析 AI Schedule 与 shiguang_warehouse 重叠
  - [ ] SubTask 12.1: 提取 AI Schedule 学校列表
  - [ ] SubTask 12.2: 与 shiguang_warehouse 对比去重
  - [ ] SubTask 12.3: 生成待迁移学校清单（按 level 分类）

- [ ] Task 13: 迁移 AI Schedule 独有学校
  - [ ] SubTask 13.1: 迁移武汉大学（undergraduate）
  - [ ] SubTask 13.2: 迁移山东大学（undergraduate）
  - [ ] SubTask 13.3: 迁移郑州大学（undergraduate）
  - [ ] SubTask 13.4: 迁移哈尔滨工业大学（undergraduate）
  - [ ] SubTask 13.5: 迁移其他独有学校

## 阶段三：数据完善

- [ ] Task 14: 补充登录网站信息
  - [ ] SubTask 14.1: 检查所有学校是否有 `import_url`
  - [ ] SubTask 14.2: 从 AI Schedule 补充缺失 URL
  - [ ] SubTask 14.3: 从 Class-Schedule-Flutter 补充缺失 URL
  - [ ] SubTask 14.4: 手动查找剩余缺失 URL
  - [ ] SubTask 14.5: 创建 URL 验证脚本

- [ ] Task 15: 验证 URL 可访问性
  - [ ] SubTask 15.1: 批量检测所有 URL 可访问性
  - [ ] SubTask 15.2: 记录失效 URL
  - [ ] SubTask 15.3: 尝试查找替代 URL

- [ ] Task 16: 统一配置格式
  - [ ] SubTask 16.1: 验证所有配置符合 Schema
  - [ ] SubTask 16.2: 补充缺失字段（level、initial 等）
  - [ ] SubTask 16.3: 标注数据来源和维护者
  - [ ] SubTask 16.4: 补齐 `source_path` 与 `license` 字段
  - [ ] SubTask 16.5: 添加 SHIGUANG 来源声明

## 阶段四：前后端同步

- [ ] Task 17: 改造后端学校服务
  - [ ] SubTask 17.1: 修改 `SchoolService` 读取发布产物目录（`data/school_configs` + `data/scripts`）
  - [ ] SubTask 17.2: 实现按 level 分类返回数据
  - [ ] SubTask 17.3: 修复 `/v1/config/schools` 中 level 硬编码问题
  - [ ] SubTask 17.4: 实现配置热重载功能
  - [ ] SubTask 17.5: 更新 API 端点适配新结构
  - [ ] SubTask 17.6: 添加版本号和更新时间字段

- [ ] Task 18: 实现适配器发布与前端同步机制
  - [ ] SubTask 18.1: 创建 `publish.py`，将 `adapters/` 编译为运行时产物目录
  - [ ] SubTask 18.2: 生成初始 `schools.builtin.json`
  - [ ] SubTask 18.3: 实现增量更新检测
  - [ ] SubTask 18.4: 前端集成同步逻辑
  - [ ] SubTask 18.5: 实现并测试 adapters→runtime 字段映射（title/import_url/delay_seconds 等）

- [ ] Task 19: 旧目录治理
  - [ ] SubTask 19.1: 将 `backend/python_import_service/data/school_configs/` 与 `data/scripts/` 标记为发布产物目录
  - [ ] SubTask 19.2: 增加“禁止手工编辑产物目录”校验
  - [ ] SubTask 19.3: 更新相关测试用例

## 阶段五：发布流程

- [ ] Task 20: 实现发布脚本
  - [ ] SubTask 20.1: 创建 `publish.py` 发布脚本
  - [ ] SubTask 20.2: 实现配置同步到后端服务
  - [ ] SubTask 20.3: 实现生成前端学校列表
  - [ ] SubTask 20.4: 生成变更日志
  - [ ] SubTask 20.5: 集成许可证审计并在失败时阻断发布

- [ ] Task 21: 完善文档
  - [ ] SubTask 21.1: 完善内部规范说明
  - [ ] SubTask 21.2: 完善贡献者指南
  - [ ] SubTask 21.3: 完善 SHIGUANG 声明
  - [ ] SubTask 21.4: 添加各教务系统适配说明
  - [ ] SubTask 21.5: 补充来源映射和许可证审计说明

## 阶段六：测试验证

- [ ] Task 22: 添加测试数据
  - [ ] SubTask 22.1: 为正方系统添加测试数据
  - [ ] SubTask 22.2: 为强智系统添加测试数据
  - [ ] SubTask 22.3: 为其他系统添加测试数据

- [ ] Task 23: 集成测试
  - [ ] SubTask 23.1: 验证后端服务正确读取配置
  - [ ] SubTask 23.2: 验证前端三层分类正确显示
  - [ ] SubTask 23.3: 验证前端搜索功能正常
  - [ ] SubTask 23.4: 端到端导入流程测试
  - [ ] SubTask 23.5: 验证前后端数据同步
  - [ ] SubTask 23.6: 验证 `/v1` 与 `/api` 双接口兼容回归通过

# Task Dependencies
- [Task 1] depends on [Task 0]
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 0, Task 2]
- [Task 4] depends on [Task 1]
- [Task 5-8] depends on [Task 1]
- [Task 9] depends on [Task 1]
- [Task 10-11] depends on [Task 1]
- [Task 12-13] depends on [Task 5, Task 6, Task 7, Task 8]
- [Task 14-16] depends on [Task 8, Task 9, Task 11, Task 13]
- [Task 17] depends on [Task 0, Task 3]
- [Task 18] depends on [Task 17]
- [Task 19] depends on [Task 18, Task 23]
- [Task 20] depends on [Task 18]
- [Task 22] depends on [Task 6, Task 13]
- [Task 23] depends on [Task 20, Task 22]
