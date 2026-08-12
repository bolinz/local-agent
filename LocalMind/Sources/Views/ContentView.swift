import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("对话", systemImage: "message.fill")
            }
            .tag(0)
            
            NavigationStack {
                WorkflowListView()
            }
            .tabItem {
                Label("工作流", systemImage: "flowchart")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
    }
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isGenerating = false
    
    private let chatService = ChatService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            NetworkStatusView()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            if isGenerating {
                ProgressView()
                    .padding(.vertical, 8)
            }
            
            QuickInputBar(
                text: $inputText,
                onSend: sendMessage
            )
        }
        .navigationTitle("LocalMind")
        .toolbar {
            #if canImport(UIKit)
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    messages.removeAll()
                    chatService.clearHistory()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    messages.removeAll()
                    chatService.clearHistory()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            #endif
        }
        .onAppear {
            // 加载历史消息
            messages = chatService.getHistory()
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: inputText,
            timestamp: Date()
        )
        messages.append(userMessage)
        inputText = ""
        isGenerating = true
        
        Task {
            do {
                let response = try await chatService.sendMessage(userMessage.content)
                messages.append(response)
            } catch {
                let errorMessage = ChatMessage(
                    id: UUID(),
                    role: .assistant,
                    content: "抱歉，处理你的请求时出现错误：\(error.localizedDescription)",
                    timestamp: Date()
                )
                messages.append(errorMessage)
            }
            isGenerating = false
        }
    }
}

struct WorkflowListView: View {
    @State private var workflows: [Workflow] = []
    
    private let engine = WorkflowEngine.shared
    
    var body: some View {
        List {
            Section {
                ForEach(workflows) { workflow in
                    WorkflowRow(workflow: workflow) { enabled in
                        engine.toggleWorkflow(workflow, enabled: enabled)
                        workflows = engine.loadWorkflows()
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        engine.deleteWorkflow(workflows[index])
                    }
                    workflows = engine.loadWorkflows()
                }
            }
            
            Section(header: Text("模板库")) {
                NavigationLink("省钱管家") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[0])
                }
                NavigationLink("带娃神器") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[1])
                }
                NavigationLink("长辈关怀") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[2])
                }
            }
        }
        .navigationTitle("工作流")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WorkflowLogsView(engine: ObservableWorkflowEngine(engine: engine))
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .onAppear {
            workflows = engine.loadWorkflows()
        }
    }
}

struct SettingsView: View {
    @State private var agentConfig: AgentConfig = AgentConfigStore.shared.load()
    @State private var skills: [AgentSkill] = SkillStore.shared.loadSkills()

    var body: some View {
        Form {
            Section(header: Text("Agent 配置")) {
                TextField("System Prompt", text: $agentConfig.systemPrompt, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: agentConfig) { _, newValue in
                        AgentConfigStore.shared.save(newValue)
                    }

                Picker("数据策略", selection: $agentConfig.dataPolicy) {
                    ForEach([DataPolicy.localFirst, .strictLocal, .allowCloud], id: \.self) { policy in
                        Text(policy.label).tag(policy)
                    }
                }
                .onChange(of: agentConfig.dataPolicy) { _, _ in
                    AgentConfigStore.shared.save(agentConfig)
                }

                Stepper(value: $agentConfig.temperature, in: 0.0...1.5, step: 0.1) {
                    Text("Temperature: \(agentConfig.temperature, specifier: "%.1f")")
                }
                .onChange(of: agentConfig.temperature) { _, _ in
                    AgentConfigStore.shared.save(agentConfig)
                }
            }

            Section(header: Text("AI大脑设置")) {
                NavigationLink("选择 AI 大脑") {
                    Text("模型选择")
                        .navigationTitle("AI大脑")
                }
            }

            Section(header: Text("Skills")) {
                ForEach(skills) { skill in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(skill.name)
                                .font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { skill.enabled },
                                set: { enabled in
                                    SkillStore.shared.toggle(skill, enabled: enabled)
                                    skills = SkillStore.shared.loadSkills()
                                }
                            ))
                            .labelsHidden()
                        }
                        Text(skill.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        SkillStore.shared.remove(skills[index])
                    }
                    skills = SkillStore.shared.loadSkills()
                }
            }

            Section(header: Text("隐私设置")) {
                Toggle("完全离线模式", isOn: .constant(false))

                NavigationLink("数据流向说明") {
                    Text("数据流向")
                        .navigationTitle("数据流向")
                }
            }

            Section(header: Text("关于")) {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.2.0 (P1)")
                        .foregroundColor(.secondary)
                }
                NavigationLink("开源仓库") {
                    Text("https://github.com/localmind/agent")
                        .navigationTitle("开源仓库")
                }
            }
        }
        .navigationTitle("设置")
    }
}

// Preview requires Xcode
// #Preview {
//     ContentView()
// }
