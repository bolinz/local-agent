import XCTest
@testable import LocalMind

final class ToolRegistryTests: XCTestCase {

    func testDefaultRegistryRegistersAllTools() {
        let registry = ToolRegistry()
        XCTAssertNotNil(registry.tool(for: "calendar"))
        XCTAssertNotNil(registry.tool(for: "reminder"))
        XCTAssertNotNil(registry.tool(for: "notification"))
        XCTAssertNotNil(registry.tool(for: "workflow"))
        XCTAssertNotNil(registry.tool(for: "health"))
        XCTAssertNotNil(registry.tool(for: "location"))
    }

    func testAllToolsCount() {
        let registry = ToolRegistry()
        XCTAssertEqual(registry.allTools().count, 6)
    }

    func testRegisterAndLookup() {
        let registry = ToolRegistry()
        let mock = MockTool(id: "custom", result: "ok")
        registry.register(mock)
        XCTAssertNotNil(registry.tool(for: "custom"))
        XCTAssertNil(registry.tool(for: "missing"))
    }

    func testOverwriteById() {
        let registry = ToolRegistry()
        registry.register(MockTool(id: "dup", result: "first"))
        registry.register(MockTool(id: "dup", result: "second"))
        let tool = registry.tool(for: "dup") as? MockTool
        XCTAssertEqual(tool?.result, "second")
    }

    func testToolProtocolMetadata() {
        let tool = ToolRegistry().tool(for: "workflow")
        XCTAssertEqual(tool?.id, "workflow")
        XCTAssertNotNil(tool?.name)
        XCTAssertNotNil(tool?.description)
        XCTAssertFalse(tool?.requiresPermission ?? true)
    }
}
