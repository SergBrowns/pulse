import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
        var isPaused: Bool
    }

    var title: String
    var contextRawValue: String
}

