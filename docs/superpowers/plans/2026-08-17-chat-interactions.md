# LocalMind 对话交互增强实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LocalMind 对话页增加 5 项交互增强：新建会话、切换 Agent/模型、移除删除按钮、查看 Skill 内容、多行输入+发图片/文件。

**Architecture:** 分层推进——先数据层（MessageAttachment + ChatMessage 附件字段 + ChatService 附件传递），再输入栏重构（多行+附件选择），再标题栏（新建按钮+移除删除）、Agent/模型切换器、Skills 详情，最后验证。

**Tech Stack:** SwiftUI（iOS 17+）、SwiftPM 单元测试（swift test）、xcodegen、PhotosPicker/fileImporter、现有 AgentStore/ModelConfigStore/ModelRouter/SessionStore。

---

### Task 1: 数据层——MessageAttachment + ChatMessage 附件字段

**Files:**
- Create: `LocalMind/Sources/Models/MessageAttachment.swift`
- Modify: `LocalMind/Sources/Models/ChatMessage.swift`
- Modify: `LocalMind/Sources/Services/ChatService.swift`
- Test: `LocalMind/Tests/LocalMindTests/ChatMessageAttachmentTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `LocalMind/Tests/LocalMindTests/ChatMessageAttachmentTests.swift`：

```swift
import XCTest
@testable import LocalMind

final class ChatMessageAttachmentTests: XCTestCase {
    func testMessageAttachmentCodable() throws {
        let att = MessageAttachment(type: .image, name: "photo.png", localURL: "Attachments/abc.png", mimeType: "image/png")
        let data = try JSONEncoder().encode(att)
        let decoded = try JSONDecoder().decode(MessageAttachment.self, from: data)
        XCTAssertEqual(decoded.type, .image)
        XCTAssertEqual(decoded.name, "photo.png")
        XCTAssertEqual(decoded.localURL, "Attachments/abc.png")
    }

    func testChatMessageWithAttachmentsCodable() throws {
        let msg = ChatMessage(
            id: UUID(),
            role: .user,
            content: "看这张图",
            timestamp: Date(),
            attachments: [MessageAttachment(type: .image, name: "a.png", localURL: "a.png", mimeType: "image/png")]
        )
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        XCTAssertEqual(decoded.attachments.count, 1)
        XCTAssertEqual(decoded.attachments.first?.type, .image)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ChatMessageAttachmentTests`
Expected: 编译失败（MessageAttachment 未定义 / ChatMessage 无 attachments 字段）

- [ ] **Step 3: 实现 MessageAttachment 模型**

创建 `LocalMind/Sources/Models/MessageAttachment.swift`：

```swift
import Foundation

struct MessageAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var type: AttachmentType
    var name: String
    var localURL: String
    var mimeType: String

    init(id: UUID = UUID(), type: AttachmentType, name: String, localURL: String, mimeType: String) {
        self.id = id
        self.type = type
        self.name = name
        self.localURL = localURL
        self.mimeType = mimeType
    }
}

enum AttachmentType: String, Codable {
    case image
    case file
}
```

- [ ] **Step 4: 扩展 ChatMessage**

修改 `LocalMind/Sources/Models/ChatMessage.swift`：

```swift
import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var speed: Double?
    var toolName: String?
    var attachments: [MessageAttachment] = []

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date,
        speed: Double? = nil,
        toolName: String? = nil,
        attachments: [MessageAttachment] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.speed = speed
        self.toolName = toolName
        self.attachments = attachments
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
```

注意：ChatMessage 之前用**成员级初始化器**（无显式 init），现在加了默认值字段 attachments 且需要自定义 init 保持向后兼容（旧调用点不传 attachments）。检查全仓 `ChatMessage(` 调用点（ChatService.swift、ChatView.swift）是否仍编译。

- [ ] **Step 5: 运行测试确认通过**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ChatMessageAttachmentTests`
Expected: 通过

- [ ] **Step 6: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Models/MessageAttachment.swift LocalMind/Sources/Models/ChatMessage.swift LocalMind/Tests/LocalMindTests/ChatMessageAttachmentTests.swift && git commit -m "feat: MessageAttachment + ChatMessage 附件字段"
```

---

### Task 2: 输入栏重构——多行 + 附件选择

**Files:**
- Modify: `LocalMind/Sources/Views/QuickInputBar.swift`
- Modify: `LocalMind/Sources/Views/ChatView.swift`（sendMessage 传附件）
- Create: `LocalMind/Sources/Views/AttachmentBubbleView.swift`

- [ ] **Step 1: 重构 QuickInputBar 支持多行 + 附件**

重写 `LocalMind/Sources/Views/QuickInputBar.swift`。签名扩展为支持附件：

```swift
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct QuickInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    var onAddAttachment: ((MessageAttachment) -> Void)? = nil
    @State private var pendingAttachments: [MessageAttachment] = []
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 6) {
            if !pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(pendingAttachments) { att in
                            AttachmentPreviewChip(attachment: att) {
                                pendingAttachments.removeAll { $0.id == att.id }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            HStack(spacing: 10) {
                Menu {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("图片", systemImage: "photo")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("文件", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.indigo)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.indigo.opacity(0.1)))
                }
                .accessibilityLabel("添加附件")

                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: 34, maxHeight: 100)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .scrollContentBackground(.hidden)
                    .background(Color.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Group {
                                if text.isEmpty && pendingAttachments.isEmpty {
                                    Circle().fill(Color.disabledGray)
                                } else {
                                    Circle().fill(LinearGradient(colors: [.indigo, .purple, .pink],
                                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                            }
                        )
                        .shadow(color: (text.isEmpty && pendingAttachments.isEmpty) ? .clear : Color.purple.opacity(0.4), radius: 6, y: 3)
                        .clipShape(Circle())
                }
                .accessibilityLabel("发送")
                .disabled(text.isEmpty && pendingAttachments.isEmpty)
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        #if canImport(UIKit)
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .plainText, .image]) { result in
            handleFileImport(result)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            loadPhoto(newItem)
        }
        #endif
    }

