import XCTest
@testable import LocalMind

final class ChatMessageAttachmentTests: XCTestCase {
    func testMessageAttachmentCodable() throws {
        let att = MessageAttachment(type: .image, name: "photo.png", localURL: "Attachments/abc.png", mimeType: "image/png")
        let data = try JSONEncoder().encode(att)
        let decoded = try JSONDecoder().decode(MessageAttachment.self, from: data)
        XCTAssertEqual(decoded.type, .image)
        XCTAssertEqual(decoded.name, "photo.png")
        XCTAssertEqual(decoded.localURL, "Attachments/abc.png")
    }

    func testChatMessageWithAttachmentsCodable() throws {
        let msg = ChatMessage(
            id: UUID(),
            role: .user,
            content: "看这张图",
            timestamp: Date(),
            attachments: [MessageAttachment(type: .image, name: "a.png", localURL: "a.png", mimeType: "image/png")]
        )
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        XCTAssertEqual(decoded.attachments.count, 1)
        XCTAssertEqual(decoded.attachments.first?.type, .image)
    }
}
