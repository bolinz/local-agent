import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func scheduleNotification(title: String, body: String, date: Date) {
        // POC: 本地模拟，真实实现需 UNUserNotificationCenter 调度
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        // POC: 本地模拟
    }
    
    func requestPermission() async -> Bool {
        // POC: 默认返回 true；真实实现需请求 UNUserNotificationCenter 授权
        return true
    }
    
    func cancelAllNotifications() {
        // POC: 本地模拟
    }
}
