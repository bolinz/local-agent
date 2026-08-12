import Foundation
@testable import LocalMind

struct MockTool: Tool {
    let id: String
    let name: String
    let description: String
    let requiresPermission: Bool
    let result: String
    let shouldFail: Bool

    init(id: String, name: String = "mock", result: String, shouldFail: Bool = false) {
        self.id = id
        self.name = name
        self.description = "mock tool"
        self.requiresPermission = false
        self.result = result
        self.shouldFail = shouldFail
    }

    func execute(arguments: [String: String]) async throws -> String {
        if shouldFail {
            throw ToolError.executionFailed(result)
        }
        return result
    }
}
