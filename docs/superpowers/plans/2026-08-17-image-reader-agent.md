# image-reader 读图 Agent 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建全局 opencode subagent `image-reader`，用小米 MiMo-V2.5 提供通用读图能力（UI 截图分析、OCR、图表解读等）。

**Architecture:** 单一 markdown agent 文件放在 `~/.config/opencode/agent/`。模型用已认证的 `xiaomi-token-plan-cn/mimo-v2.5`（唯一 attachment: true 的图片模型）。纯 subagent 软机制，不改任何全局配置、不写硬规则。

**Tech Stack:** opencode agent 定义（frontmatter: description/mode/model）+ 中文 prompt 正文。

---

### Task 1: 创建 image-reader agent 文件

**Files:**
- Create: `~/.config/opencode/agent/image-reader.md`

- [ ] **Step 1: 确认目标目录存在**

Run: `ls ~/.config/opencode/agent/`
Expected: 列出已有 agent 文件（如 `ios-builder.md`）。目录不存在则先创建。

- [ ] **Step 2: 写入 agent 文件**

写入以下内容到 `~/.config/opencode/agent/image-reader.md`：

```markdown
---
description: General-purpose image reader. Receives image/screenshot paths, describes content, extracts text, analyzes images, and answers questions about them. Use when the user attaches an image or provides an image file path - especially for UI screenshot analysis, OCR, chart/table interpretation, and any task requiring visual understanding.
mode: subagent
model: xiaomi-token-plan-cn/mimo-v2.5
---

你是一个通用读图 agent，运行在小米 MiMo-V2.5 多模态模型上，能真正看到并理解图片内容。

## 图片获取方式

- 用户提供图片/截图路径时：用 `read` 工具读取该文件（Read 工具支持图片输入）。
- 图片已作为附件传入对话时：直接分析附件中的图片。
- 两者都没有时：明确提示"缺少图片输入"，不要凭空猜测。

## 输出规范（中文，结构化）

按以下结构组织回答：

1. **内容概要**：一句话说明图片是什么。
2. **关键元素 / 布局**：描述主要视觉元素、空间布局、颜色、文字层级。
3. **文字提取（OCR）**：逐条列出图中可见的文字内容。
4. **针对性结论**：若用户问了具体问题，给出明确回答；否则给出客观观察结论。

## 准则

- 客观描述，不确定的内容明确标注，不做过度推断。
- 若用户无明确问题，给出完整客观描述而非只挑亮点。
- 回答保持简洁，突出对用户有用的信息。
```

- [ ] **Step 3: 校验 frontmatter 字段合法**

Run: `python3 -c "import re; t=open('$HOME/.config/opencode/agent/image-reader.md').read(); fm=t.split('---')[1]; print(fm); assert 'description:' in fm and 'mode: subagent' in fm and 'model:' in fm; print('OK')"`
Expected: 打印 frontmatter 且输出 OK

- [ ] **Step 4: 提交设计相关变更**

本任务不改 git 仓库内文件（agent 在全局目录，不纳入本仓库），无需 commit。

---

### Task 2: 端到端验证读图能力

**Files:**
- 无需新文件；验证用临时 PNG

- [ ] **Step 1: 生成一张已知内容的测试图**

Run:
```bash
python3 -c "
import base64, struct, zlib
def chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c))
ihdr = struct.pack('>IIBBBBB', 64, 64, 8, 2, 0, 0, 0)
raw = b''.join(b'\x00' + b'\x00\xff\x00'*64 for _ in range(64))  # 绿色
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
open('/var/folders/5t/6b2npv2d0jd1r7gzc8d1rzwh0000gn/T/opencode/test_green.png','wb').write(png)
print('written')
"
```

- [ ] **Step 2: 用 mimo-v2.5 API 直测读图（不经 opencode，验证模型通路）**

Run:
```bash
IMG_B64=$(base64 < /var/folders/5t/6b2npv2d0jd1r7gzc8d1rzwh0000gn/T/opencode/test_green.png)
curl -s -X POST "https://token-plan-cn.xiaomimimo.com/v1/chat/completions" \
  -H "Authorization: Bearer $MIMO_API_KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"mimo-v2.5\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"这张图是什么颜色?用一句话回答\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"data:image/png;base64,$IMG_B64\"}}]}],\"max_tokens\":100}"
```
Expected: 返回 content 含"绿色"或等义表述，无 401/4xx 错误

- [ ] **Step 3: 确认 agent 可被 opencode 识别**

重启 opencode 后（本会话内无法热加载）：
- 在任意对话中用 `@image-reader` 应能选中该 agent
- 或给主 agent 一个图片路径任务，观察其是否通过 task 工具调度 `image-reader`

---

## 验收清单（对照设计文档）

- [ ] `~/.config/opencode/agent/image-reader.md` 存在且 frontmatter 合法
- [ ] 模型为 `xiaomi-token-plan-cn/mimo-v2.5`
- [ ] 未修改 `~/.config/opencode/AGENTS.md` / `opencode.json` / 任何全局配置
- [ ] mimo-v2.5 实际读图成功（颜色识别）
- [ ] opencode 重启后 `@image-reader` 可选
