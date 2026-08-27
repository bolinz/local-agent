# LocalMind 项目状态文档

> 最后更新：2026-08-27
> 用途：上下文压缩——快速恢复项目全貌，供后续会话使用

---

## 项目概览

**LocalMind Agent OS** — 开源、免费、运行在 iPhone 上的本地 AI Agent。用自然语言创建自动化任务，数据留在设备上。

- **仓库**：https://github.com/bolinz/local-agent （公开）
- **语言**：Swift 5.9 / SwiftUI / iOS 17+
- **构建**：XcodeGen + SwiftPM + xcodebuild
- **测试**：79 单元测试 + 6 UI 测试
- **当前分支**：main（13 个 PR 已合并）

## 目录结构

```
LocalMind/
├── Package.swift                    # SwiftPM 包定义
├── project.yml                      # XcodeGen 配置（iOS/macOS targets）
├── run-uitests.sh                   # UI 测试运行器（规避 Xcode 26 bug）
├── Assets.xcassets/                 # App 图标（indigo→purple 渐变 + brain）
├── Sources/
│   ├── LocalMindApp.swift          # App 入口（@main）
│   ├── Agent/
│   │   ├── LocalMindShortcuts.swift # Siri/Shortcuts（AppIntents）
│   │   ├── Tool.swift              # Tool 协议
│   │   ├── ToolRegistry.swift      # 工具注册表
│   │   ├── ToolError.swift         # 工具错误类型
│   │   ├── IntentParser.swift      # 意图解析
│   │   ├── CalendarTool.swift      # 日历工具（MVP）
│   │   ├── ReminderTool.swift      # 提醒工具（MVP）
│   │   ├── NotificationTool.swift  # 通知工具（MVP）
│   │   ├── WorkflowTool.swift      # 工作流工具
│   │   └── SkillStore.swift        # Skill 存储
│   ├── Models/
│   │   ├── ChatMessage.swift       # 消息模型（含 attachments）
│   │   ├── ChatSession.swift       # 会话模型
│   │   ├── MessageAttachment.swift # 附件模型
│   │   ├── Workflow.swift          # 工作流模型
│   │   ├── AgentProfile.swift      # Agent 配置（含 DataPolicy）
│   │   ├── ModelType.swift         # 本地模型类型
│   │   └── ModelProvider.swift     # 外部 provider 模型
│   ├── Services/
│   │   ├── ChatService.swift       # 对话服务（工具调用+云API+mock）
│   │   ├── CloudAPIService.swift   # 云端 API 封装（OpenAI 兼容）
│   │   ├── AgentStore.swift        # Agent 配置持久化
│   │   ├── SessionStore.swift      # 会话持久化
│   │   ├── ModelConfigStore.swift  # 模型 provider 持久化
│   │   ├── AttachmentStore.swift   # 附件沙盒存储
│   │   ├── ModelManager.swift      # 本地模型管理（模拟）
│   │   ├── ModelRouter.swift       # 模型路由/描述
│   │   ├── StorageService.swift    # UserDefaults/文件存储
│   │   ├── WorkflowEngine.swift    # 工作流引擎
│   │   ├── TemplateStore.swift     # 工作流模板
│   │   ├── NotificationService.swift # 通知服务（POC）
│   │   └── PermissionService.swift # 权限服务
│   └── Views/
│       ├── ContentView.swift       # 主视图（Tab 栏 + WorkflowListView）
│       ├── ChatView.swift          # 对话页（流式打字+附件+切换器）
│       ├── QuickInputBar.swift     # 输入栏（多行+附件选择）
│       ├── AttachmentBubbleView.swift # 附件消息展示
│       ├── AgentModelSwitcher.swift # Agent/模型切换器
│       ├── AgentViews.swift        # Agent 管理 + Skills 详情
│       ├── ModelViews.swift        # 模型管理（本地/外部）
│       ├── VisualComponents.swift  # 通用组件（渐变图标/气泡/记忆条）
│       ├── ColorExtensions.swift   # 跨平台颜色扩展
│       └── WorkflowDetailView.swift # 工作流详情/日志
├── Tests/                           # 79 个单元测试
├── UITests/                         # 6 个 UI 测试
└── docs/                            # 设计文档 + backlog
```

## 已完成功能（13 个 PR，main 分支）

