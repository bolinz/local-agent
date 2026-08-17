# LocalMind 全 App 视觉与信息架构重设计实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 LocalMind 三个 Tab 从原生 List/Form 骨架升级为沉浸式 AI Agent 产品体验（双模式、Agent 行为可视化、历史会话、多 Agent 管理、模型管理）。

**Architecture:** 分层推进——先数据层（会话持久化、多 Agent 存储、模型 provider 存储），再视觉组件，再逐 Tab 重写 UI。视觉组件与业务解耦，可独立测试。

**Tech Stack:** SwiftUI（iOS 17+）、SwiftPM 单元测试（swift test）、xcodegen、现有 StorageService/ModelManager/SettingsService。

---

### Task 1: 数据层——ChatSession 模型 + 会话持久化

**Files:**
- Create: `LocalMind/Sources/Models/ChatSession.swift`
- Modify: `LocalMind/Sources/Services/ChatService.swift`
- Test: `LocalMind/Tests/LocalMindTests/ChatSessionTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `LocalMind/Tests/LocalMindTests/ChatSessionTests.swift`：

```swift
import XCTest
@testable import LocalMind

final class ChatSessionTests: XCTestCase {
    func testChatSessionCodableRoundTrip() throws {
        let session = ChatSession(
            id: UUID(),
            title: "测试会话",
            updatedAt: Date(),
            messages: [
                ChatMessage(id: UUID(), role: .user, content: "你好", timestamp: Date()),
                ChatMessage(id: UUID(), role: .assistant, content: "你好！", timestamp: Date())
            ]
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ChatSession.self, from: data)
        XCTAssertEqual(decoded.title, "测试会话")
        XCTAssertEqual(decoded.messages.count, 2)
    }

    func testChatSessionStorePersistsAndLoads() {
        let store = SessionStore(mockStorage: MockStorage())
        let session = ChatSession(id: UUID(), title: "会话A", updatedAt: Date(), messages: [])
        store.save([session], forKey: "test_sessions")
        let loaded = store.load(forKey: "test_sessions")
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.title, "会话A")
    }
}

private final class MockStorage {
    var data: Data?
    func save(_ data: Data) { self.data = data }
    func load() -> Data? { return data }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ChatSessionTests`
Expected: 编译失败（ChatSession/SessionStore 未定义）

- [ ] **Step 3: 实现 ChatSession 模型**

创建 `LocalMind/Sources/Models/ChatSession.swift`：

```swift
import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var updatedAt: Date
    var messages: [ChatMessage]

    init(id: UUID = UUID(), title: String, updatedAt: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.messages = messages
    }

    var preview: String {
        messages.last?.content ?? title
    }
}
```

- [ ] **Step 4: 实现 SessionStore**

创建 `LocalMind/Sources/Services/SessionStore.swift`：

```swift
import Foundation

struct SessionStore {
    private let storage: StorageService
    private let key = "chat_sessions"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func load() -> [ChatSession] {
        storage.load([ChatSession].self, forKey: key) ?? []
    }

    func save(_ sessions: [ChatSession]) {
        storage.save(sessions, forKey: key)
    }

    func upsert(_ session: ChatSession) {
        var sessions = load()
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        save(sessions)
    }

