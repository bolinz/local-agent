import SwiftUI

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
