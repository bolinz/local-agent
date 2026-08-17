import Foundation

class AgentStore {
    static let shared = AgentStore()
    private let storage: StorageService
    private let key = "agent_profiles"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func loadAgents() -> [AgentProfile] {
        if let loaded = storage.load([AgentProfile].self, forKey: key), !loaded.isEmpty {
            return loaded
        }
        let defaults = [AgentProfile(
            name: "LocalMind 通用助手",
            icon: "brain.head.profile",
            color: AgentColor.blue.rawValue,
            systemPrompt: "你是 LocalMind，一个运行在用户设备上的本地 AI 助手。优先在本地完成数据处理，保护用户隐私。",
            dataPolicy: .localFirst,
            enabledTools: ["calendar", "reminder", "notification"],
            isCurrent: true
        )]
        saveAgents(defaults)
        return defaults
    }

    func saveAgents(_ agents: [AgentProfile]) {
        storage.save(agents, forKey: key)
    }

    func currentAgent() -> AgentProfile? {
        loadAgents().first { $0.isCurrent }
    }

    func setCurrent(_ id: UUID) {
        var agents = loadAgents()
        for i in agents.indices {
            agents[i].isCurrent = (agents[i].id == id)
        }
        saveAgents(agents)
    }

    func upsert(_ agent: AgentProfile) {
        var agents = loadAgents()
        if let idx = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[idx] = agent
        } else {
            agents.append(agent)
        }
        saveAgents(agents)
    }

    func delete(_ id: UUID) {
        var agents = loadAgents()
        agents.removeAll { $0.id == id }
        saveAgents(agents)
    }
}