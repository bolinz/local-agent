import Foundation

class ChatService {
    static let shared = ChatService()
    
    private let toolRegistry = ToolRegistry.shared
    private var conversationHistory: [ChatMessage] = []
    
    private init() {}
    
    func sendMessage(_ text: String) async throws -> ChatMessage {
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: text,
            timestamp: Date()
        )
        conversationHistory.append(userMessage)
        
        let responseText = try await generateResponse(to: text)
        
        let assistantMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: responseText,
            timestamp: Date()
        )
        conversationHistory.append(assistantMessage)
        
        return assistantMessage
    }
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
    
    func getHistory() -> [ChatMessage] {
        return conversationHistory
    }
    
    private func generateResponse(to input: String) async throws -> String {
        // 1. 优先识别"周期性自动化"意图 → WorkflowTool
        if let workflowResponse = try await tryCreateWorkflow(from: input) {
            return workflowResponse
        }
        
        // 2. 尝试工具调用（Agent 的"手"）
        if let response = try await tryExecuteTool(intent: IntentParser.parse(input)) {
            return response
        }
        
        // 3. 兜底：模拟本地模型回复
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if input.contains("健康") || input.contains("睡眠") {
            return "✅ 已为你查询健康数据：\n- 今日步数：8,432步\n- 平均心率：72次/分钟\n- 昨晚睡眠：6.2小时"
        } else if input.contains("天气") {
            return "🌤 北京今天晴转多云，气温15-28°C，适合外出活动。"
        } else {
            return "我理解你的需求。作为你的本地 AI 助手，我会在设备上为你处理这些任务。数据不会离开你的设备。"
        }
    }
    
    private func tryCreateWorkflow(from input: String) async throws -> String? {
        // 周期性关键词：每/每天/每周/每月 + 动作
        guard input.contains("每") || input.contains("每天") || input.contains("每周")
            || input.contains("每月") else {
            return nil
        }
        
        guard let tool = toolRegistry.tool(for: WorkflowTool.id) else { return nil }
        
        let title = extractWorkflowTitle(from: input)
        let trigger = parseRecurrence(from: input)
        let steps = workflowSteps(from: input)
        
        let result = try await tool.execute(arguments: [
            "name": title,
            "summary": input,
            "trigger": trigger,
            "steps": steps,
        ])
        return "[工具：\(tool.name)] \(result)"
    }
    
    private func extractWorkflowTitle(from input: String) -> String {
        var text = input
        let patterns = [
            #"(每天早上|每天|每周一|每周日|每月|每)\s*"#,
            #"(帮我|请|帮我设置|提醒我)"#,
        ]
        for pattern in patterns {
            text = text.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { text = "自动任务" }
        if text.count > 12 { text = String(text.prefix(12)) }
        return text
    }
    
    private func parseRecurrence(from input: String) -> String {
        if input.contains("每周") { return "cron:0 9 * * 1" }
        if input.contains("每月") { return "cron:0 9 1 * *" }
        return "cron:0 9 * * *"
    }
    
    private func workflowSteps(from input: String) -> String {
        if input.contains("提醒") {
            return "reminder:title=\(extractWorkflowTitle(from: input))"
        }
        return "notification:title=\(extractWorkflowTitle(from: input))"
    }
    
    private func tryExecuteTool(intent: ToolIntent) async throws -> String? {
        guard intent != .none, let toolID = intent.toolID, let tool = toolRegistry.tool(for: toolID) else {
            return nil
        }
        
        let arguments = toolArguments(for: intent)
        let result = try await tool.execute(arguments: arguments)
        return "[工具：\(tool.name)] \(result)"
    }
    
    private func toolArguments(for intent: ToolIntent) -> [String: String] {
        switch intent {
        case .none:
            return [:]
        case .createReminder(let title, let date),
             .createEvent(let title, let date),
             .scheduleNotification(let title, let date):
            var args: [String: String] = ["title": title]
            if let date = date {
                args["date"] = ISO8601DateFormatter().string(from: date)
            }
            return args
        }
    }
}
