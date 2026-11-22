import XCTest
@testable import Pulse

final class TimelineViewModelTests: XCTestCase {
    func testCompressesOnlyGapsOfTwoHoursOrMore() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let items = [
            item("a", start: base, minutes: 30),
            item("b", start: base.addingTimeInterval(60 * 60), minutes: 30),
            item("c", start: base.addingTimeInterval(4 * 60 * 60), minutes: 30)
        ]

        let model = TimelineViewModel(date: base, items: items, mode: .all)

        XCTAssertEqual(model.compressedGaps.count, 1)
        XCTAssertEqual(model.compressedGaps.first?.minutes, 150)
    }

    func testContextFilter() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let items = [
            item("work", start: base, minutes: 30, context: .work),
            item("personal", start: base, minutes: 30, context: .personal)
        ]

        XCTAssertEqual(TimelineViewModel(date: base, items: items, mode: .work).visibleItems.map(\.id), ["work"])
        XCTAssertEqual(TimelineViewModel(date: base, items: items, mode: .all).visibleItems.count, 2)
    }

    func testBackToBackDetection() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let items = [
            item("a", start: base, minutes: 30),
            item("b", start: base.addingTimeInterval(30 * 60), minutes: 30)
        ]

        let ids = TimelineViewModel(date: base, items: items, mode: .all).backToBackItemIDs

        XCTAssertEqual(ids, Set(["b"]))
    }

    private func item(
        _ id: String,
        start: Date,
        minutes: Int,
        context: ContextMode = .work
    ) -> PulseItem {
        PulseItem(
            id: id,
            title: id,
            notes: nil,
            start: start,
            end: start.addingTimeInterval(TimeInterval(minutes * 60)),
            context: context,
            kind: .event,
            source: .demo,
            calendarIdentifier: nil,
            joinURL: nil,
            isAllDay: false
        )
    }
}