    private func send() {
        guard !text.isEmpty || !pendingAttachments.isEmpty else { return }
        for att in pendingAttachments {
            onAddAttachment?(att)
        }
        pendingAttachments.removeAll()
        onSend()
    }

    #if canImport(UIKit)
    private func loadPhoto(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let name = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
                let savedURL = AttachmentStore.shared.save(data: data, name: name)
                pendingAttachments.append(MessageAttachment(type: .image, name: name, localURL: savedURL, mimeType: "image/jpeg"))
            }
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let name = url.lastPathComponent
        let savedURL = AttachmentStore.shared.save(data: data, name: name)
        let mime = "application/octet-stream"
        pendingAttachments.append(MessageAttachment(type: .file, name: name, localURL: savedURL, mimeType: mime))
    }
    #endif
}

struct AttachmentPreviewChip: View {
    let attachment: MessageAttachment
    let onRemove: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: attachment.type == .image ? "photo" : "doc")
                .font(.caption2)
            Text(attachment.name)
                .font(.caption2)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.secondary.opacity(0.12)))
    }
}
```

注意：
- `TextEditor` 替代 `TextField` 支持多行；`scrollContentBackground(.hidden)` + 手动背景。
- 附件选择用 PhotosPicker + fileImporter；选中的图片/文件先经 `AttachmentStore` 保存到沙盒。
- 附件先暂存 `pendingAttachments`，发送时通过 `onAddAttachment` 回调传给 ChatView，然后清空并触发 `onSend`。

- [ ] **Step 2: 实现 AttachmentStore（附件沙盒存储）**

创建 `LocalMind/Sources/Services/AttachmentStore.swift`：

```swift
import Foundation

