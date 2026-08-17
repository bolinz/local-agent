import Foundation

class AttachmentStore {
    static let shared = AttachmentStore()
    private let fileManager = FileManager.default
    private let attachmentsDir: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        attachmentsDir = docs.appendingPathComponent("Attachments", isDirectory: true)
        try? fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
    }

    /// 返回相对路径（存于 ChatMessage.localURL），用于后续读取
    func save(data: Data, name: String) -> String {
        let safeName = sanitize(name)
        let uniqueName = "\(UUID().uuidString.prefix(8))_\(safeName)"
        let url = attachmentsDir.appendingPathComponent(uniqueName)
        try? data.write(to: url)
        return "Attachments/\(uniqueName)"
    }

    private func sanitize(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let safe = name.components(separatedBy: invalid).joined(separator: "_")
        return safe.isEmpty ? "file" : safe
    }

    func fileURL(for relative: String) -> URL? {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(relative)
    }

    func delete(_ relative: String) {
        if let url = fileURL(for: relative) {
            try? fileManager.removeItem(at: url)
        }
    }
}
