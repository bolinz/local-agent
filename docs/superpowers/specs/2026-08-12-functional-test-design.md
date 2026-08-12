# LocalMind 全链路功能测试设计

- 日期：2026-08-12
- 范围：MVP 全功能（意图解析、工具系统、工作流引擎、Agent/Skill 配置、对话闭环、UI）

## 测试分层

```
L1 单元测试  纯逻辑：意图解析 / Workflow模型 Codable / WorkflowTool解析 / TemplateStore
L2 集成测试  服务层：ChatService 对话→工具分发→工作流创建 闭环（注入 mock registry）
L3 UI 测试   端到端：导航 / 模板导入 / 设置编辑 / 聊天收发（真实渲染断言）
```

## 现有覆盖盘点

| 模块 | 现有测试 | 缺口 |
|---|---|---|
| IntentParser | 6 ✅ | 边界：空串、纯英文、无匹配 |
| WorkflowEngine | 8 ✅ | 无 |
| AgentConfig / SkillStore | 6 ✅ | 无 |
| ToolRegistry | 无 | 注册/查找/全量 |
| WorkflowTool | 无 | trigger/steps 解析、创建流程 |
| ChatService | 无 | **核心闭环未测**：输入→工具分发→工作流创建→回复 |
| Workflow 模型 | 间接 | 显式 Codable roundtrip |
| TemplateStore | 无 | 模板内容加载 |
| UI | 2 ✅ | 工作流页交互、设置编辑 |

## 待新增测试

### L1 单元
1. `ToolRegistryTests`：register/tool(for:)/allTools
2. `WorkflowToolTests`：parseTrigger（cron/event/manual）、parseSteps（单步/多步/参数）、createWorkflow 流程
3. `WorkflowModelTests`：Workflow/Step/Log Codable roundtrip
4. `TemplateStoreTests`：模板数量、含工作流、trigger 正确
5. `IntentParserTests` 补充边界

### L2 集成
6. `ChatServiceTests`（注入 mock registry）：
   - 普通聊天 → 兜底回复
   - 提醒意图 → reminder 工具被调用、回复含工具标记
   - 周期意图 → workflow 工具被调用、参数正确
   - 历史记录 / clearHistory

### L3 UI
7. 工作流页：模板库存在 → 进入模板详情 → 导入 → 列表出现该工作流
8. 设置页：编辑 Agent 配置 / Skill 开关

## 可测试性调整（最小侵入）
- `ChatService`：`private init()` → 可注入 `ToolRegistry`（保留 `shared` 默认）
- 其余依赖现有 `MockTool` 注入模式

## 实施顺序
1. ChatService 依赖注入改造
2. L1 单元测试（ToolRegistry / WorkflowTool / WorkflowModel / TemplateStore + 边界）
3. L2 ChatService 集成测试
4. L3 UI 测试扩展
5. 全量 `swift test` + `xcodebuild test` 验证