    func delete(_ id: UUID) {
        var sessions = load()
        sessions.removeAll { $0.id == id }
        save(sessions)
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ChatSessionTests`
Expected: 通过。若编译报错（ChatMessage 需 Codable），先修 ChatMessage。

- [ ] **Step 6: 使 ChatMessage 可 Codable**

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
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
```

- [ ] **Step 7: 重跑测试**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ChatSessionTests`
Expected: 通过

- [ ] **Step 8: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Models/ChatSession.swift LocalMind/Sources/Services/SessionStore.swift LocalMind/Sources/Models/ChatMessage.swift LocalMind/Tests/LocalMindTests/ChatSessionTests.swift && git commit -m "feat: 会话持久化（ChatSession + SessionStore）"
```

---

### Task 2: 数据层——多 Agent 存储

**Files:**
- Create: `LocalMind/Sources/Models/AgentProfile.swift`
- Create: `LocalMind/Sources/Services/AgentStore.swift`
- Test: `LocalMind/Tests/LocalMindTests/AgentStoreTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `LocalMind/Tests/LocalMindTests/AgentStoreTests.swift`：

```swift
import XCTest
@testable import LocalMind

final class AgentStoreTests: XCTestCase {
    func testAgentProfileCodable() throws {
        let profile = AgentProfile(
            id: UUID(),
            name: "健康管家",
            icon: "heart.fill",
            color: "green",
            systemPrompt: "你是健康管家",
            dataPolicy: .strictLocal,
            selectedModel: nil,
            enabledTools: ["calendar", "reminder"],
            isCurrent: true
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AgentProfile.self, from: data)
        XCTAssertEqual(decoded.name, "健康管家")
        XCTAssertEqual(decoded.dataPolicy, .strictLocal)
        XCTAssertEqual(decoded.enabledTools, ["calendar", "reminder"])
    }

    func testAgentStoreDefaultHasCurrentAgent() {
        let store = AgentStore(storage: .shared)
        let agents = store.loadAgents()
        XCTAssertTrue(agents.contains { $0.isCurrent })
    }

    func testAgentStoreSaveLoadRoundTrip() {
        let store = AgentStore(storage: .shared)
        var agents = store.loadAgents()
        agents.append(AgentProfile(id: UUID(), name: "测试", icon: "x", color: "blue",
                                   systemPrompt: "测试", dataPolicy: .localFirst,
                                   selectedModel: nil, enabledTools: [], isCurrent: false))
        store.saveAgents(agents)
        let reloaded = store.loadAgents()
        XCTAssertTrue(reloaded.contains { $0.name == "测试" })
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter AgentStoreTests`
Expected: 编译失败（AgentProfile/AgentStore 未定义）

- [ ] **Step 3: 实现 AgentProfile 模型**

创建 `LocalMind/Sources/Models/AgentProfile.swift`：

```swift
import Foundation

struct AgentProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var systemPrompt: String
    var dataPolicy: DataPolicy
    var selectedModel: ModelSelection?
    var enabledTools: [String]
    var isCurrent: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        systemPrompt: String,
        dataPolicy: DataPolicy = .localFirst,
        selectedModel: ModelSelection? = nil,
        enabledTools: [String] = [],
        isCurrent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.systemPrompt = systemPrompt
        self.dataPolicy = dataPolicy
        self.selectedModel = selectedModel
        self.enabledTools = enabledTools
        self.isCurrent = isCurrent
    }
}

enum ModelSelection: Codable, Equatable {
    case local(ModelType)
    case remote(providerID: UUID)
}

enum AgentColor: String, Codable {
    case blue, green, orange, purple, red
}
```

- [ ] **Step 4: 实现 AgentStore**

创建 `LocalMind/Sources/Services/AgentStore.swift`：

```swift
import Foundation

class AgentStore {
    static let shared = AgentStore()
    private let storage: StorageService
    private let key = "agent_profiles"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadAgents() -> [AgentProfile] {
        if let loaded = storage.load([AgentProfile].self, forKey: key), !loaded.isEmpty {
            return loaded
        }
        let defaults = [AgentProfile(
            name: "LocalMind 通用助手",
            icon: "brain.head.profile",
            color: AgentColor.blue.rawValue,
            systemPrompt: "你是 LocalMind，一个运行在用户设备上的本地 AI 助手。优先在本地完成数据处理，保护用户隐私。",
            dataPolicy: .localFirst,
            enabledTools: ["calendar", "reminder", "notification"],
            isCurrent: true
        )]
        saveAgents(defaults)
        return defaults
    }

    func saveAgents(_ agents: [AgentProfile]) {
        storage.save(agents, forKey: key)
    }

    func currentAgent() -> AgentProfile? {
        loadAgents().first { $0.isCurrent }
    }

    func setCurrent(_ id: UUID) {
        var agents = loadAgents()
        for i in agents.indices {
            agents[i].isCurrent = (agents[i].id == id)
        }
        saveAgents(agents)
    }

    func upsert(_ agent: AgentProfile) {
        var agents = loadAgents()
        if let idx = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[idx] = agent
        } else {
            agents.append(agent)
        }
        saveAgents(agents)
    }

    func delete(_ id: UUID) {
        var agents = loadAgents()
        agents.removeAll { $0.id == id }
        saveAgents(agents)
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter AgentStoreTests`
Expected: 通过

- [ ] **Step 6: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Models/AgentProfile.swift LocalMind/Sources/Services/AgentStore.swift LocalMind/Tests/LocalMindTests/AgentStoreTests.swift && git commit -m "feat: 多 Agent 配置存储（AgentProfile + AgentStore）"
```

---

### Task 3: 数据层——模型 provider 存储 + ModelRouter

**Files:**
- Create: `LocalMind/Sources/Models/ModelProvider.swift`
- Create: `LocalMind/Sources/Services/ModelConfigStore.swift`
- Create: `LocalMind/Sources/Services/ModelRouter.swift`
- Test: `LocalMind/Tests/LocalMindTests/ModelConfigTests.swift`

- [ ] **Step 1: 写失败测试**

创建 `LocalMind/Tests/LocalMindTests/ModelConfigTests.swift`：

```swift
import XCTest
@testable import LocalMind

final class ModelConfigTests: XCTestCase {
    func testModelProviderCodable() throws {
        let provider = ModelProvider(
            id: UUID(),
            name: "OpenAI",
            template: .openAI,
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            modelName: "gpt-4o"
        )
        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(ModelProvider.self, from: data)
        XCTAssertEqual(decoded.name, "OpenAI")
        XCTAssertEqual(decoded.template, .openAI)
    }

    func testProviderTemplates() {
        XCTAssertEqual(ProviderTemplate.openAI.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(ProviderTemplate.anthropic.baseURL, "https://api.anthropic.com/v1")
        XCTAssertEqual(ProviderTemplate.deepSeek.baseURL, "https://api.deepseek.com/v1")
        XCTAssertNil(ProviderTemplate.custom.baseURL)
    }

    func testModelConfigStoreRoundTrip() {
        let store = ModelConfigStore(storage: .shared)
        store.saveProviders([])
        store.addProvider(ModelProvider(id: UUID(), name: "测试", template: .custom,
                                        baseURL: "http://localhost:11434/v1", apiKey: "",
                                        modelName: "llama3"))
        let loaded = store.loadProviders()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.modelName, "llama3")
    }

    func testModelRouterSelectsLocal() {
        let router = ModelRouter()
        let desc = router.describe(selection: .local(.qwen2_5_3b))
        XCTAssertTrue(desc.contains("Qwen"))
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ModelConfigTests`
Expected: 编译失败（ModelProvider/ProviderTemplate/ModelConfigStore/ModelRouter 未定义）

- [ ] **Step 3: 实现 ModelProvider 模型**

创建 `LocalMind/Sources/Models/ModelProvider.swift`：

```swift
import Foundation

struct ModelProvider: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var template: ProviderTemplate
    var baseURL: String
    var apiKey: String
    var modelName: String

    init(id: UUID = UUID(), name: String, template: ProviderTemplate,
         baseURL: String, apiKey: String, modelName: String) {
        self.id = id
        self.name = name
        self.template = template
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.modelName = modelName
    }
}

enum ProviderTemplate: String, Codable, CaseIterable {
    case openAI
    case anthropic
    case gemini
    case deepSeek
    case custom

    var baseURL: String? {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .custom: return nil
        }
    }

    var defaultModelName: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-haiku-latest"
        case .gemini: return "gemini-1.5-flash"
        case .deepSeek: return "deepseek-chat"
        case .custom: return ""
        }
    }
}
```

- [ ] **Step 4: 实现 ModelConfigStore**

创建 `LocalMind/Sources/Services/ModelConfigStore.swift`：

```swift
import Foundation

class ModelConfigStore {
    static let shared = ModelConfigStore()
    private let storage: StorageService
    private let key = "model_providers"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadProviders() -> [ModelProvider] {
        storage.load([ModelProvider].self, forKey: key) ?? []
    }

    func saveProviders(_ providers: [ModelProvider]) {
        storage.save(providers, forKey: key)
    }

    func addProvider(_ provider: ModelProvider) {
        var providers = loadProviders()
        providers.append(provider)
        saveProviders(providers)
    }

    func updateProvider(_ provider: ModelProvider) {
        var providers = loadProviders()
        if let idx = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[idx] = provider
        }
        saveProviders(providers)
    }

    func deleteProvider(_ id: UUID) {
        var providers = loadProviders()
        providers.removeAll { $0.id == id }
        saveProviders(providers)
    }
}
```

- [ ] **Step 5: 实现 ModelRouter**

创建 `LocalMind/Sources/Services/ModelRouter.swift`：

```swift
import Foundation

struct ModelRouter {
    func describe(selection: ModelSelection) -> String {
        switch selection {
        case .local(let model):
            return model.displayName
        case .remote(let providerID):
            let provider = ModelConfigStore.shared.loadProviders().first { $0.id == providerID }
            return provider.map { "\($0.name) · \($0.modelName)" } ?? "外部模型"
        }
    }

    func testConnection(_ provider: ModelProvider) async -> Bool {
        guard !provider.baseURL.isEmpty, !provider.apiKey.isEmpty else { return false }
        let url = URL(string: "\(provider.baseURL)/models")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test --filter ModelConfigTests`
Expected: 通过

- [ ] **Step 7: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Models/ModelProvider.swift LocalMind/Sources/Services/ModelConfigStore.swift LocalMind/Sources/Services/ModelRouter.swift LocalMind/Tests/LocalMindTests/ModelConfigTests.swift && git commit -m "feat: 模型 provider 配置存储 + ModelRouter（本地/外部路由描述）"
```

---

### Task 4: 视觉组件——Orb / GlowPill / GradientIcon / ThinkingCard / ToolCallCard / MemoryStrip

**Files:**
- Create: `LocalMind/Sources/Views/VisualComponents.swift`
- Test: `LocalMind/Tests/LocalMindTests/VisualComponentSnapshotTests.swift`（仅编译检查）

- [ ] **Step 1: 实现视觉组件**

创建 `LocalMind/Sources/Views/VisualComponents.swift`：

```swift
import SwiftUI

// MARK: - 渐变圆角图标（通用）

struct GradientIconView: View {
    let icon: String
    let gradient: [Color]
    let size: CGFloat

    init(icon: String, gradient: [Color] = [Color.indigo, Color.purple], size: CGFloat = 36) {
        self.icon = icon
        self.gradient = gradient
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 8, y: 4)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 发光状态胶囊

struct GlowPillView: View {
    let text: String
    var isActive = true
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: (isActive ? Color.green : Color.red).opacity(0.8), radius: 4)
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.green.opacity(isActive ? 0.12 : 0)))
        .foregroundColor(isActive ? Color.green : Color.secondary)
    }
}

