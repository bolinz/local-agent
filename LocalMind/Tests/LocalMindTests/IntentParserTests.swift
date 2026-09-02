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

    // MARK: - 边界

    func testParseEmptyInput() {
        XCTAssertEqual(IntentParser.parse(""), .none)
        XCTAssertEqual(IntentParser.parse("   "), .none)
    }

    func testParseEnglishInput() {
        XCTAssertEqual(IntentParser.parse("hello world"), .none)
        XCTAssertEqual(IntentParser.parse("remind me tomorrow"), .none)
    }

    func testParseWeekdayWithTime() {
        let now = Date()
        let intent = IntentParser.parse("周五下午5点提醒我交周报", now: now)
        guard case .createReminder(let title, let date) = intent else {
            return XCTFail("应为 createReminder")
        }
        XCTAssertEqual(title, "交周报")
        XCTAssertEqual(Calendar.current.component(.hour, from: date ?? now), 17)
        XCTAssertEqual(Calendar.current.component(.weekday, from: date ?? now), 6)
    }

    func testParseTonightWithoutHour() {
        let now = Date()
        let intent = IntentParser.parse("今晚提醒我睡觉", now: now)
        guard case .createReminder(_, let date) = intent else {
            return XCTFail("应为 createReminder")
        }
        XCTAssertEqual(Calendar.current.component(.hour, from: date ?? now), 20)
    }

    func testParseNotificationWithoutTimeIsNone() {
        XCTAssertEqual(IntentParser.parse("通知我开会"), .none)
    }

    func testExtractTitleStripsNoise() {
        XCTAssertEqual(IntentParser.extractTitle(from: "明天下午3点提醒我开会"), "开会")
        XCTAssertEqual(IntentParser.extractTitle(from: "周三上午10点预约牙医"), "牙医")
        XCTAssertEqual(IntentParser.extractTitle(from: "提醒我取快递"), "取快递")
    }

    // MARK: - 健康意图

    func testParseHealthSteps() {
        let intent = IntentParser.parse("我今天走了多少步")
        XCTAssertEqual(intent, .queryHealth(type: "steps"))
    }

    func testParseHealthHeartRate() {
        let intent = IntentParser.parse("我现在心率多少")
        XCTAssertEqual(intent, .queryHealth(type: "heartRate"))
    }

    func testParseHealthSleep() {
        let intent = IntentParser.parse("昨晚睡了几个小时")
        XCTAssertEqual(intent, .queryHealth(type: "sleep"))
    }

    func testParseHealthAll() {
        let intent = IntentParser.parse("看看我的健康数据")
        XCTAssertEqual(intent, .queryHealth(type: "all"))
    }

    // MARK: - 位置意图

    func testParseLocation() {
        XCTAssertEqual(IntentParser.parse("我现在在哪"), .queryLocation)
        XCTAssertEqual(IntentParser.parse("我的位置"), .queryLocation)
        XCTAssertEqual(IntentParser.parse("这里是什么地址"), .queryLocation)
    }

    func testParseLocationWithOtherWords() {
        XCTAssertEqual(IntentParser.parse("帮我看看定位"), .queryLocation)
    }
}
