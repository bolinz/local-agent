import SwiftUI
import AppIntents

#if !SWIFTPM
@main
struct LocalMindApp: App {
    init() {
        // 测试专用：-resetData 启动参数清空本地存储，保证 UI 测试可重复
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            StorageService.shared.remove(forKey: StorageService.Keys.workflows)
            StorageService.shared.remove(forKey: StorageService.Keys.chatHistory)
            StorageService.shared.remove(forKey: "agent_skills")
            StorageService.shared.remove(forKey: "agent_config")
            StorageService.shared.remove(forKey: "chat_sessions")
            StorageService.shared.remove(forKey: "agent_profiles")
            StorageService.shared.remove(forKey: "model_providers")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#endif
