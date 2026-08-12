import Foundation
@testable import LocalMind

final class MockTool: Tool {
    let id: String
    let name: String
    let description: String
    let requiresPermission: Bool
    let result: String
    let shouldFail: Bool
    private(set) var lastArguments: [String: String] = [:]
    private(set) var callCount = 0

    init(id: String, name: String = "mock", result: String, shouldFail: Bool = false) {
        self.id = id
        self.name = name
        self.description = "mock tool"
        self.requiresPermission = false
        self.result = result
        self.shouldFail = shouldFail
    }

    func execute(arguments: [String: String]) async throws -> String {
        callCount += 1
        lastArguments = arguments
        if shouldFail {
            throw ToolError.executionFailed(result)
        }
        return result
    }
}
