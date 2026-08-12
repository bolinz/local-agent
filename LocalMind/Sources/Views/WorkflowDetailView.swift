import SwiftUI

struct TemplateDetailView: View {
    let template: WorkflowTemplate
    var engine: ObservableWorkflowEngine?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: template.icon)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text(template.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("包含的工作流")) {
                ForEach(template.workflows) { workflow in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workflow.name)
                            .font(.headline)
                        Text(workflow.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(workflow.trigger.label)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("导入") {
                    for workflow in template.workflows {
                        if let engine {
                            engine.createWorkflow(
                                name: workflow.name,
                                summary: workflow.summary,
                                trigger: workflow.trigger,
                                steps: workflow.steps
                            )
                        } else {
                            _ = WorkflowEngine.shared.createWorkflow(
                                name: workflow.name,
                                summary: workflow.summary,
                                trigger: workflow.trigger,
                                steps: workflow.steps
                            )
                        }
                    }
                    dismiss()
                }
            }
        }
    }
}

struct WorkflowLogsView: View {
    @ObservedObject var engine: ObservableWorkflowEngine

    var body: some View {
        List {
            let logs = engine.allLogs()
            if logs.isEmpty {
                Text("暂无执行记录")
                    .foregroundColor(.secondary)
            }
            ForEach(logs.reversed()) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: log.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(log.succeeded ? .green : .red)
                        Text(log.message)
                            .font(.subheadline)
                    }
                    Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("执行日志")
    }
}

final class ObservableWorkflowEngine: ObservableObject {
    private let engine: WorkflowEngine
    @Published var workflows: [Workflow] = []

    init(engine: WorkflowEngine) {
        self.engine = engine
    }

    func reload() {
        workflows = engine.loadWorkflows()
    }

    func createWorkflow(name: String, summary: String, trigger: WorkflowTrigger, steps: [WorkflowStep]) {
        _ = engine.createWorkflow(name: name, summary: summary, trigger: trigger, steps: steps)
        reload()
    }

    func toggle(_ workflow: Workflow, enabled: Bool) {
        engine.toggleWorkflow(workflow, enabled: enabled)
        reload()
    }

    func delete(_ workflow: Workflow) {
        engine.deleteWorkflow(workflow)
        reload()
    }

    func allLogs() -> [WorkflowLog] {
        engine.loadWorkflows().flatMap { $0.logs }
    }
}