class AttachmentStore {
    static let shared = AttachmentStore()
    private let fileManager = FileManager.default
    private let attachmentsDir: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        attachmentsDir = docs.appendingPathComponent("Attachments", isDirectory: true)
        try? fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
    }

    /// 返回相对路径（存于 ChatMessage.localURL），用于后续读取
    func save(data: Data, name: String) -> String {
        let url = attachmentsDir.appendingPathComponent(name)
        try? data.write(to: url)
        return "Attachments/\(name)"
    }

    func fileURL(for relative: String) -> URL? {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(relative)
    }

    func delete(_ relative: String) {
        if let url = fileURL(for: relative) {
            try? fileManager.removeItem(at: url)
        }
    }
}
```

- [ ] **Step 3: 更新 ChatView.sendMessage 支持附件**

修改 `LocalMind/Sources/Views/ChatView.swift`：
- 加 `@State private var pendingAttachments: [MessageAttachment] = []`
- 加方法 `private func attach(_ att: MessageAttachment)` 把附件加入 pending，发送时并入 user message
- 修改 `sendMessage()` 构造 user message 时带 pendingAttachments：

```swift
    private func sendMessage() {
        guard !inputText.isEmpty || !pendingAttachments.isEmpty else { return }
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: inputText,
            timestamp: Date(),
            attachments: pendingAttachments
        )
        messages.append(userMessage)
        inputText = ""
        pendingAttachments = []
        isGenerating = true
        // ... 其余不变
    }
```

注意：`ChatService.sendMessage` 只接收 text（不接收附件）。POC 阶段附件仅随 user message 展示、不传给 AI 生成。assistant 回复不含附件。所以 userMessage 在 ChatView 本地构造并 append，chatService.sendMessage 仍传 `userMessage.content`。

- [ ] **Step 4: 修改 QuickInputBar 调用点**

在 ChatView 中把 `QuickInputBar(text: $inputText, onSend: sendMessage)` 改为：

```swift
QuickInputBar(text: $inputText, onSend: sendMessage) { att in
    pendingAttachments.append(att)
}
```

- [ ] **Step 5: 添加附件消息展示**

在 ChatView 的 assistantBubble 旁边，为 user 消息加附件展示。修改消息列表的 user 分支，在 UserBubbleView 下方渲染附件：

```swift
                            if message.role == .user {
                                HStack { Spacer(); UserBubbleView(text: message.content) }
                                    .id(message.id)
                                if !message.attachments.isEmpty {
                                    ForEach(message.attachments) { att in
                                        HStack { Spacer(); AttachmentBubbleView(attachment: att) }
                                    }
                                }
                            }
```

创建 `LocalMind/Sources/Views/AttachmentBubbleView.swift`：

```swift
import SwiftUI

struct AttachmentBubbleView: View {
    let attachment: MessageAttachment
    @State private var image: UIImage?

    var body: some View {
        Group {
            if attachment.type == .image, let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: attachment.type == .image ? "photo" : "doc.fill")
                        .font(.title3)
                        .foregroundColor(.indigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attachment.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text("附件")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.1)))
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        guard attachment.type == .image, let url = AttachmentStore.shared.fileURL(for: attachment.localURL) else { return }
        image = UIImage(contentsOfFile: url.path)
    }
}
```

注意：`AttachmentBubbleView` 用 `UIImage`（UIKit）。为跨平台，用 `#if canImport(UIKit)` 包裹 UIImage 相关代码，macOS 分支降级为文件卡片。

- [ ] **Step 6: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodegen generate && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/QuickInputBar.swift LocalMind/Sources/Services/AttachmentStore.swift LocalMind/Sources/Views/ChatView.swift LocalMind/Sources/Views/AttachmentBubbleView.swift && git commit -m "feat: 输入栏多行 + 图片/文件附件（PhotosPicker/fileImporter + 沙盒存储 + 消息展示）"
```

---

### Task 3: 标题栏——新建会话按钮 + 移除删除按钮

**Files:**
- Modify: `LocalMind/Sources/Views/ChatView.swift`

- [ ] **Step 1: 添加新建会话按钮 + 移除删除**

修改 `ChatView.swift`：
- 在标题栏 HStack（左侧历史按钮旁）添加新建会话按钮
- 移除 `.toolbar` 里的删除按钮（整个 `#if canImport(UIKit) ... #endif` 的 trash ToolbarItem 删除）
- 添加 `startNewSession()` 方法

标题栏改为：

