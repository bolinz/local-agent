import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var speed: Double?
    var toolName: String?
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
