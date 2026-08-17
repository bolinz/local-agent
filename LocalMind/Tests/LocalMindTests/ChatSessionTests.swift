import XCTest
@testable import LocalMind

final class ChatSessionTests: XCTestCase {
    func testChatSessionCodableRoundTrip() throws {
        let session = ChatSession(
            id: UUID(),
            title: "测试会话",
            updatedAt: Date(),
            messages: [
                ChatMessage(id: UUID(), role: .user, content: "你好", timestamp: Date()),
                ChatMessage(id: UUID(), role: .assistant, content: "你好！", timestamp: Date())
            ]
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ChatSession.self, from: data)
        XCTAssertEqual(decoded.title, "测试会话")
        XCTAssertEqual(decoded.messages.count, 2)
    }

    func testChatSessionStorePersistsAndLoads() {
        let store = SessionStore()
        let session = ChatSession(id: UUID(), title: "会话A", updatedAt: Date(), messages: [])
        store.upsert(session)
        let loaded = store.load()
        XCTAssertTrue(loaded.contains { $0.title == "会话A" })
        store.delete(session.id)
        let afterDelete = store.load()
        XCTAssertFalse(afterDelete.contains { $0.id == session.id })
    }
}