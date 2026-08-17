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

## 主 agent 调度保证（关键需求）

主模型 `deepseek-v4-flash` 确认 `attachment: false`（不支持图片输入）。必须保证主 agent 在遇到读图需求时主动调度 `image-reader`。采用双保险：

### 1. 靠 description 自动触发（软机制）

opencode 会把所有可用 subagent 的 `description` 注入主 agent 的系统上下文。主 agent 通过 `task` 工具以 `subagent_type` 调度 subagent。`image-reader` 的 description 前载触发词（image / screenshot / 截图 / 读图 / OCR / 图表），让主 agent 在视觉任务时自主选择调度。

### 2. 全局 AGENTS.md 硬规则（硬机制，确保）

在 `~/.config/opencode/AGENTS.md`（当前不存在，新建；作用于所有会话）加入强制规则：

```markdown
# 读图调度规则（硬性）

- 当前主模型（deepseek 系列）不支持图片输入，无法直接查看图片/截图。
- 当用户附加图片、提供图片/截图路径，或任务涉及 OCR、UI 截图分析、图表/视觉理解时，
  必须通过 `task` 工具调度 `image-reader` subagent（subagent_type: "image-reader"）。
- 将 `image-reader` 的返回作为读图结论直接转发给用户，不得自己声称"看到了图片"。
```

### 注意

- 修改全局 `~/.config/opencode/AGENTS.md` 会影响**所有 opencode 项目**（全局规则语义）。因为 image-reader 是全局 agent，该保证也随之全局生效，符合预期。
- 若用户只想对当前项目生效，则把上述规则写入项目根 `AGENTS.md` 代替。

## 不做的事

- 不改主 agent / 其他 agent（除新增全局 AGENTS.md 规则）
- 不改 `opencode.json` / 不新增 provider
- 不写业务代码、不接 MCP
- 不动 LocalMind App

## 验证方式

1. 确认文件位于 `~/.config/opencode/agent/image-reader.md`
2. 确认全局规则写入 `~/.config/opencode/AGENTS.md`
3. 重启 opencode 后，`@image-reader` 可被调度
4. 用带图片的任务验证（如 `@image-reader 分析 <截图路径>`）
5. 验证主 agent 自动调度：直接给主 agent 一个图片路径任务（不显式 @），确认其通过 task 工具调度 image-reader 并转发结果
