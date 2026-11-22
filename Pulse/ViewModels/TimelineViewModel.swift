import Foundation

struct TimelineViewModel: Sendable {
    struct FreeGap: Identifiable, Equatable, Sendable {
        var id: String { "\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)" }
        let start: Date
        let end: Date
        var minutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }
        var displayText: String {
            let hours = minutes / 60
            let remainder = minutes % 60
            if remainder == 0 { return "\(hours) ч свободно — заполнить задачей?" }
            return "\(hours) ч \(remainder) мин свободно — заполнить задачей?"
        }
    }

    let date: Date
    let items: [PulseItem]
    let mode: ContextMode
    private let calendar: Calendar

    init(date: Date, items: [PulseItem], mode: ContextMode, calendar: Calendar = .current) {
        self.date = date
        self.items = items
        self.mode = mode
        self.calendar = calendar
    }

    var visibleItems: [PulseItem] {
        items.filter { mode.includes($0.context) }.sorted {
            $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start
        }
    }

    var compressedGaps: [FreeGap] {
        zip(visibleItems, visibleItems.dropFirst()).compactMap { previous, next in
            let start = previous.end
            let end = next.start
            guard end.timeIntervalSince(start) >= 2 * 60 * 60 else { return nil }
            return FreeGap(start: start, end: end)
        }
    }

    var backToBackItemIDs: Set<String> {
        var result = Set<String>()
        for (previous, next) in zip(visibleItems, visibleItems.dropFirst()) {
            let gap = next.start.timeIntervalSince(previous.end)
            if gap >= 0, gap < 60 {
                result.insert(next.id)
            }
        }
        return result
    }

    func snappedDate(hour: Int, quarter: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: min(3, max(0, quarter)) * 15, second: 0, of: date) ?? date
    }
}