// MARK: - 思考过程卡片

struct ThinkingCardView: View {
    let steps: [ThinkingStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [.indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 12, height: 12)
                Text("Agent 思考中")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
            }
            ForEach(steps) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step.state.backgroundColor)
                            .frame(width: 16, height: 16)
                        Text(step.state.symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(step.state.foregroundColor)
                    }
                    Text(step.label)
                        .font(.caption)
                        .foregroundColor(step.state == .active ? .primary : .secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}

struct ThinkingStep: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let state: StepState

    enum StepState: Equatable {
        case done, active, pending
        var symbol: String {
            switch self {
            case .done: return "✓"
            case .active: return "●"
            case .pending: return ""
            }
        }
        var backgroundColor: Color {
            switch self {
            case .done: return Color.green.opacity(0.15)
            case .active: return Color.yellow.opacity(0.15)
            case .pending: return Color.secondary.opacity(0.1)
            }
        }
        var foregroundColor: Color {
            switch self {
            case .done: return .green
            case .active: return .yellow
            case .pending: return .clear
            }
        }
    }
}

// MARK: - 工具调用卡片

struct ToolCallCardView: View {
    let toolName: String
    let params: String
    let result: String
    var isSuccess = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption)
                    Text(toolName)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.indigo)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(params)
                .font(.caption2)
                .monospaced()
                .foregroundColor(.secondary)
            Label(result, systemImage: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption2)
                .foregroundColor(isSuccess ? .green : .red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.indigo.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.indigo.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - 上下文记忆胶囊条

struct MemoryStripView: View {
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                            Text(item)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.indigo.opacity(0.12)))
                        .foregroundColor(.indigo)
                    }
                }
            }
        }
    }
}

