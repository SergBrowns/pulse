import SwiftUI

struct EventCardView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    let item: PulseItem
    let privacyShieldEnabled: Bool
    let isBackToBack: Bool
    let now: Date
    let onAddBuffer: () -> Void

    private var accent: Color { PulseTheme.accent(for: item.context) }
    private var isLive: Bool { now >= item.start && now <= item.end }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                contextBadge
                if isLive {
                    Label("СЕЙЧАС", systemImage: "waveform")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(PulseTheme.coral)
                }
                Spacer()
                Text(durationText)
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 9) {
                if privacyShieldEnabled && item.context == .personal {
                    Image(systemName: "lock.fill")
                        .font(.caption).foregroundStyle(accent)
                        .frame(width: 26, height: 26)
                        .background(accent.opacity(0.12), in: Circle())
                }
                Text(item.visibleTitle(privacyShieldEnabled: privacyShieldEnabled))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notes = item.notes, !notes.isEmpty, !(privacyShieldEnabled && item.context == .personal) {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if isBackToBack || item.isJoinable(at: now) {
                HStack(spacing: 8) {
                    if isBackToBack {
                        Button {
                            onAddBuffer()
                        } label: {
                            Label("Добавить 10 мин", systemImage: "cup.and.saucer.fill")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(PulseTheme.amber.opacity(0.14), in: Capsule())
                        }
                        .buttonStyle(.plain).foregroundStyle(PulseTheme.amber)
                    }
                    Spacer()
                    if item.isJoinable(at: now), let joinURL = item.joinURL {
                        Button {
                            openURL(joinURL)
                        } label: {
                            Label("Войти", systemImage: "video.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background {
            ZStack(alignment: .topTrailing) {
                PulseTheme.surface(for: colorScheme)
                LinearGradient(
                    colors: [accent.opacity(colorScheme == .dark ? 0.16 : 0.09), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle().fill(accent.opacity(0.08)).frame(width: 90, height: 90).offset(x: 35, y: -42)
            }
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .leading) {
            Capsule().fill(accent).frame(width: 4).padding(.vertical, 15)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(colorScheme == .dark ? 0.18 : 0.12), lineWidth: 0.8)
        }
        .shadow(color: accent.opacity(colorScheme == .dark ? 0.08 : 0.1), radius: 14, y: 7)
        .accessibilityElement(children: .combine)
    }

    private var contextBadge: some View {
        Label(item.context == .work ? "РАБОТА" : "ЛИЧНОЕ", systemImage: item.context.systemImage)
            .font(.system(size: 9, weight: .black))
            .tracking(0.7)
            .foregroundStyle(accent)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(accent.opacity(0.11), in: Capsule())
    }

    private var durationText: String {
        let minutes = max(1, Int(item.duration / 60))
        return minutes >= 60 ? "\(minutes / 60)ч \(minutes % 60 == 0 ? "" : "\(minutes % 60)м")" : "\(minutes) мин"
    }
}
