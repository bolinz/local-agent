import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var pendingAttachments: [MessageAttachment] = []
    @State private var isGenerating = false
    @State private var isStreaming = false
    @State private var streamingTexts: [UUID: String] = [:]
    @State private var currentSessionID: UUID?
    @State private var showSessions = false
    @State private var agentID: UUID? = AgentStore.shared.currentAgent()?.id
    @State private var modelSelection: ModelSelection?

    private let chatService = ChatService.shared
    private let sessionStore = SessionStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    showSessions = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.body)
                        .foregroundColor(.indigo)
                }
                .accessibilityLabel(NSLocalizedString("history_sessions", comment: ""))
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
                .accessibilityLabel(NSLocalizedString("new_session", comment: ""))

                Spacer()

                GlowPillView(text: NSLocalizedString("local_running", comment: ""))
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
                                if !message.attachments.isEmpty {
                                    ForEach(message.attachments) { att in
                                        HStack { Spacer(); AttachmentBubbleView(attachment: att) }
                                    }
                                }
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
            } else if isStreaming {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("输入中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }

            MemoryStripView(items: memoryItems())
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            AgentModelSwitcher(agentID: $agentID, modelSelection: $modelSelection)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

            QuickInputBar(text: $inputText, onSend: sendMessage) { att in
                pendingAttachments.append(att)
            }
        }
        .navigationTitle("LocalMind")
        #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if messages.isEmpty {
                messages = chatService.getHistory()
                if messages.isEmpty, ProcessInfo.processInfo.arguments.contains("-testAttachment") {
                    let testAtt = MessageAttachment(type: .file, name: "测试文件.txt", localURL: "Attachments/测试文件.txt", mimeType: "text/plain")
                    let msg = ChatMessage(id: UUID(), role: .user, content: "请看这个附件", timestamp: Date(), attachments: [testAtt])
                    messages.append(msg)
                }
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
            Text(NSLocalizedString("empty_title", comment: ""))
                .font(.title3)
                .fontWeight(.bold)
            Text(NSLocalizedString("empty_subtitle", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                chip("📅 \(NSLocalizedString("chip_create_reminder", comment: ""))", "创建一个明天下午3点的会议提醒")
                chip("📊 \(NSLocalizedString("chip_summary_schedule", comment: ""))", "帮我总结本周的日程")
            }
            HStack(spacing: 8) {
                chip("💊 \(NSLocalizedString("chip_medication_reminder", comment: ""))", "每天8点提醒我吃药")
                chip("🏠 \(NSLocalizedString("chip_smart_home", comment: ""))", "晚上到家自动开灯")
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
                ToolCallCardView(toolName: toolName,
                                 params: String(message.content.prefix(40)) + (message.content.count > 40 ? "…" : ""),
                                 result: "完成", isSuccess: true)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text(streamingTexts[message.id] ?? message.content)
                    .font(.body)
                if let text = streamingTexts[message.id], text.count < message.content.count {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.secondary.opacity(0.1)))
            .frame(maxWidth: .infinity, alignment: .leading)
            if let speed = message.speed, streamingTexts[message.id] == nil {
                Text(String(format: "%.1f tok/s", speed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 60)
    }

    private func memoryItems() -> [String] {
        let count = messages.filter { $0.role == .assistant && $0.toolName == "自动任务" }.count
        return count > 0 ? ["正在跟踪 \(count) 个自动任务"] : []
    }

    private func sendMessage() {
        guard !inputText.isEmpty || !pendingAttachments.isEmpty else { return }
        guard !isGenerating && !isStreaming else { return }
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

        Task {
            do {
                let response = try await chatService.sendMessage(userMessage.content)
                messages.append(response)
                isGenerating = false
                await startStreaming(response)
            } catch {
                messages.append(ChatMessage(id: UUID(), role: .assistant, content: "抱歉，处理你的请求时出现错误：\(error.localizedDescription)", timestamp: Date()))
                isGenerating = false
            }
            persistSession()
        }
    }

    @MainActor
    private func startStreaming(_ message: ChatMessage) async {
        guard !message.content.isEmpty else { return }
        isStreaming = true
        streamingTexts[message.id] = ""
        let fullText = message.content
        let charsPerStep = fullText.count > 200 ? 3 : 2
        let stepDelay: UInt64 = fullText.count > 200 ? 12_000_000 : 15_000_000
        var index = 0
        while index < fullText.count {
            index += charsPerStep
            let end = min(index, fullText.count)
            let startIdx = fullText.index(fullText.startIndex, offsetBy: 0)
            let endIdx = fullText.index(fullText.startIndex, offsetBy: end)
            streamingTexts[message.id] = String(fullText[startIdx..<endIdx])
            try? await Task.sleep(nanoseconds: stepDelay)
        }
        streamingTexts[message.id] = fullText
        isStreaming = false
    }

    private func startNewSession() {
        clearAttachmentFiles()
        messages = []
        streamingTexts = [:]
        isStreaming = false
        currentSessionID = nil
        isGenerating = false
    }

    private func clearAttachmentFiles() {
        for msg in messages {
            for att in msg.attachments {
                AttachmentStore.shared.delete(att.localURL)
            }
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
                    Text(NSLocalizedString("no_history", comment: ""))
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
                            HStack(spacing: 8) {
                                Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                Text("· \(session.messages.count) 条消息")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let session = sessions[index]
                        for att in session.messages.flatMap(\.attachments) {
                            AttachmentStore.shared.delete(att.localURL)
                        }
                        SessionStore().delete(session.id)
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