// MARK: - 渐变对话气泡

struct UserBubbleView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LinearGradient(colors: [Color.indigo, Color(red: 0.44, green: 0.24, blue: 0.93)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.indigo.opacity(0.3), radius: 8, y: 4)
    }
}
```

- [ ] **Step 2: 编译检查**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift build`
Expected: 编译成功（视觉组件不引入逻辑，无需逻辑测试）

- [ ] **Step 3: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/VisualComponents.swift && git commit -m "feat: 视觉组件（GradientIcon/GlowPill/ThinkingCard/ToolCallCard/MemoryStrip/UserBubble）"
```

---

### Task 5: 对话页重写——空态 + 对话流 + 输入栏 + 历史入口

**Files:**
- Modify: `LocalMind/Sources/Views/ContentView.swift`（ChatView 部分重写）
- Create: `LocalMind/Sources/Views/ChatView.swift`（抽取独立文件）

- [ ] **Step 1: 抽取 ChatView 到独立文件**

创建 `LocalMind/Sources/Views/ChatView.swift`，将 `ChatView`、`emptyStateView`、`sendMessage` 从 ContentView.swift 迁移并重写：

```swift
import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isGenerating = false
    @State private var currentSessionID: UUID?
    @State private var showSessions = false

    private let chatService = ChatService.shared
    private let sessionStore = SessionStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
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

                Spacer()

                GlowPillView(text: "本地运行")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            emptyStateView
                        }
                        ForEach(messages) { message in
                            if message.role == .user {
                                HStack { Spacer(); UserBubbleView(text: message.content) }
                                    .id(message.id)
                            } else {
                                HStack { assistantBubble(message); Spacer() }
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            if isGenerating {
                ThinkingCardView(steps: [
                    ThinkingStep(label: "理解你的意图", state: .done),
                    ThinkingStep(label: "正在调用工具", state: .active),
                    ThinkingStep(label: "整理回复", state: .pending),
                ])
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            MemoryStripView(items: memoryItems())
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            QuickInputBar(text: $inputText, onSend: sendMessage)
        }
        .navigationTitle("LocalMind")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if canImport(UIKit)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    messages.removeAll()
                    chatService.clearHistory()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            #endif
        }
        .onAppear {
            if messages.isEmpty {
                messages = chatService.getHistory()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [.indigo, .purple, .pink],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .shadow(color: .purple.opacity(0.4), radius: 16, y: 8)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            Text("你的数据，你的设备，你的 AI")
                .font(.title3)
                .fontWeight(.bold)
            Text("用一句话让 LocalMind 帮你干活")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                chip("📅 创建提醒", "创建一个明天下午3点的会议提醒")
                chip("📊 总结日程", "帮我总结本周的日程")
            }
            HStack(spacing: 8) {
                chip("💊 用药提醒", "每天8点提醒我吃药")
                chip("🏠 控制家居", "晚上到家自动开灯")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func chip(_ label: String, _ prompt: String) -> some View {
        Button {
            inputText = prompt
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.indigo.opacity(0.1)))
                .foregroundColor(.indigo)
        }
    }

    private func assistantBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let toolName = message.toolName {
                ToolCallCardView(toolName: toolName, params: message.content, result: "完成", isSuccess: true)
            }
            Text(message.content)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.secondary.opacity(0.1)))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let speed = message.speed {
                Text(String(format: "%.1f tok/s", speed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: 82%, alignment: .leading)
    }

    private func memoryItems() -> [String] {
        messages.filter { $0.role == .assistant && $0.toolName == "自动任务" }.map { _ in "正在跟踪 1 个自动任务" }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMessage = ChatMessage(id: UUID(), role: .user, content: inputText, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isGenerating = true

        Task {
            do {
                let response = try await chatService.sendMessage(userMessage.content)
                messages.append(response)
            } catch {
                messages.append(ChatMessage(id: UUID(), role: .assistant, content: "抱歉，处理你的请求时出现错误：\(error.localizedDescription)", timestamp: Date()))
            }
            isGenerating = false
            persistSession()
        }
    }

    private func persistSession() {
        let session = ChatSession(id: currentSessionID ?? UUID(), title: messages.first?.content ?? "新对话",
                                  updatedAt: Date(), messages: messages)
        currentSessionID = session.id
        sessionStore.upsert(session)
    }

    private func load(session: ChatSession) {
        currentSessionID = session.id
        messages = session.messages
    }
}

struct SessionListView: View {
    let onSelect: (ChatSession) -> Void
    @State private var sessions: [ChatSession] = []

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("暂无历史会话")
                        .foregroundColor(.secondary)
                }
                ForEach(sessions) { session in
                    Button {
                        onSelect(session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        SessionStore().delete(sessions[index].id)
                    }
                    sessions = SessionStore().load()
                }
            }
            .navigationTitle("历史会话")
            .onAppear {
                sessions = SessionStore().load()
            }
        }
    }
}
```

注意：`assistantBubble` 里助手气泡需限制最大宽度并左对齐：

```swift
private func assistantBubble(_ message: ChatMessage) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        if let toolName = message.toolName {
            ToolCallCardView(toolName: toolName, params: message.content, result: "完成", isSuccess: true)
        }
        Text(message.content)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.secondary.opacity(0.1)))
            .frame(maxWidth: .infinity, alignment: .leading)
        if let speed = message.speed {
            Text(String(format: "%.1f tok/s", speed))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    .padding(.trailing, 60)
}
```

- [ ] **Step 2: 从 ContentView.swift 移除旧 ChatView**

修改 `LocalMind/Sources/Views/ContentView.swift`，删除旧 `ChatView` struct（保留 `MainView`、`WorkflowListView`、`SettingsView` 定义），并在文件内不再引用已移动的类型。

- [ ] **Step 3: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodegen generate && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED（若 xcodegen 缺失则用现有 project 直接 build）

- [ ] **Step 4: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/ChatView.swift LocalMind/Sources/Views/ContentView.swift && git commit -m "feat: 对话页重写（空态能力chips + 思考卡片 + 历史会话入口）"
```

