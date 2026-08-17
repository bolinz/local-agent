import Foundation

struct MessageAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var type: AttachmentType
    var name: String
    var localURL: String
    var mimeType: String

    init(id: UUID = UUID(), type: AttachmentType, name: String, localURL: String, mimeType: String) {
        self.id = id
        self.type = type
        self.name = name
        self.localURL = localURL
        self.mimeType = mimeType
    }
}

enum AttachmentType: String, Codable {
    case image
    case file
}