### 核心功能
| 功能 | 状态 | PR |
|---|---|---|
| 沉浸式对话页（空态 orb/chips/渐变） | ✅ | #1 |
| 工作流页卡片化（渐变图标/新建/导入） | ✅ | #1 |
| 设置页 → Agent 管理（列表/详情/新建） | ✅ | #1 |
| 模型管理（本地列表/外部 provider/模型选择器） | ✅ | #1 |
| 会话持久化（ChatSession + SessionStore） | ✅ | #1 |
| 多 Agent 配置（AgentProfile + AgentStore） | ✅ | #1 |
| 新建会话按钮 | ✅ | #2 |
| 对话页 Agent/模型切换器 | ✅ | #2 |
| 多行输入 + 图片/文件附件 | ✅ | #2 |
| Skills 详情页（指令内容+所需工具） | ✅ | #2 |
| 流式打字效果 | ✅ | #5, #6 |
| Siri/Shortcuts 集成 | ✅ | #9 |
| iPad 分屏适配（NavigationSplitView） | ✅ | #10 |
| 云端 API 路由（MiMo 真实推理） | ✅ | #13 |

### 修复与优化
| 修复 | PR |
|---|---|
| UILaunchScreen 缺失导致上下黑边 | #1 |
| 自定义 Tab 栏（点击稳定性） | #1 |
| TabView 残留椭圆（ZStack 切换） | #1 |
| ChatMessage 向后兼容解码 | #2 |
| AttachmentStore 文件名唯一化 + 路径消毒 | #2 |
| AgentProfile Codable 向后兼容 | #2 |
| App 图标（indigo→purple 渐变） | #3 |
| 死代码清理（-281 行） | #3 |
| 本地化（70+ key） | #4 |
| 流式打字防重复发送 + 新建会话重置 | #6 |
| Launch Screen 品牌化（indigo 背景色） | #7 |
| 附件加载进度指示器 | #12 |

### 文档
| 文档 | PR |
|---|---|
| 英文 README | #11 |
| MIT LICENSE | #11 |
| CONTRIBUTING.md | #11 |
| P2/P3 设计 backlog | #3 |

## 关键设计决策

- **纯 subagent 软机制**：不修改全局 AGENTS.md，靠 description 注入触发
- **双模式原生风**：跟随系统浅深色，渐变卡片/胶囊统一设计语言
- **Agent 行为可视化**：思考卡片 + 工具调用卡片 + 记忆条
- **会话持久化**：ChatSession JSON → UserDefaults（无数据库）
- **附件存储**：本地沙盒 Documents/Attachments/（不传 API）
- **云端 API**：OpenAI 兼容格式，通过 ModelConfigStore 配置
- **GitFlow**：main 受保护（pre-push hook + GitHub 分支保护），变更必须走 PR

## 测试覆盖率

| 层 | 测试数 | 覆盖率 |
|---|---|---|
| 单元测试 | 79 | 逻辑层 90-100% |
| UI 测试 | 6 | App 总体 39.69% |
| 附件功能 | - | AttachmentBubbleView 59% / MessageAttachment 100% / AttachmentStore 100% |

## 配置与环境

- **构建**：`xcodegen generate && xcodebuild -scheme LocalMind ... build`
- **单元测试**：`swift test`（79 tests，macOS target）
- **UI 测试**：`./run-uitests.sh`（iOS 26.4，规避 Xcode 26.5 挂起）
- **实机安装**：`xcrun devicectl device install app --device <UDID> <app-path>`
- **Xcode**：26.6，iOS 26.5 SDK，iOS 26.4 runtime（UI 测试）
- **设备**：iPhone 17 Pro（UDID: 48AEB41E-DE68-5ADE-BA53-90011C3722B0）

## 待完成项（P3 远景）

| 项 | 说明 | 复杂度 |
|---|---|---|
| P3.1 MLX 本地推理 | 替换 mock 回复为真正本地 3B 模型推理 | 极高 |
| P3.3 视觉记忆系统 | 跨会话上下文摘要 | 高 |
| P3.4 MCP 支持 | 外部工具扩展 | 高 |
| P3.5 HomeKit/HealthKit/Location | 系统框架集成 | 中 |
| P3.6 真实工作流调度 | BGTaskScheduler + 通知 | 中 |
| P3.7 多 Agent 运行时隔离 | ChatService 重构为多实例 | 中 |
| P3.8 插件系统 | 自定义 Skill 包导入 | 高 |

## 已知限制

- **模拟回复**：未配置外部模型时使用硬编码 mock 回复
- **工具调用非真 Agent**：IntentParser 是规则匹配，不是 LLM 理解
- **附件不传 AI**：图片/文件仅本地存储和展示，不发送给模型
- **工作流简化**：trigger 只支持 cron（contains "每"），无事件驱动
- **UI 覆盖率**：App 总体 39.69%（Views 层依赖 UI 测试）
