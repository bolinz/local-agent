import Foundation

class HealthKitTool: Tool {
    static let id = "health"
    var id: String { Self.id }
    var name: String { "健康数据" }
    var description: String { "查询健康数据：步数、心率、睡眠" }
    var requiresPermission: Bool { true }

    private let manager = HealthKitManager.shared

    func execute(arguments: [String: String]) async throws -> String {
        guard manager.isAvailable else {
            return "❌ HealthKit 在此设备上不可用（需要 iPhone 真机）"
        }

        let queryType = arguments["type"] ?? "all"

        var lines: [String] = []

        if queryType == "all" || queryType == "steps" {
            let steps = try await manager.fetchTodayStepCount()
            lines.append("- 今日步数：\(steps)步")
        }

        if queryType == "all" || queryType == "heartRate" {
            if let hr = try await manager.fetchLatestHeartRate() {
                lines.append("- 最近心率：\(Int(hr))次/分钟")
            } else {
                lines.append("- 最近心率：暂无数据")
            }
        }

        if queryType == "all" || queryType == "sleep" {
            if let hours = try await manager.fetchLastNightSleepHours() {
                lines.append("- 昨晚睡眠：\(String(format: "%.1f", hours))小时")
            } else {
                lines.append("- 昨晚睡眠：暂无数据")
            }
        }

        return "✅ 健康数据：\n\(lines.joined(separator: "\n"))"
    }
}
