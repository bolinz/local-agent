import Foundation

protocol Tool {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var requiresPermission: Bool { get }
    func execute(arguments: [String: String]) async throws -> String
}