---

### Task 6: 工作流页重写——卡片化 + 新建入口

**Files:**
- Modify: `LocalMind/Sources/Views/ContentView.swift`（WorkflowListView 重写）

- [ ] **Step 1: 重写 WorkflowListView**

在 ContentView.swift 中替换 `WorkflowListView` 为卡片式布局：

```swift
struct WorkflowListView: View {
    @StateObject private var engine = ObservableWorkflowEngine(engine: WorkflowEngine.shared)
    @State private var showCreateSheet = false

    var body: some View {
        List {
            Section {
                ForEach(engine.workflows) { workflow in
                    WorkflowCardView(workflow: workflow) { enabled in
                        engine.toggle(workflow, enabled: enabled)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        engine.delete(engine.workflows[index])
                    }
                }
            } header: {
                Text("我的自动任务")
            }

            Section {
                ForEach(Array(TemplateStore.sampleTemplates.enumerated()), id: \.element.id) { _, template in
                    TemplateCardView(template: template, engine: engine)
                }
            } header: {
                Text("模板库")
            }
        }
        .navigationTitle("工作流")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建工作流")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    WorkflowLogsView(engine: engine)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            WorkflowCreateSheet(engine: engine)
        }
        .onAppear {
            engine.reload()
        }
    }
}

struct WorkflowCardView: View {
    let workflow: Workflow
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            GradientIconView(icon: workflow.isEnabled ? "bolt.fill" : "bolt",
                             gradient: workflow.isEnabled ? [.indigo, .purple] : [.gray, .gray],
                             size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(workflow.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(workflow.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(workflow.trigger.label)
                        .font(.caption2)
                }
                .foregroundColor(.indigo)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { workflow.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .tint(.indigo)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateCardView: View {
    let template: WorkflowTemplate
    var engine: ObservableWorkflowEngine?

    var body: some View {
        HStack(spacing: 12) {
            GradientIconView(icon: template.icon,
                             gradient: [.green, .teal], size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(template.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button("导入") {
                for workflow in template.workflows {
                    if let engine {
                        engine.createWorkflow(name: workflow.name, summary: workflow.summary,
                                              trigger: workflow.trigger, steps: workflow.steps)
                    } else {
                        _ = WorkflowEngine.shared.createWorkflow(name: workflow.name, summary: workflow.summary,
                                                                 trigger: workflow.trigger, steps: workflow.steps)
                    }
                }
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding(.vertical, 4)
    }
}

struct WorkflowCreateSheet: View {
    @ObservedObject var engine: ObservableWorkflowEngine
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var summary = ""
    @State private var triggerText = "每天 8:00"

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)
                TextField("描述", text: $summary)
                TextField("触发（如：每天 8:00 / 每周一 9:00）", text: $triggerText)
            }
            .navigationTitle("新建工作流")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let cron = triggerText.contains("每周") ? "0 9 * * 1"
                            : triggerText.contains("每天") ? "0 8 * * *" : "0 9 * * *"
                        engine.createWorkflow(
                            name: name.isEmpty ? "未命名任务" : name,
                            summary: summary.isEmpty ? name : summary,
                            trigger: .time(cron),
                            steps: [WorkflowStep(toolID: "notification", arguments: ["title": name.isEmpty ? "提醒" : name])]
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/ContentView.swift && git commit -m "feat: 工作流页卡片化 + 新建入口"
```

