import Foundation

struct AgentProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var systemPrompt: String
    var dataPolicy: DataPolicy
    var temperature: Double
    var selectedModel: ModelSelection?
    var enabledTools: [String]
    var isCurrent: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        systemPrompt: String,
        dataPolicy: DataPolicy = .localFirst,
        temperature: Double = 0.7,
        selectedModel: ModelSelection? = nil,
        enabledTools: [String] = [],
        isCurrent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.systemPrompt = systemPrompt
        self.dataPolicy = dataPolicy
        self.temperature = temperature
        self.selectedModel = selectedModel
        self.enabledTools = enabledTools
        self.isCurrent = isCurrent
    }
}

enum ModelSelection: Codable, Equatable {
    case local(ModelType)
    case remote(providerID: UUID)
}

enum AgentColor: String, Codable {
    case blue, green, orange, purple, red
}