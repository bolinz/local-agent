import Foundation

struct SessionStore {
    private let storage: StorageService
    private let key = "chat_sessions"

    init(storage: StorageService = .shared) {
        self.storage = storage
    }

    func load() -> [ChatSession] {
        storage.load([ChatSession].self, forKey: key) ?? []
    }

    func save(_ sessions: [ChatSession]) {
        storage.save(sessions, forKey: key)
    }

    func upsert(_ session: ChatSession) {
        var sessions = load()
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        save(sessions)
    }

    func delete(_ id: UUID) {
        var sessions = load()
        sessions.removeAll { $0.id == id }
        save(sessions)
    }
}