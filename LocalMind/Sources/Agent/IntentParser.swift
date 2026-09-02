import Foundation

enum ToolIntent: Equatable {
    case none
    case createReminder(title: String, date: Date?)
    case createEvent(title: String, date: Date?)
    case scheduleNotification(title: String, date: Date?)
    case queryHealth(type: String)
    case queryLocation

    var toolID: String? {
        switch self {
        case .none: return nil
        case .createReminder: return "reminder"
        case .createEvent: return "calendar"
        case .scheduleNotification: return "notification"
        case .queryHealth: return "health"
        case .queryLocation: return "location"
        }
    }
}

struct IntentParser {
    static func parse(_ input: String, now: Date = Date()) -> ToolIntent {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }

        let lowered = trimmed.lowercased()
        let (date, _) = extractDate(from: input, now: now)
        let title = extractTitle(from: trimmed)

        // 提醒：明确提到"提醒/别忘/记得" → Reminder
        if lowered.contains("提醒") || lowered.contains("别忘") || lowered.contains("记得") {
            return .createReminder(title: title, date: date)
        }
        // 日程：提到"日程/安排/会议/评审/约" → Calendar
        if lowered.contains("日程") || lowered.contains("安排") || lowered.contains("会议")
            || lowered.contains("评审") || lowered.contains("约") {
            return .createEvent(title: title, date: date)
        }
        // 通知：明确提到"通知"且带时间 → Notification
        if lowered.contains("通知") && date != nil {
            return .scheduleNotification(title: title, date: date)
        }
        // 健康：提到步数/心率/睡眠/健康 → Health
        if lowered.contains("步数") || lowered.contains("步") || lowered.contains("心率") || lowered.contains("睡眠")
            || lowered.contains("睡") || lowered.contains("健康") || lowered.contains("运动") {
            if lowered.contains("步") { return .queryHealth(type: "steps") }
            if lowered.contains("心率") || lowered.contains("心跳") { return .queryHealth(type: "heartRate") }
            if lowered.contains("睡眠") || lowered.contains("睡") { return .queryHealth(type: "sleep") }
            return .queryHealth(type: "all")
        }
        // 位置：提到位置/在哪/哪里/地址 → Location
        if lowered.contains("位置") || lowered.contains("在哪") || lowered.contains("哪里")
            || lowered.contains("地址") || lowered.contains("定位") {
            return .queryLocation
        }
        return .none
    }

    static func extractDate(from input: String, now: Date) -> (Date?, Bool) {
        let calendar = Calendar.current

        // 明天
        if input.contains("明天") {
            let base = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            if let hour = extractHour(from: input) {
                return (calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base), true)
            }
            return (calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base), true)
        }
        // 今晚 → 今天 20:00（默认）
        if input.contains("今晚") {
            if let hour = extractHour(from: input) {
                return (calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now), true)
            }
            return (calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now), true)
        }
        // 今天 / 现在
        if input.contains("今天") || input.contains("现在") {
            if let hour = extractHour(from: input) {
                return (calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now), true)
            }
            return (now, true)
        }
        // 周几（周三/星期三）
        if let weekday = extractWeekday(from: input) {
            let base = nextOccurrence(of: weekday, from: now, calendar: calendar)
            if let hour = extractHour(from: input) {
                return (calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base), true)
            }
            return (calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base), true)
        }
        // 只给小时（如 "下午3点"）
        if let hour = extractHour(from: input) {
            return (calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now), true)
        }
        return (nil, false)
    }

    static func extractWeekday(from input: String) -> Int? {
        let map: [(String, Int)] = [
            ("周一", 2), ("星期一", 2), ("周二", 3), ("星期二", 3),
            ("周三", 4), ("星期三", 4), ("周四", 5), ("星期四", 5),
            ("周五", 6), ("星期五", 6), ("周六", 7), ("星期六", 7),
            ("周日", 1), ("周天", 1), ("星期天", 1), ("星期日", 1),
        ]
        for (keyword, weekday) in map where input.contains(keyword) {
            return weekday
        }
        return nil
    }

    static func nextOccurrence(of weekday: Int, from now: Date, calendar: Calendar) -> Date {
        let today = calendar.component(.weekday, from: now)
        var daysAhead = weekday - today
        if daysAhead <= 0 { daysAhead += 7 }
        return calendar.date(byAdding: .day, value: daysAhead, to: now) ?? now
    }

    static func extractHour(from input: String) -> Int? {
        guard let digitsRange = input.range(of: #"(\d{1,2})\s*点"#, options: .regularExpression) else { return nil }
        let digitPart = String(input[digitsRange]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let number = Int(digitPart), number >= 0, number <= 23 else { return nil }

        let prefix = String(input[..<digitsRange.lowerBound])
        var hour = number
        if prefix.contains("下午") || prefix.contains("晚上") || prefix.contains("今晚") {
            hour = (hour % 12) + 12
        } else if prefix.contains("上午") {
            hour = hour % 12
        }
        return hour
    }

    static func extractTitle(from input: String) -> String {
        var text = input
        let removalPatterns = [
            #"周[一二三四五六日天]"#,
            #"星期[一二三四五六日天]"#,
            #"(\d{1,2})\s*点"#,
            #"(明天|今天|现在|今晚|上午|下午|晚上)"#,
            #"(提醒我|提醒|别忘|记得|通知我|通知|帮我|请|帮我设置|请帮我)"#,
            #"(设置|创建|建个|加个|记下|安排|预约)"#,
        ]
        for pattern in removalPatterns {
            text = text.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { text = input }
        return text
    }
}
