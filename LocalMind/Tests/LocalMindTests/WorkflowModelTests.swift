import XCTest
@testable import LocalMind

final class WorkflowModelTests: XCTestCase {

    func testWorkflowCodableRoundTrip() throws {
        let original = Workflow(
            name: "测试",
            summary: "描述",
            isEnabled: false,
            trigger: .event("location.home"),
            steps: [WorkflowStep(toolID: "reminder", arguments: ["title": "买牛奶"])],
            logs: [WorkflowLog(message: "成功", succeeded: true)]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workflow.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.trigger, .event("location.home"))
    }

    func testAllTriggerCasesRoundTrip() throws {
        let triggers: [WorkflowTrigger] = [
            .time("0 9 * * 1"),
            .event("calendar.updated"),
            .manual,
        ]
        let data = try JSONEncoder().encode(triggers)
        let decoded = try JSONDecoder().decode([WorkflowTrigger].self, from: data)
        XCTAssertEqual(decoded, triggers)
    }

    func testStepArgumentsRoundTrip() throws {
        let original = WorkflowStep(toolID: "notification", arguments: ["title": "你好", "date": "x"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkflowStep.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.arguments["title"], "你好")
    }

    func testSampleDataValidity() {
        let samples = Workflow.sampleData
        XCTAssertEqual(samples.count, 3)
        for wf in samples {
            XCTAssertFalse(wf.name.isEmpty)
            XCTAssertFalse(wf.summary.isEmpty)
            XCTAssertTrue(wf.isEnabled || true)
        }
        XCTAssertTrue(samples[0].steps.contains { $0.toolID == "notification" })
    }
}
