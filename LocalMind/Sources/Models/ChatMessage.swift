import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var speed: Double?
    var toolName: String?
    var attachments: [MessageAttachment] = []

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date,
        speed: Double? = nil,
        toolName: String? = nil,
        attachments: [MessageAttachment] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.speed = speed
        self.toolName = toolName
        self.attachments = attachments
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