```swift
            HStack(spacing: 8) {
                Button {
                    showSessions = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.body)
                        .foregroundColor(.indigo)
                }
                .accessibilityLabel("历史会话")
                .sheet(isPresented: $showSessions) {
                    SessionListView { session in
                        load(session: session)
                        showSessions = false
                    }
                }

                Button(action: startNewSession) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(LinearGradient(colors: [.indigo, .purple],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .accessibilityLabel("新建会话")

                Spacer()

                GlowPillView(text: "本地运行")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
```

删除整个 `.toolbar { #if canImport(UIKit) ToolbarItem(placement: .topBarTrailing) { ...trash... } #else ... #endif }` 块。

添加方法：

```swift
    private func startNewSession() {
        messages = []
        currentSessionID = nil
        isGenerating = false
    }
```

- [ ] **Step 2: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/ChatView.swift && git commit -m "feat: 新建会话按钮 + 移除导航栏删除按钮"
```

---

### Task 4: 对话页 Agent/模型切换器

**Files:**
- Create: `LocalMind/Sources/Views/AgentModelSwitcher.swift`
- Modify: `LocalMind/Sources/Views/ChatView.swift`

- [ ] **Step 1: 实现切换器组件**

创建 `LocalMind/Sources/Views/AgentModelSwitcher.swift`：

```swift
import SwiftUI

struct AgentModelSwitcher: View {
    @Binding var agentID: UUID?
    @Binding var modelSelection: ModelSelection?
    @State private var agents: [AgentProfile] = AgentStore.shared.loadAgents()
    @State private var showAgentPicker = false
    @State private var showModelPicker = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showAgentPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text(currentAgentName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.indigo.opacity(0.12)))
                .foregroundColor(.indigo)
            }
            .accessibilityLabel("切换 Agent")
            .sheet(isPresented: $showAgentPicker) {
                AgentPickerSheet(agents: agents, selectedID: agentID) { id in
                    agentID = id
                    let agent = agents.first { $0.id == id }
                    modelSelection = agent?.selectedModel
                }
            }

            Button {
                showModelPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text(modelSelection.map { ModelRouter().describe(selection: $0) } ?? "本地默认")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.indigo.opacity(0.12)))
                .foregroundColor(.indigo)
            }
            .accessibilityLabel("切换模型")
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheet(selection: $modelSelection)
            }
        }
    }

    private var currentAgentName: String {
        agents.first { $0.id == agentID }?.name ?? "通用助手"
    }
}

