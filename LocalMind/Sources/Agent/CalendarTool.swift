import Foundation
import EventKit

class CalendarTool: Tool {
    static let id = "calendar"
    var id: String { Self.id }
    var name: String { "日历" }
    var description: String { "创建日程事件" }
    var requiresPermission: Bool { true }

    private let eventStore = EKEventStore()
    private let permissionService = PermissionService.shared

    func execute(arguments: [String: String]) async throws -> String {
        guard let title = arguments["title"], !title.isEmpty else {
            throw ToolError.invalidArguments("缺少日程标题")
        }

        let granted = try await permissionService.requestCalendarPermission()
        guard granted else {
            throw ToolError.permissionDenied("日历权限")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = eventStore.defaultCalendarForNewEvents

        let date: Date
        if let dateString = arguments["date"], let parsed = ISO8601DateFormatter().date(from: dateString) {
            date = parsed
        } else {
            date = Date().addingTimeInterval(3600)
        }
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600)

        try eventStore.save(event, span: .thisEvent)
        return "✅ 已创建日程：\(title)（\(date.formatted(date: .abbreviated, time: .shortened))）"
    }
}
