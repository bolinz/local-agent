# LocalMind 待完善设计追踪

> 日期：2026-08-24
> 说明：P0/P1 修复在 feature/p0p1-bugfix 分支实施。P2/P3 记录于此，后续迭代处理。

---

## P2 — 锦上添花（非阻塞但提升体验）

| # | 功能 | 说明 | 优先级 |
|---|---|---|---|
| P2.1 | 流式打字效果 | 助手回复逐字显示（当前一次性返回），提升"AI 思考"感 | 中 |
| P2.2 | Launch Screen 自定义 | 添加 `UILaunchScreen` 配置，用 LocalMind 品牌色/Logo 替代白闪 | 中 |
| P2.3 | App 名称本地化 | 配置 `CFBundleDisplayName` 显示"LocalMind 智能助手"而非 bundle name | 低 |
| P2.4 | Siri/Shortcuts 集成 | 支持 App Intents，"Hey Siri 用 LocalMind ..." | 低 |
| P2.5 | iPad 分屏适配 | 真实适配 split view / slide over，当前仅 TARGETED_DEVICE_FAMILY 声明 | 低 |
| P2.6 | 文档国际化 | README 提供英文版；Contributing Guide / LICENSE 文件 | 低 |
| P2.7 | 附件进度展示 | 大文件上传时显示进度条（当前无反馈） | 低 |

## P3 — 远景（需要架构级改造）

| # | 功能 | 说明 | 阻塞项 |
|---|---|---|---|
| P3.1 | 真实 MLX 推理接入 | 替换 ChatService 模拟回复为真正的本地 LLM 推理 | 需要 MLX 框架集成、模型格式、GPU 加速 |
| P3.2 | 云端 API 路由 | 连接 OpenAI/Anthropic/Gemini 真实 API，用户填 key | 需要网络层、API 格式适配、安全存储 key |
| P3.3 | 视觉记忆系统 | 跨会话上下文摘要，AI "记住"重要对话 | 需要 embedding 模型、向量存储 |
| P3.4 | MCP 支持 | 连接外部 MCP 服务器扩展工具集 | 需要 MCP 协议客户端 |
| P3.5 | HomeKit/HealthKit/Location | 真实系统框架集成 | 需要权限申请、框架集成、测试 |
| P3.6 | 真实工作流调度 | BGTaskScheduler + 本地通知，定时/事件驱动 | 需要后台任务 API、通知权限 |
| P3.7 | 多 Agent 运行时隔离 | 真正的 system prompt / 工具集 / 推理偏好隔离 | 需要 ChatService 重构为多实例 |
| P3.8 | 插件系统 | 用户可导入自定义 Skill 包 | 需要 Skill 格式规范、沙盒、权限模型 |

---

## P0/P1 实施进度追踪

- [ ] P0.1: App 图标生成
- [ ] P0.2: 本地化硬编码 → NSLocalizedString
- [ ] P0.3: 死代码清理（NotificationService/ModelManager TODO、DataFlowService/DeviceDetectionService/DeviceInfo）
- [ ] P1.1: 工作流执行状态展示
- [ ] P1.2: 错误用户反馈（toast/alert）
- [ ] P1.3: 键盘交互（上滑收键盘）
- [ ] P1.4: 死代码清理（AgentConfig 残留测试引用）

---

*后续迭代：每个 P2/P3 独立 spec → plan → 实施 cycle。*
