import Foundation

class ToolRegistry {
    static let shared = ToolRegistry()

    private var tools: [String: Tool] = [:]

    init() {
        register(CalendarTool())
        register(ReminderTool())
        register(NotificationTool())
        register(WorkflowTool())
    }

    func register(_ tool: Tool) {
        tools[tool.id] = tool
    }

    func tool(for id: String) -> Tool? {
        return tools[id]
    }

    func allTools() -> [Tool] {
        return Array(tools.values)
    }
}
