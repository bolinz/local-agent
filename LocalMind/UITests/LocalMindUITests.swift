import XCTest

final class LocalMindUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if reset {
            app.launchArguments = ["-resetData"]
        }
        return app
    }

    @MainActor
    func testMainScreenRendersAndTabNavigationWorks() throws {
        let app = makeApp(reset: true)
        app.launch()

        // 主界面三个 Tab 存在
        XCTAssertTrue(app.tabBars.buttons["对话"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["工作流"].exists)
        XCTAssertTrue(app.tabBars.buttons["设置"].exists)

        // 输入框存在（对话页）
        XCTAssertTrue(app.textFields["输入消息..."].exists)

        // 切换到工作流页：模板库存在
        app.tabBars.buttons["工作流"].tap()
        XCTAssertTrue(app.staticTexts["模板库"].waitForExistence(timeout: 5))

        // 切换到设置页：Agent 管理存在
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.staticTexts["我的 Agents"].waitForExistence(timeout: 5))

        // 滚动到 Skills 区块
        let skills = app.staticTexts["Skills"]
        if !skills.exists {
            app.swipeUp()
        }
        XCTAssertTrue(skills.waitForExistence(timeout: 3))
    }

    @MainActor
    func testChatSendsMessageAndGetsReply() throws {
        let app = makeApp(reset: true)
        app.launch()

        let input = app.textFields["输入消息..."]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("hello")
        app.buttons["发送"].tap()

        // 等待 assistant 回复出现（验证收发闭环）
        let reply = app.staticTexts["我理解你的需求。作为你的本地 AI 助手，我会在设备上为你处理这些任务。数据不会离开你的设备。"]
        XCTAssertTrue(reply.waitForExistence(timeout: 10))
    }

    @MainActor
    func testImportWorkflowTemplate() throws {
        let app = makeApp(reset: true)
        app.launch()

        // 进入工作流页
        app.tabBars.buttons["工作流"].tap()
        XCTAssertTrue(app.staticTexts["模板库"].waitForExistence(timeout: 5))

        // 模板卡直接带"导入"按钮（省钱管家）
        app.swipeUp()
        let importButtons = app.buttons.matching(identifier: "导入")
        XCTAssertTrue(importButtons.firstMatch.waitForExistence(timeout: 5))
        importButtons.firstMatch.tap()

        // 导入后返回列表顶部，导入的工作流出现在"我的自动任务"区
        for _ in 0..<5 {
            app.swipeDown()
            usleep(200_000)
        }
        XCTAssertTrue(app.staticTexts["每月还款提醒"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testToggleWorkflowEnabled() throws {
        let app = makeApp(reset: true)
        app.launch()

        app.tabBars.buttons["工作流"].tap()
        XCTAssertTrue(app.staticTexts["每日晨报"].waitForExistence(timeout: 5))

        // 找到并切换"每日晨报"的开关
        let cell = app.cells.containing(.staticText, identifier: "每日晨报").firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.switches.firstMatch.tap()
    }

    @MainActor
    func testSettingsScreenShowsAgentConfig() throws {
        let app = makeApp(reset: true)
        app.launch()

        app.tabBars.buttons["设置"].tap()

        // 设置页关键区块渲染（Agent 管理 / Skills 入口）
        XCTAssertTrue(app.staticTexts["我的 Agents"].waitForExistence(timeout: 5), "我的 Agents 未出现")
        XCTAssertTrue(app.staticTexts["LocalMind 通用助手"].waitForExistence(timeout: 5), "默认 Agent 未出现")
        let skills = app.staticTexts["Skills"]
        if !skills.exists {
            app.swipeUp()
        }
        XCTAssertTrue(skills.waitForExistence(timeout: 3), "Skills 未出现")
    }
}
