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

## 不做的事

- 不改主 agent / 其他 agent
- 不改 `opencode.json` / 不新增 provider
- 不写业务代码、不接 MCP
- 不动 LocalMind App

## 验证方式

1. 确认文件位于 `~/.config/opencode/agent/image-reader.md`
2. 重启 opencode 后，`@image-reader` 可被调度
3. 用带图片的任务验证（如 `@image-reader 分析 <截图路径>`）
