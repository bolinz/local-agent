import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var speed: Double?
}

enum MessageRole {
    case user
    case assistant
}
