import Foundation

struct Workflow: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var summary: String
    var isEnabled: Bool
    var trigger: WorkflowTrigger
    var steps: [WorkflowStep]
    var logs: [WorkflowLog]

    init(
        id: UUID = UUID(),
        name: String,
        summary: String,
        isEnabled: Bool = true,
        trigger: WorkflowTrigger,
        steps: [WorkflowStep] = [],
        logs: [WorkflowLog] = []
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.steps = steps
        self.logs = logs
    }
}

struct WorkflowStep: Codable, Equatable {
    let toolID: String
    var arguments: [String: String]

    init(toolID: String, arguments: [String: String] = [:]) {
        self.toolID = toolID
        self.arguments = arguments
    }
}

struct WorkflowLog: Codable, Equatable, Identifiable {
    let id: UUID
    var timestamp: Date
    var message: String
    var succeeded: Bool

    init(id: UUID = UUID(), timestamp: Date = Date(), message: String, succeeded: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.succeeded = succeeded
    }
}

enum WorkflowTrigger: Codable, Equatable {
    case time(String) // cron expression
    case event(String)
    case manual

    var label: String {
        switch self {
        case .time(let cron): return "定时 \(cron)"
        case .event(let name): return "事件 \(name)"
        case .manual: return "手动"
        }
    }
}

extension Workflow {
    static let sampleData: [Workflow] = [
        Workflow(
            name: "每日晨报",
            summary: "每天早上8点创建今日待办提醒",
            isEnabled: true,
            trigger: .time("0 8 * * *"),
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "新的一天开始啦", "date": ""])]
        ),
        Workflow(
            name: "还款提醒",
            summary: "每月1号提醒还款",
            isEnabled: true,
            trigger: .time("0 9 1 * *"),
            steps: [WorkflowStep(toolID: "reminder", arguments: ["title": "检查本月账单并还款"])]
        ),
        Workflow(
            name: "阅读通知",
            summary: "每周日晚提醒整理下周计划",
            isEnabled: false,
            trigger: .time("0 20 * * 0"),
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "整理下周计划"])]
        )
    ]
}
