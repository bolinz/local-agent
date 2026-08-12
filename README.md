# LocalMind Agent OS

开源、免费、运行在 iPhone 上的本地 AI Agent——用自然语言创建能自动执行任务的自动化助手，你的数据由你掌控。

## 定位

- **核心用户**：技术隐私党（极客）
- **主战场**：Agent 自动化（能自动执行任务的 AI）
- **平台**：iOS 优先（macOS 附带 target）
- **商业模式**：完全免费，完全开源
- **推理策略**：本地优先 + 可选云端路由（用户自带 API key）

## 架构

```
对话运行时（Agent 实例）
├── Agent 配置    system prompt / 默认工具集 / 推理偏好 / 数据策略
└── Skill 包      元数据 + instructions + 依赖工具与权限，可分享导入
      └── 工具系统   Tool 协议 + ToolRegistry
            ├── CalendarTool / ReminderTool / NotificationTool（MVP 已实现）
            ├── HealthKitTool / HomeKitTool / LocationTool / FileTool / WebTool（后续）
            └── WorkflowTool（Agent 可调用创建/修改/开关工作流）
```

- **通用对话是唯一入口**：用户说人话 → Agent 识别意图 → 调用对应工具（创建工作流也是 WorkflowTool）
- **工作流引擎**：结构化模型（trigger/steps/日志）+ JSON 持久化 + 模板库
- 详细设计见 `docs/superpowers/specs/2026-08-12-localmind-reposition-design.md`

## 目录结构

```
LocalMind/
├── Package.swift          # SwiftPM：库 + 单元测试（swift test）
├── project.yml            # XcodeGen：生成 iOS/macOS App target + UI 测试
├── run-uitests.sh         # UI 测试运行器（规避 Xcode 26 bug，见下方）
├── Sources/
│   ├── Agent/             # Tool 协议、ToolRegistry、意图解析、4 个工具、Agent/Skill 配置
│   ├── Models/            # ChatMessage、DeviceInfo、ModelType、Workflow
│   ├── Services/          # ChatService、WorkflowEngine、StorageService 等
│   └── Views/             # SwiftUI 界面（对话/工作流/设置）
├── Tests/                 # 单元测试
└── UITests/               # UI 测试（XCUITest）
docs/                      # 产品文档 + 设计/诊断文档（docs/superpowers/specs/）
```

## 构建

```bash
cd LocalMind

# 单元测试（快，SwiftPM）
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test

# 生成 Xcode 工程并构建 App
xcodegen generate
xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath build build
```

## 测试

### 单元测试（60 个）

```bash
cd LocalMind
swift test
```

覆盖三层：纯逻辑（意图解析/Workflow 模型/模板库）、服务层集成（ChatService 对话→工具→工作流闭环）、配置存储（Agent/Skill）。

### UI 测试（5 个）——必须用 `run-uitests.sh`

```bash
cd LocalMind
./run-uitests.sh              # 跑完整 UI 套件
./run-uitests.sh <用例名>     # 只跑指定用例（如 testChatSendsMessageAndGetsReply）
./run-uitests.sh --list       # 列出全部用例
```

**不要直接跑 `xcodebuild test`**，会挂死数小时。原因和规避见下文。

## 已知问题与规避

### ⚠️ Xcode 26 UI 测试挂死（重要）

**症状**：`xcodebuild test` 直接跑完整 UI 套件会无限挂起（数小时无响应）。

**根因**：iOS 26.5 模拟器运行时的 `backboardd`（UI 事件路由进程）反复崩溃（崩溃点 `SimFramebuffer.__SFBConnectionConnect`，SIGTRAP）。连续跑多个 UI 用例时崩溃累积导致 XCUITest runner 死锁。

**规避**：使用 **iOS 26.4 运行时**跑 UI 测试（`run-uitests.sh` 已封装）。已验证完整套件全部通过、零 backboardd 崩溃。

详细诊断：`docs/superpowers/specs/2026-08-13-xcode26-ui-test-hang-diagnosis.md`

### 其他

- 本机若无完整 Xcode（仅 CommandLineTools），App target 无法用 `xcodebuild` 验证，但 `swift test` 可跑。
- iOS 后台调度受限：工作流用本地通知 + 手动触发，不承诺后台常驻。

## 测试设计文档

- 功能测试设计：`docs/superpowers/specs/2026-08-12-functional-test-design.md`
- 产品重定位设计：`docs/superpowers/specs/2026-08-12-localmind-reposition-design.md`
