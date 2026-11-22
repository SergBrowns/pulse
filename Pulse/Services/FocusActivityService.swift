import ActivityKit
import Foundation

@MainActor
final class FocusActivityService {
    private(set) var activeActivity: Activity<FocusActivityAttributes>?

    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(title: String, context: ContextMode, endsAt: Date) throws {
        guard isAvailable else { throw FocusActivityError.notAvailable }
        let attributes = FocusActivityAttributes(title: title, contextRawValue: context.rawValue)
        let state = FocusActivityAttributes.ContentState(endsAt: endsAt, isPaused: false)
        activeActivity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: endsAt),
            pushType: nil
        )
    }

    func update(endsAt: Date, isPaused: Bool) async {
        guard let activeActivity else { return }
        let state = FocusActivityAttributes.ContentState(endsAt: endsAt, isPaused: isPaused)
        await activeActivity.update(ActivityContent(state: state, staleDate: endsAt))
    }

    func end() async {
        guard let activeActivity else { return }
        let finalState = FocusActivityAttributes.ContentState(endsAt: .now, isPaused: false)
        await activeActivity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
        self.activeActivity = nil
    }
}

enum FocusActivityError: LocalizedError {
    case notAvailable

    var errorDescription: String? { "Live Activities отключены на этом устройстве." }
}
