import EventKit
import Foundation
import Observation

@MainActor
@Observable
final class EventKitService {
    enum AccessState: Equatable {
        case unknown
        case denied
        case granted

        var explanation: String {
            switch self {
            case .unknown: "Подключите календарь или откройте демо-режим."
            case .denied: "Доступ к календарю закрыт. Его можно разрешить в Настройках iOS."
            case .granted: "Календарь подключён."
            }
        }
    }

    private let store = EKEventStore()
    private(set) var accessState: AccessState = .unknown

    init() {
        refreshAuthorizationState()
    }

    func refreshAuthorizationState() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            accessState = .granted
        case .denied, .restricted, .writeOnly:
            accessState = .denied
        case .notDetermined:
            accessState = .unknown
        @unknown default:
            accessState = .denied
        }
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            accessState = granted ? .granted : .denied
            return granted
        } catch {
            accessState = .denied
            return false
        }
    }

    func availableCalendars() -> [EKCalendar] {
        guard accessState == .granted else { return [] }
        return store.calendars(for: .event).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func events(
        on date: Date,
        mappings: [String: ContextMode],
        calendar: Calendar = .current
    ) -> [PulseItem] {
        guard accessState == .granted,
              let start = calendar.dateInterval(of: .day, for: date)?.start,
              let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { event in
            let context = mappings[event.calendar.calendarIdentifier] ?? Self.inferContext(from: event.calendar)
            let joinURL = Self.findMeetingURL(in: [event.url?.absoluteString, event.location, event.notes])
            return PulseItem(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title.isEmpty ? "Без названия" : event.title,
                notes: event.notes,
                start: event.startDate,
                end: event.endDate,
                context: context,
                kind: .event,
                source: .eventKit,
                calendarIdentifier: event.calendar.calendarIdentifier,
                joinURL: joinURL,
                isAllDay: event.isAllDay
            )
        }
        .sorted { $0.start < $1.start }
    }

    func createEvent(
        title: String,
        notes: String?,
        start: Date,
        durationMinutes: Int,
        preferredCalendarIdentifier: String?
    ) throws {
        guard accessState == .granted else { throw EventKitError.accessDenied }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.startDate = start
        event.endDate = start.addingTimeInterval(TimeInterval(max(15, durationMinutes) * 60))
        event.calendar = preferredCalendarIdentifier
            .flatMap(store.calendar(withIdentifier:)) ?? store.defaultCalendarForNewEvents
        guard event.calendar != nil else { throw EventKitError.noWritableCalendar }
        try store.save(event, span: .thisEvent, commit: true)
    }

    func addBuffer(before item: PulseItem, minutes: Int = 10) throws {
        guard item.source == .eventKit,
              let event = store.event(withIdentifier: item.id) else { throw EventKitError.eventNotFound }
        event.startDate = event.startDate.addingTimeInterval(TimeInterval(minutes * 60))
        event.endDate = event.endDate.addingTimeInterval(TimeInterval(minutes * 60))
        try store.save(event, span: .thisEvent, commit: true)
    }

    static func inferContext(from calendar: EKCalendar) -> ContextMode {
        let text = calendar.title.lowercased()
        let workWords = ["work", "работ", "office", "команд", "project"]
        return workWords.contains(where: text.contains) ? .work : .personal
    }

    static func findMeetingURL(in values: [String?]) -> URL? {
        let hosts = ["zoom.us", "meet.google.com", "teams.microsoft.com", "t.me", "discord.gg", "discord.com"]
        let text = values.compactMap { $0 }.joined(separator: " ")
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, range: range)
            .compactMap(\.url)
            .first { url in hosts.contains { url.host?.lowercased().contains($0) == true } }
    }
}

enum EventKitError: LocalizedError {
    case accessDenied
    case noWritableCalendar
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Нет доступа к календарю."
        case .noWritableCalendar: "Не найден календарь для записи."
        case .eventNotFound: "Событие больше не найдено в календаре."
        }
    }
}

