import Foundation

struct ModelProvider: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var template: ProviderTemplate
    var baseURL: String
    var apiKey: String
    var modelName: String

    init(id: UUID = UUID(), name: String, template: ProviderTemplate,
         baseURL: String, apiKey: String, modelName: String) {
        self.id = id
        self.name = name
        self.template = template
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.modelName = modelName
    }
}

enum ProviderTemplate: String, Codable, CaseIterable {
    case openAI
    case anthropic
    case gemini
    case deepSeek
    case custom

    var baseURL: String? {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .custom: return nil
        }
    }

    var defaultModelName: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-haiku-latest"
        case .gemini: return "gemini-1.5-flash"
        case .deepSeek: return "deepseek-chat"
        case .custom: return ""
        }
    }
}