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
        .tint(.accentColor)
    }
}

struct WorkflowListView: View {
    @StateObject private var engine = ObservableWorkflowEngine(engine: WorkflowEngine.shared)
    
    var body: some View {
        List {
            Section {
                ForEach(engine.workflows) { workflow in
                    WorkflowRow(workflow: workflow) { enabled in
                        engine.toggle(workflow, enabled: enabled)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        engine.delete(engine.workflows[index])
                    }
                }
            }
            
            Section(header: Text("模板库")) {
                NavigationLink("省钱管家") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[0], engine: engine)
                }
                NavigationLink("带娃神器") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[1], engine: engine)
                }
                NavigationLink("长辈关怀") {
                    TemplateDetailView(template: TemplateStore.sampleTemplates[2], engine: engine)
                }
            }
        }
        .id(engine.workflows.map(\.id))
        .navigationTitle("工作流")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WorkflowLogsView(engine: engine)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                }
            }
        }
        .onAppear {
            engine.reload()
        }
    }
}

struct SettingsView: View {
    @State private var agentConfig: AgentConfig = AgentConfigStore.shared.load()
    @State private var skills: [AgentSkill] = SkillStore.shared.loadSkills()

    var body: some View {
        Form {
            Section {
                TextField("System Prompt", text: $agentConfig.systemPrompt, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("systemPromptField")
                    .onChange(of: agentConfig) { _, newValue in
                        AgentConfigStore.shared.save(newValue)
                    }
            } header: {
                Text("Agent 配置")
            } footer: {
                Text("定义 AI 的角色和行为方式")
                    .font(.caption)
            }

            Section {
                Picker("数据策略", selection: $agentConfig.dataPolicy) {
                    ForEach([DataPolicy.localFirst, .strictLocal, .allowCloud], id: \.self) { policy in
                        Text(policy.label).tag(policy)
                    }
                }
                .onChange(of: agentConfig.dataPolicy) { _, _ in
                    AgentConfigStore.shared.save(agentConfig)
                }

                Stepper(value: $agentConfig.temperature, in: 0.0...1.5, step: 0.1) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", agentConfig.temperature))
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: agentConfig.temperature) { _, _ in
                    AgentConfigStore.shared.save(agentConfig)
                }
            } header: {
                Text("推理设置")
            }

            Section {
                ForEach(skills) { skill in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(skill.summary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        SkillStore.shared.remove(skills[index])
                    }
                    skills = SkillStore.shared.loadSkills()
                }
            } header: {
                Text("Skills")
            } footer: {
                Text("技能包为 AI 提供预定义能力")
                    .font(.caption)
            }

            Section {
                Toggle("完全离线模式", isOn: .constant(false))
                NavigationLink("数据流向说明") {
                    Text("数据流向")
                        .navigationTitle("数据流向")
                }
            } header: {
                Text("隐私")
            }

            Section {
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
