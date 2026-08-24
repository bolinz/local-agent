import XCTest
@testable import LocalMind

final class SkillStoreTests: XCTestCase {

    override func tearDown() {
        StorageService.shared.remove(forKey: "agent_skills")
        super.tearDown()
    }

    func testLoadReturnsSamples() {
        let skills = SkillStore.shared.loadSkills()
        XCTAssertEqual(skills.count, 3)
        XCTAssertTrue(skills.contains { $0.id == "money_manager" })
    }

    func testInstallAndRemove() {
        let store = SkillStore.shared
        _ = store.loadSkills()

        let custom = AgentSkill(name: "自定义技能", summary: "测试", instructions: "指令")
        store.install(custom)
        XCTAssertTrue(store.loadSkills().contains { $0.id == custom.id })

        store.remove(custom)
        XCTAssertFalse(store.loadSkills().contains { $0.id == custom.id })
    }

    func testToggleSkill() {
        let store = SkillStore.shared
        let skills = store.loadSkills()
        guard let skill = skills.first else { return XCTFail("无示例技能") }

        store.toggle(skill, enabled: false)
        let reloaded = store.loadSkills().first { $0.id == skill.id }
        XCTAssertEqual(reloaded?.enabled, false)
    }
}
