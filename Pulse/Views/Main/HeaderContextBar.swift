import SwiftUI

struct HeaderContextBar: View {
    @Environment(AppState.self) private var appState
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(appState.selectedDate.formatted(.dateTime.day().month(.wide)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    appState.privacyShieldEnabled.toggle()
                    HapticManager.selection()
                } label: {
                    Image(systemName: appState.privacyShieldEnabled ? "lock.fill" : "lock.open")
                        .frame(width: 38, height: 38)
                        .background(.thinMaterial, in: Circle())
                }
                .accessibilityLabel(appState.privacyShieldEnabled ? "Выключить защиту экрана" : "Включить защиту экрана")

                Button {
                    appState.isSettingsPresented = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 38, height: 38)
                        .background(.thinMaterial, in: Circle())
                }
                .accessibilityLabel("Настройки календарей")
            }

            dateStrip
            contextPicker
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var dateStrip: some View {
        HStack(spacing: 6) {
            ForEach(-3...3, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: .now) ?? .now
                let isSelected = calendar.isDate(date, inSameDayAs: appState.selectedDate)
                Button {
                    appState.selectedDate = date
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 5) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.semibold))
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.primary : Color.clear, in: .rect(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var contextPicker: some View {
        HStack(spacing: 4) {
            ForEach(ContextMode.allCases) { mode in
                Button {
                    appState.setContext(mode)
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(appState.contextMode == mode ? Color.primary.opacity(0.12) : .clear)
                        .clipShape(.rect(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

