# 读图 Agent（image-reader）设计文档

> 日期：2026-08-17
> 范围：为 opencode 创建全局 subagent `image-reader`，模型使用小米 MiMo-V2.5，提供通用读图能力

## 背景

主模型（deepseek-v4-flash）不支持图片输入，无法直接查看截图/图片。用户需要一个能"读图"的 subagent，用来做 UI 截图分析、OCR、图表解读等视觉理解任务。

## 结论先行

- **provider 已就绪，无需改 opencode.json**：
  - `auth.json` 已有 `xiaomi-token-plan-cn` 认证（baseURL `https://token-plan-cn.xiaomimimo.com/v1`）
  - models.dev 内置该 provider（`@ai-sdk/openai-compatible`）
  - 环境变量 `MIMO_API_KEY` 存在
- **模型选择**：`xiaomi-token-plan-cn/mimo-v2.5`
  - 该 provider 的模型清单中，`mimo-v2.5` 是唯一 `attachment: true`、输入支持 `image` 的模型
  - `mimo-v2.5-pro` 在 models.dev 标注 `attachment: false`，不冒险使用
  - 已实测：用 `mimo-v2.5` 发送 base64 PNG，正确识别"红色图片"

## Agent 定义

位置：`~/.config/opencode/agent/image-reader.md`

```markdown
---
description: General-purpose image reader. Receives image/screenshot paths, describes content, extracts text, analyzes images, and answers questions about them. Use when the user attaches an image or provides an image file path - especially for UI screenshot analysis, OCR, chart/table interpretation, and any task requiring visual understanding.
mode: subagent
model: xiaomi-token-plan-cn/mimo-v2.5
---
```

## Prompt 要点

- 图片通过 `read` 工具读取文件路径获取（Read 工具支持图片输入）；也兼容对话中已附加图片的情况
- 输出使用中文，结构化：
  1. 内容概要
  2. 关键元素 / 布局
  3. 文字提取（OCR）
  4. 针对性结论（回答用户具体问题）
- 若用户无明确问题，给出客观描述而非猜测；不确定的地方明确说明
- 无图片时明确提示缺少图片输入

## 主 agent 如何调用 image-reader

主模型可能读图、也可能不读图（取决于主 agent 当前所用模型：如 `deepseek-v4-flash` 为 `attachment: false`，而 `deepseek-chat`/`deepseek-reasoner` 为 `attachment: true`）。**不引入任何硬规则**，采用 opencode 原生 subagent 软机制：

- opencode 会把所有可用 subagent 的 `description` 注入主 agent 的系统上下文。主 agent 通过 `task` 工具以 `subagent_type` 调度 subagent（与调度 `ios-builder` 同理）。
- `image-reader` 的 description 前载触发词（image / screenshot / 截图 / 读图 / OCR / 图表 / visual understanding），让主 agent 在需要视觉理解时自主选择调度。
- 主 agent 能直接处理图片时（attachment: true 模型）自行处理；不能时通过 task 工具调度 image-reader 并把其返回转发给用户。
- **不保证 100% 触发**（模型可能忘了调度）——这是 opencode subagent 的标准行为，与 ios-builder 一致。需要保险时用户可显式 `@image-reader 分析 <路径>`。

### 为什么不加硬规则

曾设计过"全局 AGENTS.md 强制调度规则"，评估后放弃，风险过大：

- **影响面太大**：全局规则作用于所有项目/会话，措辞不当即污染所有主 agent 行为
- **误判风险**：靠"自检能否看到图片"依赖模型主观判断，能读图的模型可能被强制转发、不能读图的却漏调
- **不必要的开销**：强制调度额外消耗 token/延迟
- **难以回滚**：关键能力绑定在一条全局规则上，后续改动风险高

## 不做的事

- 不改主 agent / 其他 agent
- 不改 `opencode.json` / 不新增 provider / 不新增全局 AGENTS.md
- 不写业务代码、不接 MCP
- 不动 LocalMind App

## 验证方式

1. 确认文件位于 `~/.config/opencode/agent/image-reader.md`
2. 重启 opencode 后，`@image-reader` 可被调度
3. 用带图片的任务验证（如 `@image-reader 分析 <截图路径>`）
4. 验证主 agent 自动调度：用 `attachment: false` 的模型（如 deepseek-v4-flash）给一个图片路径任务（不显式 @），观察其是否通过 task 工具调度 image-reader 并转发结果；用 `attachment: true` 的模型（如 deepseek-chat）重复，观察其是否直接处理