---

### Task 7: 设置页重写——Agent 管理 + 模型管理

**Files:**
- Create: `LocalMind/Sources/Views/AgentViews.swift`
- Create: `LocalMind/Sources/Views/ModelViews.swift`
- Modify: `LocalMind/Sources/Views/ContentView.swift`（SettingsView 替换）

- [ ] **Step 1: 实现 Agent 管理视图**

创建 `LocalMind/Sources/Views/AgentViews.swift`：

```swift
import SwiftUI

struct AgentListView: View {
    @State private var agents: [AgentProfile] = AgentStore.shared.loadAgents()
    @State private var showCreate = false

    var body: some View {
        List {
            Section("我的 Agents") {
                ForEach(agents) { agent in
                    AgentRowView(agent: agent)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        AgentStore.shared.delete(agents[index].id)
                    }
                    agents = AgentStore.shared.loadAgents()
                }
            }
            Section {
                Button {
                    showCreate = true
                } label: {
                    Label("新建 Agent", systemImage: "plus")
                        .foregroundColor(.indigo)
                }
            }
            Section("其他设置") {
                NavigationLink("Skills") { SkillsView() }
                NavigationLink("模型管理") { ModelListView() }
                NavigationLink("关于 / 开源") { AboutView() }
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showCreate) {
            AgentCreateSheet { agent in
                AgentStore.shared.upsert(agent)
                agents = AgentStore.shared.loadAgents()
            }
        }
        .onAppear {
            agents = AgentStore.shared.loadAgents()
        }
    }
}

struct AgentRowView: View {
    let agent: AgentProfile
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                GradientIconView(icon: agent.icon,
                                 gradient: gradient(for: agent.color), size: 40)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(agent.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if agent.isCurrent {
                            Text("当前")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                                .foregroundColor(.green)
                        }
                    }
                    Text(agent.systemPrompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showDetail) {
            AgentDetailView(agent: agent)
        }
    }

    func gradient(for color: String) -> [Color] {
        switch color {
        case "green": return [.green, .teal]
        case "orange": return [.orange, .red]
        case "purple": return [.purple, .pink]
        default: return [.indigo, .purple]
        }
    }
}

struct AgentDetailView: View {
    let agent: AgentProfile
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String
    @State private var policy: DataPolicy
    @State private var selectedModel: ModelSelection?
    @State private var tools: [String]

    init(agent: AgentProfile) {
        self.agent = agent
        _prompt = State(initialValue: agent.systemPrompt)
        _policy = State(initialValue: agent.dataPolicy)
        _selectedModel = State(initialValue: agent.selectedModel)
        _tools = State(initialValue: agent.enabledTools)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("角色设定") {
                    TextField("System Prompt", text: $prompt, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("能力") {
                    ForEach(toolOptions(), id: \.self) { tool in
                        Toggle(toolLabel(tool), isOn: Binding(
                            get: { tools.contains(tool) },
                            set: { on in
                                if on { tools.append(tool) }
                                else { tools.removeAll { $0 == tool } }
                            }
                        ))
                    }
                }
                Section("隐私与推理") {
                    Picker("数据策略", selection: $policy) {
                        ForEach([DataPolicy.localFirst, .strictLocal, .allowCloud], id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    NavigationLink {
                        ModelPickerView(selection: $selectedModel)
                    } label: {
                        HStack {
                            Text("模型")
                            Spacer()
                            Text(selectedModel.map { ModelRouter().describe(selection: $0) } ?? "本地默认")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(agent.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = agent
                        updated.systemPrompt = prompt
                        updated.dataPolicy = policy
                        updated.selectedModel = selectedModel
                        updated.enabledTools = tools
                        AgentStore.shared.upsert(updated)
                        dismiss()
                    }
                }
            }
        }
    }

    func toolOptions() -> [String] { ["calendar", "reminder", "notification"] }
    func toolLabel(_ id: String) -> String {
        switch id {
        case "calendar": return "日历"
        case "reminder": return "提醒"
        case "notification": return "通知"
        default: return id
        }
    }
}

struct AgentCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (AgentProfile) -> Void
    @State private var name = ""
    @State private var prompt = "你是 LocalMind 的专用助手。"
    @State private var color = "blue"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Agent 名称", text: $name)
                TextField("System Prompt", text: $prompt, axis: .vertical)
                    .lineLimit(3...6)
                Picker("颜色", selection: $color) {
                    Text("蓝色").tag("blue")
                    Text("绿色").tag("green")
                    Text("橙色").tag("orange")
                    Text("紫色").tag("purple")
                }
            }
            .navigationTitle("新建 Agent")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        onSave(AgentProfile(name: name.isEmpty ? "新 Agent" : name,
                                            icon: "sparkles",
                                            color: color,
                                            systemPrompt: prompt))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct SkillsView: View {
    @State private var skills: [AgentSkill] = SkillStore.shared.loadSkills()
    var body: some View {
        List {
            ForEach(skills) { skill in
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
        .navigationTitle("Skills")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            HStack {
                Text("版本")
                Spacer()
                Text("1.2.0 (P1)").foregroundColor(.secondary)
            }
        }
        .navigationTitle("关于")
    }
}
```

