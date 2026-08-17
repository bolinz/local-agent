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
            #if canImport(UIKit)
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    WorkflowLogsView(engine: engine)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    WorkflowLogsView(engine: engine)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                }
            }
            #endif
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
