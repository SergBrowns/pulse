import ActivityKit
import Foundation

@MainActor
final class FocusActivityService {
    private(set) var activeActivityIdentifier: String?
    private var activeHandle: FocusActivityHandle?

    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(title: String, context: ContextMode, endsAt: Date) throws {
        guard isAvailable else { throw FocusActivityError.notAvailable }
        let attributes = FocusActivityAttributes(title: title, contextRawValue: context.rawValue)
        let state = FocusActivityAttributes.ContentState(endsAt: endsAt, isPaused: false)
        let activity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: endsAt),
            pushType: nil
        )
        activeActivityIdentifier = activity.id
        activeHandle = FocusActivityHandle(activity: activity)
    }

    func update(endsAt: Date, isPaused: Bool) async {
        guard let activeHandle else { return }
        let state = FocusActivityAttributes.ContentState(endsAt: endsAt, isPaused: isPaused)
        await activeHandle.update(state: state, staleDate: endsAt)
    }

    func end() async {
        guard let activeHandle else { return }
        let finalState = FocusActivityAttributes.ContentState(endsAt: .now, isPaused: false)
        await activeHandle.end(finalState: finalState)
        self.activeHandle = nil
        self.activeActivityIdentifier = nil
    }
}

// ActivityKit допускает параллельные update/end, но Activity в SDK iOS 18
// ещё не помечен Sendable. Обёртка фиксирует владение одним экземпляром.
private final class FocusActivityHandle: @unchecked Sendable {
    private let activity: Activity<FocusActivityAttributes>

    init(activity: Activity<FocusActivityAttributes>) {
        self.activity = activity
    }

    func update(state: FocusActivityAttributes.ContentState, staleDate: Date) async {
        await activity.update(ActivityContent(state: state, staleDate: staleDate))
    }

    func end(finalState: FocusActivityAttributes.ContentState) async {
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
    }
}

enum FocusActivityError: LocalizedError {
    case notAvailable

    var errorDescription: String? { "Live Activities отключены на этом устройстве." }
}
