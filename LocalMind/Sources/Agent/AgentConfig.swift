import Foundation

struct AgentConfig: Codable, Equatable {
    var systemPrompt: String
    var defaultTools: [String]
    var temperature: Double
    var dataPolicy: DataPolicy

    static let `default` = AgentConfig(
        systemPrompt: "你是 LocalMind，一个运行在用户设备上的本地 AI 助手。优先在本地完成数据处理，保护用户隐私。",
        defaultTools: ["calendar", "reminder", "notification"],
        temperature: 0.7,
        dataPolicy: .localFirst
    )
}

enum DataPolicy: String, Codable, Equatable {
    case localFirst
    case strictLocal
    case allowCloud

    var label: String {
        switch self {
        case .localFirst: return "本地优先"
        case .strictLocal: return "严格本地"
        case .allowCloud: return "允许云端"
        }
    }
}

class AgentConfigStore {
    static let shared = AgentConfigStore()

    private let storage = StorageService.shared
    private let key = "agent_config"

    private init() {}

    func load() -> AgentConfig {
        if let config: AgentConfig = storage.load(AgentConfig.self, forKey: key) {
            return config
        }
        let config = AgentConfig.default
        save(config)
        return config
    }

    func save(_ config: AgentConfig) {
        storage.save(config, forKey: key)
    }
}
