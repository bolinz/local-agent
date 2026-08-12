import XCTest
@testable import LocalMind

final class ChatServiceTests: XCTestCase {

    private var registry: ToolRegistry!
    private var reminderTool: MockTool!
    private var workflowTool: MockTool!

    override func setUp() {
        super.setUp()
        registry = ToolRegistry()
        reminderTool = MockTool(id: "reminder", name: "提醒事项", result: "✅ 已创建提醒")
        workflowTool = MockTool(id: "workflow", name: "自动任务", result: "已创建自动任务")
        registry.register(reminderTool)
        registry.register(workflowTool)
    }

    override func tearDown() {
        StorageService.shared.save([Workflow](), forKey: StorageService.Keys.workflows)
        super.tearDown()
    }

    private func makeService() -> ChatService {
        ChatService(toolRegistry: registry)
    }

    // MARK: - 兜底回复

    func testPlainChatReturnsFallbackReply() async throws {
        let service = makeService()
        let reply = try await service.sendMessage("你好")
        XCTAssertTrue(reply.role == .assistant)
        XCTAssertTrue(reply.content.contains("本地 AI 助手"))
    }

    func testHealthKeywordReturnsData() async throws {
        let service = makeService()
        let reply = try await service.sendMessage("我的健康数据怎么样")
        XCTAssertTrue(reply.content.contains("健康数据"))
    }

    // MARK: - 工具分发

    func testReminderIntentDispatchesToReminderTool() async throws {
        let service = makeService()
        let reply = try await service.sendMessage("提醒我取快递")

        XCTAssertEqual(reminderTool.callCount, 1)
        XCTAssertEqual(reminderTool.lastArguments["title"], "取快递")
        XCTAssertTrue(reply.content.contains("[工具：提醒事项]"))
    }

    func testReminderWithDatePassesISO8601Argument() async throws {
        let service = makeService()
        _ = try await service.sendMessage("明天下午3点提醒我开会")

        XCTAssertEqual(reminderTool.callCount, 1)
        let dateArg = reminderTool.lastArguments["date"]
        XCTAssertNotNil(dateArg)
        let parsed = ISO8601DateFormatter().date(from: dateArg ?? "")
        XCTAssertNotNil(parsed)
    }

    // MARK: - 工作流创建

    func testRecurringIntentDispatchesToWorkflowTool() async throws {
        let service = makeService()
        let reply = try await service.sendMessage("每天早上8点提醒我喝水")

        XCTAssertEqual(workflowTool.callCount, 1)
        XCTAssertEqual(workflowTool.lastArguments["name"], "喝水")
        XCTAssertEqual(workflowTool.lastArguments["trigger"], "cron:0 9 * * *")
        XCTAssertTrue(reply.content.contains("[工具：自动任务]"))
    }

    func testWeeklyIntentUsesWeeklyCron() async throws {
        let service = makeService()
        _ = try await service.sendMessage("每周一总结上周邮件")

        XCTAssertEqual(workflowTool.callCount, 1)
        XCTAssertEqual(workflowTool.lastArguments["trigger"], "cron:0 9 * * 1")
    }

    func testMonthlyIntentUsesMonthlyCron() async throws {
        let service = makeService()
        _ = try await service.sendMessage("每月1号提醒我还款")

        XCTAssertEqual(workflowTool.callCount, 1)
        XCTAssertEqual(workflowTool.lastArguments["trigger"], "cron:0 9 1 * *")
    }

    func testToolFailureShowsErrorMessage() async throws {
        let failing = MockTool(id: "reminder", name: "提醒事项", result: "权限被拒", shouldFail: true)
        let customRegistry = ToolRegistry()
        customRegistry.register(failing)
        let service = ChatService(toolRegistry: customRegistry)

        let reply = try await service.sendMessage("提醒我取快递")
        XCTAssertTrue(reply.content.contains("抱歉"))
        XCTAssertTrue(reply.content.contains("调用工具时出现问题"))
    }

    // MARK: - 历史记录

    func testConversationHistoryTracksMessages() async throws {
        let service = makeService()
        _ = try await service.sendMessage("你好")
        _ = try await service.sendMessage("提醒我取快递")

        let history = service.getHistory()
        XCTAssertEqual(history.count, 4) // 2 user + 2 assistant
        XCTAssertEqual(history.filter { $0.role == .user }.count, 2)
        XCTAssertEqual(history.filter { $0.role == .assistant }.count, 2)
    }

    func testClearHistory() async throws {
        let service = makeService()
        _ = try await service.sendMessage("你好")
        service.clearHistory()
        XCTAssertTrue(service.getHistory().isEmpty)
    }
}
