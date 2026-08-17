import XCTest
@testable import LocalMind

final class AgentStoreTests: XCTestCase {
    func testAgentProfileCodable() throws {
        let profile = AgentProfile(
            id: UUID(),
            name: "健康管家",
            icon: "heart.fill",
            color: AgentColor.green.rawValue,
            systemPrompt: "你是健康管家",
            dataPolicy: .strictLocal,
            selectedModel: nil,
            enabledTools: ["calendar", "reminder"],
            isCurrent: true
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AgentProfile.self, from: data)
        XCTAssertEqual(decoded.name, "健康管家")
        XCTAssertEqual(decoded.dataPolicy, .strictLocal)
        XCTAssertEqual(decoded.enabledTools, ["calendar", "reminder"])
    }

    func testAgentProfileDecodesOldJSONWithoutTemperature() throws {
        let oldJSON = """
        {"id":"\(UUID().uuidString)","name":"旧数据","icon":"x","color":"blue",
         "systemPrompt":"旧","dataPolicy":"localFirst","enabledTools":[],"isCurrent":true}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AgentProfile.self, from: oldJSON)
        XCTAssertEqual(decoded.temperature, 0.7)
        XCTAssertEqual(decoded.name, "旧数据")
    }

    func testAgentStoreDefaultHasCurrentAgent() {
        let store = AgentStore()
        store.saveAgents([])
        let agents = store.loadAgents()
        XCTAssertTrue(agents.contains { $0.isCurrent })
    }

    func testAgentStoreSaveLoadRoundTrip() {
        let store = AgentStore()
        store.saveAgents([])
        var agents = store.loadAgents()
        agents.append(AgentProfile(id: UUID(), name: "测试", icon: "x", color: AgentColor.blue.rawValue,
                                   systemPrompt: "测试", dataPolicy: .localFirst,
                                   selectedModel: nil, enabledTools: [], isCurrent: false))
        store.saveAgents(agents)
        let reloaded = store.loadAgents()
        XCTAssertTrue(reloaded.contains { $0.name == "测试" })
        store.saveAgents([])
    }
}