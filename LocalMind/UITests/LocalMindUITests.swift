import XCTest

final class LocalMindUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainScreenRendersAndTabNavigationWorks() throws {
        let app = XCUIApplication()
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

        // 切换到设置页：Agent 配置存在
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.staticTexts["Agent 配置"].waitForExistence(timeout: 5))

        // 滚动到 Skills 区块
        let skills = app.staticTexts["Skills"]
        if !skills.exists {
            app.swipeUp()
        }
        XCTAssertTrue(skills.waitForExistence(timeout: 3))
    }

    @MainActor
    func testChatSendsMessageAndGetsReply() throws {
        let app = XCUIApplication()
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
}
