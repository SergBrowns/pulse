import Foundation
import SwiftData

@Model
final class CalendarMapping {
    @Attribute(.unique) var calendarIdentifier: String
    var calendarTitle: String
    var contextRawValue: String

    init(calendarIdentifier: String, calendarTitle: String, context: ContextMode) {
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.contextRawValue = context.rawValue
    }

    var context: ContextMode {
        get { ContextMode(rawValue: contextRawValue) ?? .personal }
        set { contextRawValue = newValue.rawValue }
    }
}

