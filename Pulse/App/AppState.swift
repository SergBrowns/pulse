import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var selectedDate = Date.now
    var contextMode: ContextMode = .all
    var privacyShieldEnabled: Bool {
        didSet { UserDefaults.standard.set(privacyShieldEnabled, forKey: Keys.privacyShield) }
    }
    var isDemoMode = false
    var isInboxPresented = false
    var isSettingsPresented = false
    var isLoading = false
    var errorMessage: String?
    var systemEvents: [PulseItem] = []
    var colorSchemePreference = 0

    let eventKit = EventKitService()

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case 1: .light
        case 2: .dark
        default: nil
        }
    }

    init() {
        privacyShieldEnabled = UserDefaults.standard.bool(forKey: Keys.privacyShield)
    }

    func loadEvents(mappings: [CalendarMapping]) {
        isLoading = true
        defer { isLoading = false }
        if isDemoMode {
            systemEvents = DemoData.events(for: selectedDate)
        } else {
            let dictionary = Dictionary(uniqueKeysWithValues: mappings.map { ($0.calendarIdentifier, $0.context) })
            systemEvents = eventKit.events(on: selectedDate, mappings: dictionary)
        }
    }

    func enableDemo() {
        isDemoMode = true
        systemEvents = DemoData.events(for: selectedDate)
    }

    func setContext(_ mode: ContextMode) {
        contextMode = mode
        HapticManager.selection()
    }

    func report(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private enum Keys {
        static let privacyShield = "pulse.privacyShield"
    }
}

