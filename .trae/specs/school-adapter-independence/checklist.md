# Checklist

## 阶段零：基线与兼容收敛

- [ ] 已明确 `backend/python_import_service/adapters/` 为源码目录
- [ ] 已明确 `backend/python_import_service/data/school_configs/` 与 `data/scripts/` 为发布产物目录
- [ ] `/v1` 与 `/api` 兼容字段清单完成并冻结
- [ ] 现有 Flutter 导入主链路回归通过

## 阶段一：框架搭建

- [ ] `backend/python_import_service/adapters/` 目录结构创建完成，包含所有必要子目录
- [ ] `school_config.schema.json` Schema 定义完成（兼容 shiguang 格式）
- [ ] `adapter_test.schema.json` Schema 定义完成
- [ ] `school_index.proto` Protobuf 定义完成
- [ ] `base_parser.py` 解析器基类实现完成
- [ ] `utils.py` 通用工具函数实现完成（周次解析、节次解析等）
- [ ] `test_runner.py` 测试运行器实现完成

## 阶段二：数据迁移

### 2.1 shiguang_warehouse 迁移

- [ ] `root_index.yaml` 复制到 `adapters/index/`
- [ ] `migration_map.yaml` 建立完成并包含来源映射与许可证字段
- [ ] 正方教务通用适配迁移完成
- [ ] 超星教务通用适配迁移完成
- [ ] 青果教务通用适配迁移完成
- [ ] URP教务通用适配迁移完成
- [ ] 强智教务通用适配迁移或补齐完成
- [ ] A-F 开头学校迁移完成
- [ ] G-L 开头学校迁移完成
- [ ] M-R 开头学校迁移完成
- [ ] S-Z 开头学校迁移完成

### 2.2 当前项目配置迁移

- [ ] sora 配置迁移到 `adapters/general/systems/`
- [ ] xjtu 配置迁移到 `adapters/undergraduate/schools/`

### 2.3 Class-Schedule-Flutter 学校迁移

- [ ] 南京大学（本科教务）适配完成
- [ ] 南京大学（研究生教务）适配完成
- [ ] 东南大学适配完成
- [ ] 上海交通大学适配完成
- [ ] 西北农林科技大学适配完成
- [ ] 中国人民大学适配完成

### 2.4 AI Schedule 学校迁移

- [ ] AI Schedule 与 shiguang_warehouse 去重分析完成
- [ ] 武汉大学配置和脚本迁移完成
- [ ] 山东大学配置和脚本迁移完成
- [ ] 郑州大学配置和脚本迁移完成
- [ ] 哈尔滨工业大学配置和脚本迁移完成
- [ ] 其他独有学校迁移完成（约 30 所）

### 2.5 迁移验收

- [ ] 至少 150 所学校配置迁移完成
- [ ] 所有迁移的配置符合 Schema 定义
- [ ] 每个教务系统都有 README 说明文档

## 阶段三：数据完善

- [ ] 所有学校包含 `import_url`（登录网站）字段
- [ ] URL 可访问性批量验证完成
- [ ] 失效 URL 记录并处理完成
- [ ] 所有配置格式统一
- [ ] 数据来源和维护者信息标注完成
- [ ] 所有配置补齐 `source_path` 和 `license` 字段

## 阶段四：前后端同步

- [ ] `SchoolService` 正确读取发布产物目录并可用
- [ ] `/v1/config/schools` 的 level 字段不再硬编码
- [ ] 配置热重载功能正常工作
- [ ] 所有 API 端点正常返回数据
- [ ] 版本号和更新时间字段添加完成
- [ ] `publish.py` 可将 `adapters/` 正确编译到运行时产物目录
- [ ] adapters→runtime 字段映射规则实现并验证通过
- [ ] 初始 `schools.builtin.json` 生成完成
- [ ] 增量更新检测功能实现
- [ ] 前端集成同步逻辑完成
- [ ] 运行时目录已治理为发布产物目录（含防手改约束）

## 阶段五：发布流程

- [ ] `publish.py` 脚本正常同步配置到后端
- [ ] 前端学校列表自动生成正常
- [ ] 变更日志自动生成完成
- [ ] 许可证审计报告生成并通过
- [ ] 适配器开发指南文档完成
- [ ] 贡献指南文档完成
- [ ] 各教务系统适配说明完成

## 阶段六：测试验证

- [ ] 正方系统测试数据添加完成
- [ ] 强智系统测试数据添加完成
- [ ] URP系统测试数据添加完成
- [ ] 超星系统测试数据添加完成
- [ ] 青果系统测试数据添加完成
- [ ] 所有测试用例通过
- [ ] 端到端导入流程验证通过
- [ ] 前后端数据同步验证通过
- [ ] `/v1` 与 `/api` 双接口兼容回归通过
- [ ] 无回归问题

## 最终验收

- [ ] 适配器目录与主体项目清晰分离
- [ ] 新增学校适配流程文档化
- [ ] 所有代码通过 lint 检查
- [ ] 所有测试通过
- [ ] 支持学校总数达到 150+
- [ ] 登录 URL 覆盖率 100%
- [ ] 前后端同步延迟 < 5秒
- [ ] 来源可追溯率 100%（含 source/source_path/license）
