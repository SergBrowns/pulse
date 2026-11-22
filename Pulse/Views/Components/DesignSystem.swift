import SwiftUI

enum PulseTheme {
    static let work = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
    static let personal = Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255)
    static let darkCard = Color(red: 20 / 255, green: 20 / 255, blue: 22 / 255)
    static let lightBackground = Color(red: 250 / 255, green: 250 / 255, blue: 250 / 255)

    static func accent(for context: ContextMode) -> Color {
        context == .work ? work : personal
    }
}

struct PulseCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? PulseTheme.darkCard : .white)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.primary.opacity(0.09), lineWidth: 0.5)
            }
    }
}

extension View {
    func pulseCard() -> some View { modifier(PulseCardModifier()) }
}

