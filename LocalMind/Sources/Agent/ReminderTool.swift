import Foundation
import EventKit

class ReminderTool: Tool {
    static let id = "reminder"
    var id: String { Self.id }
    var name: String { "提醒事项" }
    var description: String { "创建提醒事项" }
    var requiresPermission: Bool { true }

    private let eventStore = EKEventStore()
    private let permissionService = PermissionService.shared

    func execute(arguments: [String: String]) async throws -> String {
        guard let title = arguments["title"], !title.isEmpty else {
            throw ToolError.invalidArguments("缺少提醒内容")
        }

        let granted = try await permissionService.requestReminderPermission()
        guard granted else {
            throw ToolError.permissionDenied("提醒事项权限")
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dateString = arguments["date"], let date = ISO8601DateFormatter().date(from: dateString) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: date
            )
            reminder.addAlarm(EKAlarm(absoluteDate: date))
        }

        try eventStore.save(reminder, commit: true)
        return "✅ 已创建提醒：\(title)"
    }
}
