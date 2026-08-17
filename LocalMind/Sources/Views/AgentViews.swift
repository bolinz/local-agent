import SwiftUI

struct AgentListView: View {
    @State private var agents: [AgentProfile] = AgentStore.shared.loadAgents()
    @State private var showCreate = false

    var body: some View {
        List {
            Section("我的 Agents") {
                ForEach(agents) { agent in
                    AgentRowView(agent: agent) {
                        agents = AgentStore.shared.loadAgents()
                    }
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
    var onChange: () -> Void = {}
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
            AgentDetailView(agent: agent) {
                onChange()
            }
        }
        .contextMenu {
            if !agent.isCurrent {
                Button("设为当前 Agent") {
                    AgentStore.shared.setCurrent(agent.id)
                    onChange()
                }
            }
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
    var onSave: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String
    @State private var policy: DataPolicy
    @State private var temperature: Double
    @State private var selectedModel: ModelSelection?
    @State private var tools: [String]

    init(agent: AgentProfile, onSave: @escaping () -> Void = {}) {
        self.agent = agent
        self.onSave = onSave
        _prompt = State(initialValue: agent.systemPrompt)
        _policy = State(initialValue: agent.dataPolicy)
        _temperature = State(initialValue: agent.temperature)
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
                Section {
                    ForEach(toolOptions(), id: \.self) { tool in
                        Toggle(toolLabel(tool), isOn: Binding(
                            get: { tools.contains(tool) },
                            set: { on in
                                if on { tools.append(tool) }
                                else { tools.removeAll { $0 == tool } }
                            }
                        ))
                    }
                } header: {
                    Text("能力")
                } footer: {
                    Text("已启用 \(tools.count) / \(toolOptions().count) 个工具，Agent 仅能调用启用项")
                        .font(.caption)
                }
                Section("隐私与推理") {
                    Picker("数据策略", selection: $policy) {
                        ForEach([DataPolicy.localFirst, .strictLocal, .allowCloud], id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    Stepper(value: $temperature, in: 0.0...1.5, step: 0.1) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", temperature))
                                .foregroundColor(.secondary)
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
                        updated.temperature = temperature
                        updated.selectedModel = selectedModel
                        updated.enabledTools = tools
                        AgentStore.shared.upsert(updated)
                        onSave()
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

struct AboutView: View {
    var body: some View {
        List {
            HStack {
                Text("版本")
                Spacer()
                Text("1.2.0 (P1)").foregroundColor(.secondary)
            }
            if let url = URL(string: "https://github.com/bolinz/local-agent") {
                Link(destination: url) {
                    HStack {
                        Text("开源仓库")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("关于")
    }
}