import XCTest
@testable import Pulse

final class NLPParserServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }

    func testRussianEventWithDuration() throws {
        let parser = NLPParserService(calendar: calendar)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 12)))

        let result = parser.parse("Созвон завтра в 15:00 на 45 минут", now: now)

        XCTAssertEqual(result.title, "Созвон")
        XCTAssertEqual(result.durationMinutes, 45)
        XCTAssertEqual(result.context, .work)
        XCTAssertEqual(result.kind, .event)
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(result.start)), 24)
        XCTAssertEqual(calendar.component(.hour, from: try XCTUnwrap(result.start)), 15)
    }

    func testEnglishPersonalTaskWithoutTime() {
        let result = NLPParserService(calendar: calendar).parse("Buy groceries")

        XCTAssertEqual(result.kind, .inboxTask)
        XCTAssertEqual(result.context, .personal)
        XCTAssertNil(result.start)
        XCTAssertEqual(result.durationMinutes, 30)
    }

    func testFridayTime() throws {
        let parser = NLPParserService(calendar: calendar)
        let monday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 8)))

        let result = parser.parse("Ревью в пятницу в 10:30", now: monday)

        let start = try XCTUnwrap(result.start)
        XCTAssertEqual(calendar.component(.weekday, from: start), 6)
        XCTAssertEqual(calendar.component(.hour, from: start), 10)
        XCTAssertEqual(calendar.component(.minute, from: start), 30)
    }
}

