import Foundation

struct AgentProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var systemPrompt: String
    var dataPolicy: DataPolicy
    var selectedModel: ModelSelection?
    var enabledTools: [String]
    var isCurrent: Bool
    var temperature: Double

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        systemPrompt: String,
        dataPolicy: DataPolicy = .localFirst,
        selectedModel: ModelSelection? = nil,
        enabledTools: [String] = [],
        isCurrent: Bool = false,
        temperature: Double = 0.7
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.systemPrompt = systemPrompt
        self.dataPolicy = dataPolicy
        self.selectedModel = selectedModel
        self.enabledTools = enabledTools
        self.isCurrent = isCurrent
        self.temperature = temperature
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, systemPrompt, dataPolicy, selectedModel, enabledTools, isCurrent, temperature
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        color = try c.decode(String.self, forKey: .color)
        systemPrompt = try c.decode(String.self, forKey: .systemPrompt)
        dataPolicy = try c.decodeIfPresent(DataPolicy.self, forKey: .dataPolicy) ?? .localFirst
        selectedModel = try c.decodeIfPresent(ModelSelection.self, forKey: .selectedModel)
        enabledTools = try c.decodeIfPresent([String].self, forKey: .enabledTools) ?? []
        isCurrent = try c.decodeIfPresent(Bool.self, forKey: .isCurrent) ?? false
        temperature = try c.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
    }
}

enum ModelSelection: Codable, Equatable {
    case local(ModelType)
    case remote(providerID: UUID)
}

enum AgentColor: String, Codable {
    case blue, green, orange, purple, red
}