- [ ] **Step 2: 实现模型管理视图**

创建 `LocalMind/Sources/Views/ModelViews.swift`：

```swift
import SwiftUI

struct ModelListView: View {
    @State private var providers: [ModelProvider] = ModelConfigStore.shared.loadProviders()
    @State private var showAdd = false

    var body: some View {
        List {
            Section("本地模型") {
                ForEach(ModelType.allCases, id: \.rawValue) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                                .font(.subheadline)
                            Text(String(format: "%.1f GB", model.sizeInGB))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("未下载")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section("外部 API") {
                ForEach(providers) { provider in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(provider.modelName) · \(provider.baseURL)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("测试") {
                            Task {
                                let ok = await ModelRouter().testConnection(provider)
                                await MainActor.run {
                                    // 简单反馈：用系统 alert 或临时状态
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        ModelConfigStore.shared.deleteProvider(providers[index].id)
                    }
                    providers = ModelConfigStore.shared.loadProviders()
                }
            }
            Section {
                Button {
                    showAdd = true
                } label: {
                    Label("添加外部模型", systemImage: "plus")
                        .foregroundColor(.indigo)
                }
            }
        }
        .navigationTitle("模型管理")
        .sheet(isPresented: $showAdd) {
            ProviderFormView { provider in
                ModelConfigStore.shared.addProvider(provider)
                providers = ModelConfigStore.shared.loadProviders()
            }
        }
    }
}

struct ProviderFormView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ModelProvider) -> Void
    @State private var template: ProviderTemplate = .openAI
    @State private var name = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var modelName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("模板") {
                    Picker("Provider", selection: $template) {
                        Text("OpenAI").tag(ProviderTemplate.openAI)
                        Text("Anthropic").tag(ProviderTemplate.anthropic)
                        Text("Gemini").tag(ProviderTemplate.gemini)
                        Text("DeepSeek").tag(ProviderTemplate.deepSeek)
                        Text("自定义").tag(ProviderTemplate.custom)
                    }
                    .onChange(of: template) { _, newValue in
                        if baseURL.isEmpty, let url = newValue.baseURL {
                            baseURL = url
                        }
                        if modelName.isEmpty {
                            modelName = newValue.defaultModelName
                        }
                    }
                }
                Section("配置") {
                    TextField("名称", text: $name)
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    SecureField("API Key", text: $apiKey)
                    TextField("模型名", text: $modelName)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("添加外部模型")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let finalName = name.isEmpty ? (template == .custom ? "自定义" : "\(templateName(template))") : name
                        onSave(ModelProvider(name: finalName, template: template,
                                             baseURL: baseURL, apiKey: apiKey, modelName: modelName))
                        dismiss()
                    }
                    .disabled(baseURL.isEmpty || modelName.isEmpty)
                }
            }
        }
    }

    func templateName(_ t: ProviderTemplate) -> String {
        switch t {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Gemini"
        case .deepSeek: return "DeepSeek"
        case .custom: return "自定义"
        }
    }
}

struct ModelPickerView: View {
    @Binding var selection: ModelSelection?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
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
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
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
```

