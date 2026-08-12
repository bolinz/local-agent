import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func scheduleNotification(title: String, body: String, date: Date) {
        // TODO: 使用 UNUserNotificationCenter 调度通知
        print("TODO: Schedule notification - \(title)")
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        // TODO: 使用 UNUserNotificationCenter 调度通知
        print("TODO: Schedule notification - \(title)")
    }
    
    func requestPermission() async -> Bool {
        // TODO: 请求通知权限
        // let center = UNUserNotificationCenter.current()
        // let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        // return granted ?? false
        return true
    }
    
    func cancelAllNotifications() {
        // TODO: 取消所有通知
        print("TODO: Cancel all notifications")
    }
}
