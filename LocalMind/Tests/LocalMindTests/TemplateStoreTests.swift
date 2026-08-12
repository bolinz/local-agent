import XCTest
@testable import LocalMind

final class TemplateStoreTests: XCTestCase {

    func testSampleTemplatesCount() {
        XCTAssertEqual(TemplateStore.sampleTemplates.count, 3)
    }

    func testTemplateNames() {
        let names = TemplateStore.sampleTemplates.map { $0.name }
        XCTAssertEqual(names, ["省钱管家", "带娃神器", "长辈关怀"])
    }

    func testEachTemplateHasWorkflow() {
        for template in TemplateStore.sampleTemplates {
            XCTAssertFalse(template.workflows.isEmpty, "模板 \(template.name) 应包含工作流")
            for wf in template.workflows {
                XCTAssertFalse(wf.name.isEmpty)
                XCTAssertFalse(wf.summary.isEmpty)
                XCTAssertFalse(wf.steps.isEmpty)
            }
        }
    }

    func testTemplateTriggersAreTimeBased() {
        for template in TemplateStore.sampleTemplates {
            for wf in template.workflows {
                if case .time = wf.trigger {} else {
                    XCTFail("模板 \(template.name) 的工作流触发器应为时间型")
                }
            }
        }
    }

    func testIconsAndSummaryPresent() {
        for template in TemplateStore.sampleTemplates {
            XCTAssertFalse(template.icon.isEmpty)
            XCTAssertFalse(template.summary.isEmpty)
        }
    }

    func testImportTemplateWorkflowPersists() {
        let engine = WorkflowEngine.shared
        let template = TemplateStore.sampleTemplates[0] // 省钱管家
        for workflow in template.workflows {
            _ = engine.createWorkflow(
                name: workflow.name,
                summary: workflow.summary,
                trigger: workflow.trigger,
                steps: workflow.steps
            )
        }

        let loaded = engine.loadWorkflows()
        XCTAssertTrue(loaded.contains { $0.name == "每月还款提醒" })

        // 清理
        StorageService.shared.save([Workflow](), forKey: StorageService.Keys.workflows)
    }
}
