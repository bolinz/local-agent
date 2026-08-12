import XCTest
@testable import LocalMind

final class IntentParserTests: XCTestCase {

    func testParseReminderWithTime() {
        let now = Date()
        let intent = IntentParser.parse("明天下午3点提醒我开会", now: now)
        guard case .createReminder(let title, let date) = intent else {
            return XCTFail("应为 createReminder，实际 \(intent)")
        }
        XCTAssertEqual(title, "开会")
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: date ?? now)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
        XCTAssertEqual(comps.day, cal.component(.day, from: tomorrow))
        XCTAssertEqual(comps.hour, 15)
    }

    func testParseReminderWithoutDate() {
        let intent = IntentParser.parse("提醒我取快递")
        XCTAssertEqual(intent, .createReminder(title: "取快递", date: nil))
    }

    func testParseCalendarEvent() {
        let intent = IntentParser.parse("周三下午2点安排项目评审会")
        guard case .createEvent(let title, let date) = intent else {
            return XCTFail("应为 createEvent")
        }
        XCTAssertEqual(title, "项目评审会")
        XCTAssertEqual(Calendar.current.component(.hour, from: date ?? Date()), 14)
    }

    func testParseNotification() {
        let intent = IntentParser.parse("今晚8点通知我吃药")
        guard case .scheduleNotification(let title, let date) = intent else {
            return XCTFail("应为 scheduleNotification")
        }
        XCTAssertEqual(title, "吃药")
        XCTAssertEqual(Calendar.current.component(.hour, from: date ?? Date()), 20)
    }

    func testParseNoneForPlainChat() {
        XCTAssertEqual(IntentParser.parse("你好"), .none)
        XCTAssertEqual(IntentParser.parse("今天天气怎么样"), .none)
    }

    func testExtractHourAmPm() {
        XCTAssertEqual(IntentParser.extractHour(from: "下午3点"), 15)
        XCTAssertEqual(IntentParser.extractHour(from: "上午9点"), 9)
        XCTAssertEqual(IntentParser.extractHour(from: "15点"), 15)
        XCTAssertNil(IntentParser.extractHour(from: "没有时间"))
    }
}
