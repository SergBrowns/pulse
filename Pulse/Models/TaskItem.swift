import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String
    var durationMinutes: Int
    var contextRawValue: String
    var scheduledStart: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        durationMinutes: Int = 30,
        context: ContextMode = .personal,
        scheduledStart: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.durationMinutes = max(15, durationMinutes)
        self.contextRawValue = context.rawValue
        self.scheduledStart = scheduledStart
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    var context: ContextMode {
        get { ContextMode(rawValue: contextRawValue) ?? .personal }
        set { contextRawValue = newValue.rawValue }
    }

    var asPulseItem: PulseItem? {
        guard let scheduledStart else { return nil }
        return PulseItem(
            id: id.uuidString,
            title: title,
            notes: details.isEmpty ? nil : details,
            start: scheduledStart,
            end: scheduledStart.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            context: context,
            kind: .timeBlock,
            source: .local,
            calendarIdentifier: nil,
            joinURL: nil,
            isAllDay: false
        )
    }
}

