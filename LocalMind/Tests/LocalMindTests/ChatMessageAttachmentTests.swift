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

    func testChatMessageDecodesOldJSONWithoutAttachments() throws {
        let oldJSON = """
        {"id":"\(UUID().uuidString)","role":"user","content":"旧消息","timestamp":\(Date().timeIntervalSince1970)}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: oldJSON)
        XCTAssertEqual(decoded.content, "旧消息")
        XCTAssertEqual(decoded.attachments, [])
    }
}

final class AttachmentStoreTests: XCTestCase {
    func testSaveReturnsRelativePathWithAttachmentsPrefix() {
        let data = "test".data(using: .utf8)!
        let path = AttachmentStore.shared.save(data: data, name: "test.txt")
        XCTAssertTrue(path.hasPrefix("Attachments/"))
        XCTAssertTrue(path.contains("test.txt"))
    }

    func testSaveSanitizesSpecialCharacters() {
        let data = "test".data(using: .utf8)!
        let path = AttachmentStore.shared.save(data: data, name: "a/b:c?d*e.txt")
        // 应该包含 sanitized 版本：a_b_c_d_e.txt
        XCTAssertTrue(path.contains("a_b_c_d_e.txt"))
        XCTAssertFalse(path.contains("/b:") || path.hasSuffix("b:c?d*e.txt"))
    }

    func testSaveSanitizesEmptyNameToFile() {
        let data = "test".data(using: .utf8)!
        let path = AttachmentStore.shared.save(data: data, name: "")
        XCTAssertTrue(path.contains("file"))
    }

    func testSaveGeneratesUniqueFilenames() {
        let data = "test".data(using: .utf8)!
        let path1 = AttachmentStore.shared.save(data: data, name: "same.txt")
        let path2 = AttachmentStore.shared.save(data: data, name: "same.txt")
        XCTAssertNotEqual(path1, path2, "Same name should produce unique paths")
    }

    func testSaveCreatesFileOnDisk() {
        let data = "hello".data(using: .utf8)!
        let path = AttachmentStore.shared.save(data: data, name: "disk_test.txt")
        let url = AttachmentStore.shared.fileURL(for: path)
        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
        // cleanup
        AttachmentStore.shared.delete(path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url!.path))
    }

    func testFileURLResolvesCorrectly() {
        let path = "Attachments/test.txt"
        let url = AttachmentStore.shared.fileURL(for: path)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("Attachments/test.txt"))
    }
}
