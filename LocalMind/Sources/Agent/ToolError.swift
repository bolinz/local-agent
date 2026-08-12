import Foundation

enum ToolError: LocalizedError {
    case invalidArguments(String)
    case permissionDenied(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let msg): return "参数无效：\(msg)"
        case .permissionDenied(let name): return "需要授权才能使用\(name)。请在系统设置中开启。"
        case .executionFailed(let msg): return "执行失败：\(msg)"
        }
    }
}
