import AppIntents

// MARK: - App Shortcuts Provider

struct LocalMindShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateReminderIntent(),
            phrases: [
                "用 \(.applicationName) 创建提醒",
                "让 \(.applicationName) 提醒我",
            ],
            shortTitle: "创建提醒",
            systemImageName: "bell.fill"
        )

        AppShortcut(
            intent: QuickChatIntent(),
            phrases: [
                "用 \(.applicationName) 说",
                "问 \(.applicationName)",
                "让 \(.applicationName) 帮我",
            ],
            shortTitle: "快速对话",
            systemImageName: "message.fill"
        )
    }
}

// MARK: - 创建提醒 Intent

struct CreateReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "创建提醒"
    static var description = IntentDescription("让 LocalMind 创建一个定时提醒")

    @Parameter(title: "提醒内容")
    var reminderContent: String

    @Parameter(title: "提醒时间")
    var reminderDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("创建提醒 \(\.$reminderContent)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tool = ToolRegistry.shared.tool(for: "reminder")
        var arguments: [String: String] = ["title": reminderContent]
        if let reminderDate {
            arguments["date"] = ISO8601DateFormatter().string(from: reminderDate)
        }
        _ = try await tool?.execute(arguments: arguments)
        return .result(dialog: IntentDialog(stringLiteral: "已为你创建提醒：\(reminderContent)"))
    }
}

// MARK: - 快速聊天 Intent

struct QuickChatIntent: AppIntent {
    static var title: LocalizedStringResource = "快速对话"
    static var description = IntentDescription("向 LocalMind 发送一条消息")

    @Parameter(title: "消息内容")
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("问 LocalMind \(\.$message)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let chatService = ChatService.shared
        let response = try await chatService.sendMessage(message)
        return .result(dialog: IntentDialog(stringLiteral: response.content))
    }
}
