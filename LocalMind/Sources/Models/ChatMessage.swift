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

    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, speed, toolName, attachments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        role = try c.decode(MessageRole.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        speed = try c.decodeIfPresent(Double.self, forKey: .speed)
        toolName = try c.decodeIfPresent(String.self, forKey: .toolName)
        attachments = try c.decodeIfPresent([MessageAttachment].self, forKey: .attachments) ?? []
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}
