import Foundation

struct PulseItem: Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case event
        case timeBlock
    }

    enum Source: String, Codable, Sendable {
        case eventKit
        case local
        case demo
    }

    let id: String
    var title: String
    var notes: String?
    var start: Date
    var end: Date
    var context: ContextMode
    var kind: Kind
    var source: Source
    var calendarIdentifier: String?
    var joinURL: URL?
    var isAllDay: Bool

    var duration: TimeInterval { end.timeIntervalSince(start) }

    func visibleTitle(privacyShieldEnabled: Bool) -> String {
        privacyShieldEnabled && context == .personal ? "Личное время" : title
    }

    func isJoinable(at date: Date) -> Bool {
        guard joinURL != nil else { return false }
        return date >= start.addingTimeInterval(-15 * 60) && date <= end
    }
}

