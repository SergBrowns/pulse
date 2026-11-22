import SwiftUI

struct EventCardView: View {
    @Environment(\.openURL) private var openURL
    let item: PulseItem
    let privacyShieldEnabled: Bool
    let isBackToBack: Bool
    let now: Date
    let onAddBuffer: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule()
                .fill(PulseTheme.accent(for: item.context))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    if privacyShieldEnabled && item.context == .personal {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.visibleTitle(privacyShieldEnabled: privacyShieldEnabled))
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(timeText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if let notes = item.notes, !notes.isEmpty, !(privacyShieldEnabled && item.context == .personal) {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Label(item.context == .work ? "Работа" : "Личное", systemImage: item.context.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(PulseTheme.accent(for: item.context))

                    Spacer()

                    if isBackToBack {
                        Button("Буфер 10 мин", systemImage: "arrow.right.to.line.compact") {
                            onAddBuffer()
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }

                    if item.isJoinable(at: now), let joinURL = item.joinURL {
                        Button("Войти", systemImage: "video.fill") {
                            openURL(joinURL)
                        }
                        .font(.caption.weight(.bold))
                        .buttonStyle(.borderedProminent)
                        .tint(PulseTheme.work)
                    }
                }
            }
        }
        .padding(14)
        .pulseCard()
        .accessibilityElement(children: .combine)
    }

    private var timeText: String {
        "\(item.start.formatted(date: .omitted, time: .shortened))–\(item.end.formatted(date: .omitted, time: .shortened))"
    }
}
