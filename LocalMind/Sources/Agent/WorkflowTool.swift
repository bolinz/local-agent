import Foundation

class WorkflowTool: Tool {
    static let id = "workflow"
    var id: String { Self.id }
    var name: String { "自动任务" }
    var description: String { "创建可持久化的自动任务（工作流）" }
    var requiresPermission: Bool { false }

    private lazy var engine = WorkflowEngine.shared

    func execute(arguments: [String: String]) async throws -> String {
        guard let name = arguments["name"], !name.isEmpty else {
            throw ToolError.invalidArguments("缺少工作流名称")
        }
        let summary = arguments["summary"] ?? name
        let trigger = parseTrigger(arguments["trigger"])
        let steps = parseSteps(arguments["steps"])

        guard !steps.isEmpty else {
            throw ToolError.invalidArguments("工作流至少需要一个步骤")
        }

        let workflow = engine.createWorkflow(
            name: name,
            summary: summary,
            trigger: trigger,
            steps: steps
        )
        return "已创建自动任务「\(workflow.name)」：\(workflow.summary)。可在「工作流」页查看/修改。"
    }

    private func parseTrigger(_ raw: String?) -> WorkflowTrigger {
        guard let raw = raw, !raw.isEmpty else { return .manual }
        if raw.hasPrefix("cron:") {
            return .time(String(raw.dropFirst(5)))
        }
        if raw.hasPrefix("event:") {
            return .event(String(raw.dropFirst(6)))
        }
        return .manual
    }

    private func parseSteps(_ raw: String?) -> [WorkflowStep] {
        guard let raw = raw, !raw.isEmpty else { return [] }
        // 格式："toolID:参数=值,参数=值;toolID2:..."
        let parts = raw.components(separatedBy: ";")
        var steps: [WorkflowStep] = []
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let segments = trimmed.components(separatedBy: ":")
            guard let toolID = segments.first, toolID.isEmpty == false else { continue }

            var arguments: [String: String] = [:]
            if segments.count > 1 {
                let argPart = segments.dropFirst().joined(separator: ":")
                for pair in argPart.components(separatedBy: ",") {
                    let kv = pair.split(separator: "=", maxSplits: 1)
                    if kv.count == 2 {
                        arguments[String(kv[0]).trimmingCharacters(in: .whitespaces)] =
                            String(kv[1]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            steps.append(WorkflowStep(toolID: toolID, arguments: arguments))
        }
        return steps
    }
}
