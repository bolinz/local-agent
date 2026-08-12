import XCTest
@testable import LocalMind

final class WorkflowToolTests: XCTestCase {

    override func tearDown() {
        StorageService.shared.save([Workflow](), forKey: StorageService.Keys.workflows)
        super.tearDown()
    }

    func testParseTriggerCron() {
        let tool = WorkflowTool()
        XCTAssertEqual(tool.parseTrigger("cron:0 8 * * *"), .time("0 8 * * *"))
    }

    func testParseTriggerEvent() {
        let tool = WorkflowTool()
        XCTAssertEqual(tool.parseTrigger("event:location.home"), .event("location.home"))
    }

    func testParseTriggerManual() {
        let tool = WorkflowTool()
        XCTAssertEqual(tool.parseTrigger(nil), .manual)
        XCTAssertEqual(tool.parseTrigger(""), .manual)
        XCTAssertEqual(tool.parseTrigger("unknown"), .manual)
    }

    func testParseStepsSingleStep() {
        let tool = WorkflowTool()
        let steps = tool.parseSteps("notification:title=提醒")
        XCTAssertEqual(steps.count, 1)
        XCTAssertEqual(steps[0].toolID, "notification")
        XCTAssertEqual(steps[0].arguments["title"], "提醒")
    }

    func testParseStepsMultipleSteps() {
        let tool = WorkflowTool()
        let steps = tool.parseSteps("notification:title=A;reminder:title=B,date=2026-01-01")
        XCTAssertEqual(steps.count, 2)
        XCTAssertEqual(steps[0].toolID, "notification")
        XCTAssertEqual(steps[1].toolID, "reminder")
        XCTAssertEqual(steps[1].arguments["title"], "B")
        XCTAssertEqual(steps[1].arguments["date"], "2026-01-01")
    }

    func testParseStepsEmpty() {
        let tool = WorkflowTool()
        XCTAssertEqual(tool.parseSteps(nil), [])
        XCTAssertEqual(tool.parseSteps(""), [])
    }

    func testExecuteCreatesPersistedWorkflow() async throws {
        let tool = WorkflowTool()
        let result = try await tool.execute(arguments: [
            "name": "每日晨报",
            "summary": "每天早上总结",
            "trigger": "cron:0 8 * * *",
            "steps": "notification:title=晨报",
        ])
        XCTAssertTrue(result.contains("每日晨报"))
        XCTAssertTrue(result.contains("工作流"))

        let workflows = WorkflowEngine.shared.loadWorkflows()
        let created = workflows.first { $0.name == "每日晨报" }
        XCTAssertNotNil(created)
        XCTAssertEqual(created?.trigger, .time("0 8 * * *"))
        XCTAssertEqual(created?.steps.count, 1)
    }

    func testExecuteMissingNameThrows() async {
        let tool = WorkflowTool()
        do {
            _ = try await tool.execute(arguments: ["steps": "notification:title=x"])
            XCTFail("应抛出 invalidArguments")
        } catch let error as ToolError {
            if case .invalidArguments = error {} else { XCTFail("错误类型错误：\(error)") }
        } catch {
            XCTFail("错误类型错误：\(error)")
        }
    }

    func testExecuteEmptyStepsThrows() async {
        let tool = WorkflowTool()
        do {
            _ = try await tool.execute(arguments: ["name": "x", "steps": ""])
            XCTFail("应抛出 invalidArguments")
        } catch let error as ToolError {
            if case .invalidArguments = error {} else { XCTFail("错误类型错误：\(error)") }
        } catch {
            XCTFail("错误类型错误：\(error)")
        }
    }
}
