import Foundation

class WorkflowEngine {
    static let shared = WorkflowEngine()

    private let storage = StorageService.shared
    private let toolRegistry: ToolRegistry
    private let workflowsKey = StorageService.Keys.workflows

    init(toolRegistry: ToolRegistry? = nil) {
        self.toolRegistry = toolRegistry ?? ToolRegistry.shared
    }

    func loadWorkflows() -> [Workflow] {
        if let loaded: [Workflow] = storage.load([Workflow].self, forKey: workflowsKey) {
            return loaded
        }
        let sample = Workflow.sampleData
        saveWorkflows(sample)
        return sample
    }

    func saveWorkflows(_ workflows: [Workflow]) {
        storage.save(workflows, forKey: workflowsKey)
    }

    func createWorkflow(
        name: String,
        summary: String,
        trigger: WorkflowTrigger,
        steps: [WorkflowStep]
    ) -> Workflow {
        let workflow = Workflow(
            name: name,
            summary: summary,
            isEnabled: true,
            trigger: trigger,
            steps: steps
        )
        var workflows = loadWorkflows()
        workflows.insert(workflow, at: 0)
        saveWorkflows(workflows)
        return workflow
    }

    func deleteWorkflow(_ workflow: Workflow) {
        var workflows = loadWorkflows()
        workflows.removeAll { $0.id == workflow.id }
        saveWorkflows(workflows)
    }

    func toggleWorkflow(_ workflow: Workflow, enabled: Bool) {
        var workflows = loadWorkflows()
        guard let index = workflows.firstIndex(where: { $0.id == workflow.id }) else { return }
        workflows[index].isEnabled = enabled
        saveWorkflows(workflows)
    }

    func execute(_ workflow: Workflow) async -> WorkflowLog {
        let current = loadWorkflows().first { $0.id == workflow.id } ?? workflow
        let result = await executeSteps(current)
        var workflows = loadWorkflows()
        guard let index = workflows.firstIndex(where: { $0.id == workflow.id }) else {
            return WorkflowLog(message: "工作流不存在", succeeded: false)
        }
        workflows[index].logs.append(result)
        saveWorkflows(workflows)
        return result
    }

    private func executeSteps(_ workflow: Workflow) async -> WorkflowLog {
        guard workflow.isEnabled else {
            return WorkflowLog(message: "工作流已停用", succeeded: false)
        }
        guard !workflow.steps.isEmpty else {
            return WorkflowLog(message: "工作流没有步骤", succeeded: false)
        }

        var failures: [String] = []
        for step in workflow.steps {
            guard let tool = toolRegistry.tool(for: step.toolID) else {
                failures.append("未知工具：\(step.toolID)")
                continue
            }
            do {
                _ = try await tool.execute(arguments: step.arguments)
            } catch {
                failures.append("\(tool.name)：\(error.localizedDescription)")
            }
        }

        if failures.isEmpty {
            return WorkflowLog(message: "执行成功（\(workflow.steps.count) 个步骤）", succeeded: true)
        } else {
            return WorkflowLog(message: "部分失败：\(failures.joined(separator: "；"))", succeeded: false)
        }
    }
}
