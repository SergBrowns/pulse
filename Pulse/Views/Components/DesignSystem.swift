import SwiftUI

enum PulseTheme {
    static let work = Color(red: 92 / 255, green: 108 / 255, blue: 1)
    static let workDeep = Color(red: 46 / 255, green: 63 / 255, blue: 210 / 255)
    static let personal = Color(red: 35 / 255, green: 205 / 255, blue: 145 / 255)
    static let personalDeep = Color(red: 10 / 255, green: 133 / 255, blue: 92 / 255)
    static let coral = Color(red: 1, green: 91 / 255, blue: 105 / 255)
    static let amber = Color(red: 1, green: 184 / 255, blue: 74 / 255)
    static let darkCanvas = Color(red: 7 / 255, green: 8 / 255, blue: 11 / 255)
    static let darkSurface = Color(red: 18 / 255, green: 19 / 255, blue: 24 / 255)
    static let lightCanvas = Color(red: 244 / 255, green: 245 / 255, blue: 249 / 255)
    static let lightSurface = Color.white

    static func accent(for context: ContextMode) -> Color { context == .work ? work : personal }
    static func deepAccent(for context: ContextMode) -> Color { context == .work ? workDeep : personalDeep }
    static func background(for scheme: ColorScheme) -> Color { scheme == .dark ? darkCanvas : lightCanvas }
    static func surface(for scheme: ColorScheme) -> Color { scheme == .dark ? darkSurface : lightSurface }
}

struct PulseCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 22
    var shadow = true

    func body(content: Content) -> some View {
        content
            .background(PulseTheme.surface(for: colorScheme))
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(colorScheme == .dark ? 0.07 : 0.7), lineWidth: 0.7)
            }
            .shadow(color: shadow ? .black.opacity(colorScheme == .dark ? 0.22 : 0.07) : .clear, radius: 18, y: 8)
    }
}

struct PulseIconButton: View {
    let systemName: String
    let accessibilityTitle: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .frame(width: 42, height: 42)
                .background(isActive ? PulseTheme.work : Color.primary.opacity(0.065), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}

extension View {
    func pulseCard(cornerRadius: CGFloat = 22, shadow: Bool = true) -> some View {
        modifier(PulseCardModifier(cornerRadius: cornerRadius, shadow: shadow))
    }
}

