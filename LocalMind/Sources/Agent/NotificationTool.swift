import Foundation
import UserNotifications

class NotificationTool: Tool {
    static let id = "notification"
    var id: String { Self.id }
    var name: String { "通知" }
    var description: String { "发送一次性本地通知" }
    var requiresPermission: Bool { true }

    func execute(arguments: [String: String]) async throws -> String {
        guard let title = arguments["title"], !title.isEmpty else {
            throw ToolError.invalidArguments("缺少通知内容")
        }

        let granted = await NotificationService.shared.requestPermission()
        guard granted else {
            throw ToolError.permissionDenied("通知权限")
        }

        let date: Date
        if let dateString = arguments["date"], let parsed = ISO8601DateFormatter().date(from: dateString) {
            date = parsed
        } else {
            date = Date().addingTimeInterval(3600)
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "来自 LocalMind 的通知"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)

        return "✅ 已设置通知：\(title)（\(date.formatted(date: .abbreviated, time: .shortened))）"
    }
}
