# LocalMind 项目指南

## 构建与测试命令

```bash
cd LocalMind
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# 单元测试（快）
swift test

# 生成 Xcode 工程
xcodegen generate
```

## ⚠️ 必须遵守：UI 测试运行方式

**不要直接运行 `xcodebuild test`** 跑 UI 测试套件——在 iOS 26.5 模拟器上会无限挂起（数小时）。

原因：iOS 26.5 模拟器的 `backboardd` 反复崩溃（`SimFramebuffer` 系统 bug）导致 XCUITest runner 死锁。详见 `docs/superpowers/specs/2026-08-13-xcode26-ui-test-hang-diagnosis.md`。

**正确做法**：用 `run-uitests.sh`（自动用 iOS 26.4 设备 + 超时保护）：

```bash
cd LocalMind
./run-uitests.sh                    # 完整 UI 套件
./run-uitests.sh <用例名>            # 指定用例
```

## 测试命令速查

| 目的 | 命令 | 位置 |
|---|---|---|
| 单元测试 | `swift test` | LocalMind/ |
| UI 测试 | `./run-uitests.sh` | LocalMind/ |
| 构建 App | `xcodegen generate && xcodebuild ... build` | LocalMind/ |

## 架构要点

- 通用对话是唯一入口，Agent 通过 ToolRegistry 调用工具（含 WorkflowTool）
- 测试用依赖注入：ChatService/WorkflowEngine/ToolRegistry 支持注入 mock
- 逻辑层保持 SwiftPM 可测（UI 层依赖 Xcode 环境）
- 云端 API 路由：CloudAPIService 封装 OpenAI 兼容调用，ChatService 按优先级：工具调用 → 云 API → mock 回复

## 项目状态

完整项目状态见 `docs/PROJECT_STATUS.md`（上下文压缩文档，含功能清单、设计决策、已知限制）。
