import XCTest
@testable import LocalMind

final class WorkflowEngineTests: XCTestCase {

    private var engine: WorkflowEngine!

    override func setUp() {
        super.setUp()
        engine = WorkflowEngine.shared
    }

    override func tearDown() {
        let empty: [Workflow] = []
        StorageService.shared.save(empty, forKey: StorageService.Keys.workflows)
        super.tearDown()
    }

    func testCreateWorkflowPersists() {
        let wf = engine.createWorkflow(
            name: "测试任务",
            summary: "每日提醒",
            trigger: .time("0 9 * * *"),
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "提醒"])]
        )
        XCTAssertEqual(wf.name, "测试任务")
        XCTAssertTrue(wf.isEnabled)

        let reloaded = engine.loadWorkflows()
        XCTAssertTrue(reloaded.contains { $0.id == wf.id })
        XCTAssertEqual(reloaded.first?.name, "测试任务")
    }

    func testToggleWorkflow() {
        let wf = engine.createWorkflow(
            name: "开关测试",
            summary: "测试",
            trigger: .manual,
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "x"])]
        )
        engine.toggleWorkflow(wf, enabled: false)
        let reloaded = engine.loadWorkflows().first { $0.id == wf.id }
        XCTAssertEqual(reloaded?.isEnabled, false)
    }

    func testDeleteWorkflow() {
        let wf = engine.createWorkflow(
            name: "删除测试",
            summary: "测试",
            trigger: .manual,
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "x"])]
        )
        engine.deleteWorkflow(wf)
        let reloaded = engine.loadWorkflows()
        XCTAssertFalse(reloaded.contains { $0.id == wf.id })
    }

    func testExecuteDisabledWorkflowLogsFailure() async {
        let wf = engine.createWorkflow(
            name: "停用执行",
            summary: "测试",
            trigger: .manual,
            steps: [WorkflowStep(toolID: "notification", arguments: ["title": "x"])]
        )
        engine.toggleWorkflow(wf, enabled: false)
        let log = await engine.execute(wf)
        XCTAssertFalse(log.succeeded)
        XCTAssertTrue(log.message.contains("停用"))
    }

    func testExecuteEmptyStepsLogsFailure() async {
        let wf = engine.createWorkflow(
            name: "空步骤",
            summary: "测试",
            trigger: .manual,
            steps: []
        )
        let log = await engine.execute(wf)
        XCTAssertFalse(log.succeeded)
        XCTAssertTrue(log.message.contains("没有步骤"))
    }

    func testExecuteSuccessAppendsLog() async {
        let registry = ToolRegistry()
        let mock = MockTool(id: "mock", result: "ok")
        registry.register(mock)
        let engine = WorkflowEngine(toolRegistry: registry)

        let wf = engine.createWorkflow(
            name: "成功执行",
            summary: "测试",
            trigger: .manual,
            steps: [WorkflowStep(toolID: "mock", arguments: ["x": "1"])]
        )
        let log = await engine.execute(wf)
        XCTAssertTrue(log.succeeded)
        XCTAssertTrue(log.message.contains("执行成功"))

        let reloaded = engine.loadWorkflows().first { $0.id == wf.id }
        XCTAssertEqual(reloaded?.logs.count, 1)
    }

    func testExecutePartialFailure() async {
        let registry = ToolRegistry()
        let failing = MockTool(id: "fail", result: "boom", shouldFail: true)
        registry.register(failing)
        let engine = WorkflowEngine(toolRegistry: registry)

        let wf = engine.createWorkflow(
            name: "部分失败",
            summary: "测试",
            trigger: .manual,
            steps: [WorkflowStep(toolID: "fail", arguments: [:])]
        )
        let log = await engine.execute(wf)
        XCTAssertFalse(log.succeeded)
        XCTAssertTrue(log.message.contains("部分失败"))
    }

    func testWorkflowTriggerLabel() {
        XCTAssertEqual(WorkflowTrigger.time("0 8 * * *").label, "定时 0 8 * * *")
        XCTAssertEqual(WorkflowTrigger.event("location.home").label, "事件 location.home")
        XCTAssertEqual(WorkflowTrigger.manual.label, "手动")
    }
}