- [ ] **Step 3: 替换 ContentView 的 SettingsView**

修改 `LocalMind/Sources/Views/ContentView.swift`，将 `SettingsView` 替换为指向 `AgentListView`：

```swift
struct SettingsView: View {
    var body: some View {
        AgentListView()
    }
}
```

并删除旧的 SettingsView 大段实现（含 systemPrompt/温度/Skills/隐私/版本所有旧 UI）。

- [ ] **Step 4: 构建验证**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodegen generate && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 提交**

```bash
cd /Users/zhangbolin/Projects/local-agent && git add LocalMind/Sources/Views/AgentViews.swift LocalMind/Sources/Views/ModelViews.swift LocalMind/Sources/Views/ContentView.swift && git commit -m "feat: 设置页重写（Agent 管理 + 模型管理：本地模型/外部provider/模型选择器）"
```

---

### Task 8: 全量验证

**Files:** 无新文件

- [ ] **Step 1: 单元测试全量**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && swift test`
Expected: 全部通过（原 60 个 + 新增 SessionStore/AgentStore/ModelConfig 测试）

- [ ] **Step 2: 构建 App**

Run: `cd LocalMind && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodegen generate && xcodebuild -project LocalMind.xcodeproj -scheme LocalMind -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 模拟器安装启动 + 截图**

Run:
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID=4D7E6483-F29E-41F2-B28C-35E288B1347F
xcrun simctl terminate $UDID com.localmind.LocalMind 2>/dev/null
xcrun simctl install $UDID /Users/zhangbolin/Projects/local-agent/LocalMind/build/Build/Products/Debug-iphonesimulator/LocalMind.app
xcrun simctl launch $UDID com.localmind.LocalMind
sleep 3
xcrun simctl io $UDID screenshot /var/folders/5t/6b2npv2d0jd1r7gzc8d1rzwh0000gn/T/opencode/redesign_chat.png
```
Expected: App 启动，截图生成

- [ ] **Step 4: image-reader 校验视觉**

用 image-reader subagent 分析 `redesign_chat.png`：确认空状态 chips/orb 渲染、无黑边、无布局错乱。

- [ ] **Step 5: 提交**

无新代码提交；如有测试/构建修正则随前序任务提交。

---

## 验收清单（对照设计文档）

- [ ] 会话持久化：ChatSession 可保存/恢复/删除，重启不丢
- [ ] 多 Agent：AgentStore 默认有当前 Agent，可新建/编辑/删除/切换当前
- [ ] 模型管理：本地模型列表 + 外部 provider（模板预填/自定义）+ 模型选择器
- [ ] 对话页：空态 orb+chips、思考卡片、工具卡片、记忆条、历史入口
- [ ] 工作流页：卡片化 + 新建 sheet
- [ ] 设置页：Agent 列表 + 详情 + 模型管理
- [ ] 全部单元测试通过
- [ ] App 构建成功 + 截图经 image-reader 校验无黑边/布局正确