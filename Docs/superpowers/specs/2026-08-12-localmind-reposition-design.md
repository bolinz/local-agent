# LocalMind 重定位设计文档

- 日期：2026-08-12
- 状态：已确认
- 主题：从"小白零配置应用"重定位为"极客开源本地 AI Agent"

## 背景

原设计面向小白用户（省钱管家/带娃神器/长辈关怀/自由聊天四个场景），68 元一次性买断，文案隐藏技术词。存在根本矛盾：文档卖点是"Agent OS + 工作流编辑器 + 15+ 工具"（极客诉求），但场景化引导和"隐藏技术词"策略服务小白用户。代码处于 POC 骨架阶段，且 App 因缺少 `@main` 入口和场景选择死锁而无法运行。

## 决策记录

| 维度 | 决策 |
|---|---|
| 核心用户 | 技术隐私党（极客） |
| 主战场 | Agent 自动化（能自动执行任务的 AI） |
| 场景 | 废弃强制场景引导，改为工作流模板库 |
| 平台 | iOS 优先 |
| 推理策略 | 本地优先 + 可选云端路由（用户自带 API key） |
| 商业模式 | 完全免费 |
| 开源 | 完全开源 |
| 工作流形态 | 自然语言创建 + 可读化查看/编辑 |
| 对话形态 | 通用对话是唯一入口，创建工作流是 WorkflowTool |

## 产品定位

> LocalMind 是一个开源、免费、运行在 iPhone 上的本地 AI Agent——用自然语言创建能自动执行任务的自动化助手，你的数据由你掌控。

## 架构

三层声明式结构（工具系统 → Skill 包 → Agent 配置）：

```
对话运行时（Agent 实例）
├── Agent 配置    system prompt / 默认工具集 / 推理偏好 / 数据策略
└── Skill 包      元数据 + instructions + 依赖工具与权限，可分享导入
      └── 工具系统   Tool 协议 + ToolRegistry
            ├── CalendarTool / ReminderTool / NotificationTool（MVP）
            ├── HealthKitTool / HomeKitTool / LocationTool / FileTool / WebTool
            └── WorkflowTool（Agent 可调用创建/修改/开关工作流）
```

推理层：ModelRouter（本地 MLX / 云端路由 / 强制本地数据）。

## 信息架构

- Tab 1 对话（唯一主入口，通用聊天 + 工具调用展示）
- Tab 2 工作流（管理 Agent 创建的自动化任务：列表/开关/日志/模板库/分享导入）
- Tab 3 设置（Agent 配置 / Skills / 工具权限 / 云端路由 / 模型 / 关于+GitHub）

## iOS 后台自动化边界（诚实呈现）

- 后台运行时长受限 → 短任务设计
- 定时触发仅推断性调度 → BGTaskScheduler + 本地通知兜底
- 事件监听受限 → 依赖原生框架监听能力
- 沙盒文件系统 → 工具只操作 App 沙盒与系统授权数据

## MVP 范围（Phase 1）

核心闭环：App 入口修复 → 通用对话 + 3 个本地工具（Calendar/Reminder/Notification）→ WorkflowTool 创建持久化工作流 → Agent 配置 + Skill 声明 → 模板库。

明确砍掉：真实 MLX 推理、云端 API 路由、HealthKit/HomeKit/位置、完整 BGTask 调度。

## 落地顺序

1. Phase 0 工程基础（git init / .gitignore / 环境验证）
2. Phase 1 App 入口修复
3. Phase 2 对话 + 工具调用闭环
4. Phase 3 工作流引擎 + WorkflowTool + 模板库
5. Phase 4 Agent/Skill 配置层
6. Phase 5 验证与收尾（单元测试）
