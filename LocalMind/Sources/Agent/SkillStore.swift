import Foundation

struct AgentSkill: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var summary: String
    var instructions: String
    var requiredTools: [String]
    var enabled: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        summary: String,
        instructions: String,
        requiredTools: [String] = [],
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.instructions = instructions
        self.requiredTools = requiredTools
        self.enabled = enabled
    }
}

class SkillStore {
    static let shared = SkillStore()

    private let storage = StorageService.shared
    private let key = "agent_skills"

    private init() {}

    func loadSkills() -> [AgentSkill] {
        if let loaded: [AgentSkill] = storage.load([AgentSkill].self, forKey: key) {
            return loaded
        }
        let sample = sampleSkills()
        saveSkills(sample)
        return sample
    }

    func saveSkills(_ skills: [AgentSkill]) {
        storage.save(skills, forKey: key)
    }

    func install(_ skill: AgentSkill) {
        var skills = loadSkills()
        skills.removeAll { $0.id == skill.id }
        skills.append(skill)
        saveSkills(skills)
    }

    func remove(_ skill: AgentSkill) {
        var skills = loadSkills()
        skills.removeAll { $0.id == skill.id }
        saveSkills(skills)
    }

    func toggle(_ skill: AgentSkill, enabled: Bool) {
        var skills = loadSkills()
        guard let index = skills.firstIndex(where: { $0.id == skill.id }) else { return }
        skills[index].enabled = enabled
        saveSkills(skills)
    }

    private func sampleSkills() -> [AgentSkill] {
        [
            AgentSkill(
                id: "money_manager",
                name: "省钱管家",
                summary: "还款提醒、账单整理等财务自动化",
                instructions: "当用户提到还款、账单、记账时，使用提醒工具创建定时任务。",
                requiredTools: ["reminder"]
            ),
            AgentSkill(
                id: "kid_helper",
                name: "带娃神器",
                summary: "作业提醒、睡前故事等育儿助手",
                instructions: "当用户提到作业、睡前故事、育儿时，提供相关内容或创建提醒。",
                requiredTools: ["notification"]
            ),
            AgentSkill(
                id: "senior_care",
                name: "长辈关怀",
                summary: "用药提醒、健康关怀",
                instructions: "当用户提到吃药、健康、家人时，创建用药提醒并给出关怀建议。",
                requiredTools: ["notification"]
            ),
        ]
    }
}