struct AgentPickerSheet: View {
    let agents: [AgentProfile]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(agents) { agent in
                Button {
                    onSelect(agent.id)
                    dismiss()
                } label: {
                    HStack {
                        Text(agent.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if agent.id == selectedID {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("选择 Agent")
        }
    }
}

struct ModelPickerSheet: View {
    @Binding var selection: ModelSelection?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("本地模型") {
                    ForEach(ModelType.allCases, id: \.rawValue) { model in
                        Button {
                            selection = .local(model)
                            dismiss()
                        } label: {
                            HStack {
                                Text(model.displayName)
                                Spacer()
                                if case .local(model) = selection {
                                    Image(systemName: "checkmark").foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                Section("外部 API") {
                    ForEach(ModelConfigStore.shared.loadProviders()) { provider in
                        Button {
                            selection = .remote(providerID: provider.id)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(provider.name) · \(provider.modelName)")
                                Spacer()
                                if case .remote(let pid) = selection, pid == provider.id {
                                    Image(systemName: "checkmark").foregroundColor(.green)
                                }
                            }
                        }
                    }
                    if ModelConfigStore.shared.loadProviders().isEmpty {
                        Text("尚无外部模型，请先在模型管理中添加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择模型")
        }
    }
}
```

- [ ] **Step 2: 接入 ChatView**

在 `ChatView.swift`：
- 添加 `@State private var agentID: UUID? = AgentStore.shared.currentAgent()?.id`
- 添加 `@State private var modelSelection: ModelSelection?`
- 在消息列表与输入框之间（QuickInputBar 上方）加入 `AgentModelSwitcher`，常驻显示：

```swift
            AgentModelSwitcher(agentID: $agentID, modelSelection: $modelSelection)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

            QuickInputBar(text: $inputText, onSend: sendMessage) { att in
                pendingAttachments.append(att)
            }
```

- [ ] **Step 3: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/AgentModelSwitcher.swift LocalMind/Sources/Views/ChatView.swift && git commit -m "feat: 对话页 Agent/模型切换器（常驻输入栏上方，菜单切换不清对话）"
```

---

### Task 5: Skills 详情页

**Files:**
- Modify: `LocalMind/Sources/Views/AgentViews.swift`

- [ ] **Step 1: 实现 SkillsView 详情**

修改 `LocalMind/Sources/Views/AgentViews.swift` 的 `SkillsView`，让每行点击进入详情：

```swift
struct SkillsView: View {
    @State private var skills: [AgentSkill] = SkillStore.shared.loadSkills()
    var body: some View {
        List {
            ForEach(skills) { skill in
                NavigationLink {
                    SkillDetailView(skill: skill)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name).font(.subheadline).fontWeight(.medium)
                            Text(skill.summary).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { skill.enabled },
                            set: { enabled in
                                SkillStore.shared.toggle(skill, enabled: enabled)
                                skills = SkillStore.shared.loadSkills()
                            }
                        )).labelsHidden()
                    }
                }
            }
        }
        .navigationTitle("Skills")
    }
}

struct SkillDetailView: View {
    let skill: AgentSkill
    var body: some View {
        Form {
            Section("简介") {
                Text(skill.summary)
            }
            Section("指令内容") {
                Text(skill.instructions)
            }
            Section("所需工具") {
                if skill.requiredTools.isEmpty {
                    Text("无")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(skill.requiredTools, id: \.self) { tool in
                        Text(tool)
                    }
                }
            }
        }
        .navigationTitle(skill.name)
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/AgentViews.swift && git commit -m "feat: Skills 详情页（指令内容 + 所需工具）"
```

---

### Task 6: 全量验证

**Files:** 无新文件

- [ ] **Step 1: 单元测试全量**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test`
Expected: 全部通过（原 70 + 新增 ChatMessageAttachmentTests 2）

- [ ] **Step 2: 构建 App**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodegen generate && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 模拟器安装启动 + 截图**

Run:
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID=$(xcrun simctl list devices | grep "iPhone 17 (" | grep -oE '[0-9A-F-]{36}' | head -1)
[ -z "$UDID" ] && UDID=$(xcrun simctl list devices | grep "iPhone 17" | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl terminate "$UDID" com.localmind.LocalMind 2>/dev/null
xcrun simctl install "$UDID" /Users/zhangbolin/Projects/local-agent/LocalMind/build/Build/Products/Debug-iphonesimulator/LocalMind.app
xcrun simctl launch "$UDID" com.localmind.LocalMind
sleep 4
xcrun simctl io "$UDID" screenshot /var/folders/5t/6b2npv2d0jd1r7gzc8d1rzwh0000gn/T/opencode/chat_interactions.png
```
Expected: App 启动，截图生成

- [ ] **Step 4: UI 测试（run-uitests.sh）**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && ./run-uitests.sh`
Expected: 全部通过。若因新增按钮/移除删除导致断言变化（如 `testMainScreenRendersAndTabNavigationWorks` 中 `app.buttons["删除"]` 相关），更新测试断言。

- [ ] **Step 5: image-reader 校验截图**

用 image-reader subagent 分析 `chat_interactions.png`：确认标题栏（历史+新建+状态）、输入框上方切换器、空态布局、无黑边/重叠。

- [ ] **Step 6: 提交**

无新代码；如有测试修正随前序任务提交。

---

## 验收清单（对照设计文档）

- [ ] 新建会话按钮：标题栏左侧，点击清空消息区开新会话
- [ ] 切换 Agent/模型：输入框上方常驻切换器，菜单切换，不清空对话
- [ ] 删除按钮：从导航栏移除
- [ ] Skills 详情：点开显示 instructions + requiredTools
- [ ] 多行输入：TextEditor 支持换行
- [ ] 发图片/文件：PhotosPicker/fileImporter + 沙盒存储 + 消息展示缩略图/文件卡片
- [ ] 单元测试 + UI 测试通过
- [ ] 截图经 image-reader 校验布局正确