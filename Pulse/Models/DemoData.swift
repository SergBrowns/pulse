import Foundation

enum DemoData {
    static func events(for date: Date, calendar: Calendar = .current) -> [PulseItem] {
        func time(_ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
        }

        return [
            PulseItem(
                id: "demo-standup", title: "Командный стендап", notes: "Сверяем приоритеты на день",
                start: time(9, 30), end: time(10), context: .work, kind: .event, source: .demo,
                calendarIdentifier: nil, joinURL: URL(string: "https://meet.google.com/demo-pulse"), isAllDay: false
            ),
            PulseItem(
                id: "demo-focus", title: "Фокус: прототип Pulse", notes: nil,
                start: time(10), end: time(12), context: .work, kind: .timeBlock, source: .demo,
                calendarIdentifier: nil, joinURL: nil, isAllDay: false
            ),
            PulseItem(
                id: "demo-design", title: "Дизайн-ревью", notes: "Zoom: https://zoom.us/j/123456789",
                start: time(14), end: time(14, 45), context: .work, kind: .event, source: .demo,
                calendarIdentifier: nil, joinURL: URL(string: "https://zoom.us/j/123456789"), isAllDay: false
            ),
            PulseItem(
                id: "demo-training", title: "Тренировка", notes: nil,
                start: time(18, 30), end: time(19, 30), context: .personal, kind: .event, source: .demo,
                calendarIdentifier: nil, joinURL: nil, isAllDay: false
            ),
            PulseItem(
                id: "demo-dinner", title: "Ужин с друзьями", notes: "На Патриарших",
                start: time(20), end: time(21, 30), context: .personal, kind: .event, source: .demo,
                calendarIdentifier: nil, joinURL: nil, isAllDay: false
            )
        ]
    }

    static let inbox: [(String, Int, ContextMode)] = [
        ("Подготовить план релиза", 60, .work),
        ("Ответить на важные письма", 30, .work),
        ("Купить продукты", 30, .personal),
        ("Записаться к врачу", 15, .personal)
    ]
}
