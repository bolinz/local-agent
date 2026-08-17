import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ChatView()
                }
                .tag(0)
                
                NavigationStack {
                    WorkflowListView()
                }
                .tag(1)
                
                NavigationStack {
                    SettingsView()
                }
                .tag(2)
            }
            #if canImport(UIKit)
            .toolbar(.hidden, for: .tabBar)
            #endif
            
            CustomTabBar(selected: $selectedTab)
        }
    }
}

private struct TabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
}

private let tabItems: [TabItem] = [
    TabItem(id: 0, title: "对话", icon: "message.fill"),
    TabItem(id: 1, title: "工作流", icon: "flowchart.fill"),
    TabItem(id: 2, title: "设置", icon: "gearshape.fill"),
]

struct CustomTabBar: View {
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabItems) { item in
                let isSelected = selected == item.id
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = item.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.title)
                            .font(.caption2)
                            .fontWeight(isSelected ? .semibold : .regular)
                    }
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected
                                  ? AnyShapeStyle(LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.secondary.opacity(0.08)))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
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
                    if !workflow.logs.isEmpty {
                        Text("· 已运行 \(workflow.logs.count) 次")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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
    var body: some View {
        AgentListView()
    }
}
