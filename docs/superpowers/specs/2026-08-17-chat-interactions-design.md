# LocalMind 对话交互增强设计文档

> 日期：2026-08-17
> 状态：已确认
> 主题：对话页 5 项交互增强——新建会话、切换 Agent/模型、移除删除按钮、查看 Skill 内容、多行输入+发图片/文件

## 背景

用户反馈对话页 5 个功能缺口：无新建会话按钮、对话页无法切换 Agent/模型、右上角删除按钮没用且不该显眼、看不到 Skill 内容、输入框无法多行编辑/换行/发文件图片。

## 设计决策

| 维度 | 决策 |
|---|---|
| 分支策略 | GitFlow：在 main 上新建 `feature/chat-interactions` 分支开发 |
| 对话页顶部 | 方案 C：标题栏左侧 历史🕘+新建＋，中间标题，右侧状态胶囊；移除删除按钮 |
| Agent/模型切换 | 输入框上方常驻切换器（空态+对话中都显示），点开弹菜单切换，**不清空对话**，影响后续新消息 |
| 删除按钮 | 从导航栏移除；清理功能保留在历史会话列表左滑删除 |
| Skill 内容 | Skills 列表项点击进入详情，显示 instructions 与 requiredTools |
| 多行输入 | TextEditor 多行，自动增高，Enter 换行、按钮发送 |
| 发图片/文件 | 从相册/文件选择，消息展示缩略图/文件名，存本地沙盒，不真传 API |

## 信息架构

### 对话页（ChatView）

- **标题栏**：左侧 `历史按钮` + `新建＋按钮`（渐变），中间 `LocalMind` 标题，右侧 `状态胶囊`。删除按钮移除。
- **空态**：渐变 orb → 标题 → 副标题 → 能力 chips → 输入框
- **对话中**：消息列表上方显示当前 Agent/模型胶囊（`🤖 通用助手` `🧠 Qwen 2.5`）
- **输入框上方常驻切换器**：`🤖 Agent ⌄` + `🧠 模型 ⌄` 两个胶囊选择器
- **输入框**：多行 TextEditor，左侧附件按钮（📎 图片/文件），右侧渐变发送按钮

### Skills 页

- 列表项点击进入详情：名称、summary、instructions 全文、requiredTools 列表

## 组件清单

- `NewSessionButtonView`：新建会话渐变按钮（或并入标题栏）
- `AgentModelSwitcherView`：常驻切换器（两个胶囊 + 菜单）
- `AgentPickerMenu` / `ModelPickerMenu`：弹出选择菜单（复用 AgentStore/ModelConfigStore/ModelPickerView 逻辑）
- `AttachmentPickerView`：图片/文件选择（PhotosPicker / fileImporter）
- `AttachmentBubbleView`：消息中的附件展示（图片缩略图 / 文件卡片）

## 数据层变更

- `ChatMessage`：新增附件字段 `attachments: [MessageAttachment]`
- 新增 `MessageAttachment` 模型：`type`（image/file）、`name`、`data` 或 `localURL`、`mimeType`
- `ChatService`：sendMessage 支持附带附件
- 附件文件存本地沙盒（Documents/Attachments/），消息引用路径

## 交互细节

- **新建会话**：清空当前消息区、分配新 `currentSessionID`，不删除旧会话（旧会话仍在历史列表）
- **切换 Agent/模型**：只改当前对话的后续生成上下文，不清空消息；切换器实时反映当前选择
- **发送**：输入框支持多行，`Shift+Enter` 或发送按钮提交；附件在发送时随消息一起
- **删除**：导航栏不再有删除；历史列表左滑删除会话

## 不做的事

- 图片/文件**不真正上传**到 AI API（POC：仅本地存储 + 消息展示）
- 不做附件在 AI 回复中的真正解析（模型暂不读附件内容）
- 不引入真实模型推理

## 验证方式

1. 单元测试：ChatMessage 附件 Codable、SessionStore 含附件会话持久化
2. UI 测试（run-uitests.sh）：新建会话、切换 Agent/模型、Skills 详情、多行输入、附件展示
3. 模拟器截图 + image-reader 校验布局

## 落地顺序

1. GitFlow 分支 + 数据层（MessageAttachment + ChatMessage 附件字段）
2. 标题栏（新建按钮 + 移除删除）
3. 输入框重构（多行 + 附件选择）
4. Agent/模型切换器（常驻 + 菜单）
5. Skills 详情
6. 验证与收尾
