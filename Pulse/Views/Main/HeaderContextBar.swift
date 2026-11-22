import SwiftUI

struct HeaderContextBar: View {
    @Environment(AppState.self) private var appState
    let scheduledMinutes: Int
    let itemCount: Int
    let inboxCount: Int
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            topBar
            dayHero
            dateStrip
            contextPicker
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(PulseTheme.work.opacity(0.16)).frame(width: 34, height: 34)
                Circle().fill(PulseTheme.work).frame(width: 11, height: 11)
                    .shadow(color: PulseTheme.work.opacity(0.7), radius: 8)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("PULSE").font(.system(size: 14, weight: .black, design: .rounded)).tracking(1.8)
                Text(appState.selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }
            Spacer()
            PulseIconButton(
                systemName: appState.privacyShieldEnabled ? "lock.fill" : "lock.open",
                accessibilityTitle: appState.privacyShieldEnabled ? "Выключить защиту" : "Включить защиту",
                isActive: appState.privacyShieldEnabled
            ) {
                appState.privacyShieldEnabled.toggle()
                HapticManager.selection()
            }
            PulseIconButton(systemName: "slider.horizontal.3", accessibilityTitle: "Настройки") {
                appState.isSettingsPresented = true
            }
        }
    }

    private var dayHero: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(calendar.isDateInToday(appState.selectedDate) ? "СЕГОДНЯ" : "ПЛАН НА ДЕНЬ")
                    .font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(.white.opacity(0.72))
                Text(appState.selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(.white).textCase(.uppercase).minimumScaleFactor(0.72).lineLimit(1)
                Text(appState.selectedDate.formatted(.dateTime.day().month(.wide)))
                    .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.74))
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 10) {
                HStack(spacing: 6) {
                    metric(value: "\(itemCount)", label: "событий")
                    metric(value: durationText, label: "занято")
                }
                if inboxCount > 0 {
                    Label("\(inboxCount) в инбоксе", systemImage: "tray.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .padding(20)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: heroColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.white.opacity(0.12)).frame(width: 150, height: 150).offset(x: 55, y: -70)
                Circle().fill(.black.opacity(0.12)).frame(width: 110, height: 110).blur(radius: 16).offset(x: -220, y: 75)
            }
        }
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .shadow(color: (heroColors.first ?? .clear).opacity(0.28), radius: 20, y: 12)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(value).font(.system(.headline, design: .rounded, weight: .bold)).monospacedDigit()
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.65))
        }
        .foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 7)
        .background(.white.opacity(0.12), in: .rect(cornerRadius: 12, style: .continuous))
    }

    private var dateStrip: some View {
        HStack(spacing: 5) {
            ForEach(-3...3, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: appState.selectedDate) ?? appState.selectedDate
                let selected = calendar.isDate(date, inSameDayAs: appState.selectedDate)
                Button {
                    appState.selectedDate = date
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 6) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(selected ? .white.opacity(0.72) : .secondary)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 16, weight: .bold, design: .rounded)).monospacedDigit()
                            .foregroundStyle(selected ? .white : .primary)
                        Circle().fill(calendar.isDateInToday(date) ? PulseTheme.coral : .clear).frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(selected ? Color.primary.opacity(0.88) : .clear, in: .rect(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .pulseCard(cornerRadius: 20, shadow: false)
    }

    private var contextPicker: some View {
        HStack(spacing: 5) {
            ForEach(ContextMode.allCases) { mode in
                let selected = appState.contextMode == mode
                Button {
                    withAnimation(.snappy(duration: 0.28)) { appState.setContext(mode) }
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(.caption.weight(.bold)).foregroundStyle(selected ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selected ? pickerColor(for: mode) : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4).background(.primary.opacity(0.055), in: Capsule())
    }

    private var durationText: String {
        let hours = scheduledMinutes / 60
        let minutes = scheduledMinutes % 60
        if hours == 0 { return "\(minutes)м" }
        if minutes == 0 { return "\(hours)ч" }
        return "\(hours)ч \(minutes)м"
    }

    private var heroColors: [Color] {
        switch appState.contextMode {
        case .work: [PulseTheme.work, PulseTheme.workDeep]
        case .personal: [PulseTheme.personal, PulseTheme.personalDeep]
        case .all: [PulseTheme.work, Color(red: 92 / 255, green: 63 / 255, blue: 190 / 255)]
        }
    }

    private func pickerColor(for mode: ContextMode) -> Color {
        switch mode {
        case .all: .primary.opacity(0.88)
        case .work: PulseTheme.work
        case .personal: PulseTheme.personalDeep
        }
    }
}
