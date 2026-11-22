import EventKit
import SwiftData
import SwiftUI

struct CalendarSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var mappings: [CalendarMapping]

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: accessIcon)
                            .foregroundStyle(accessColor)
                        Text(appState.eventKit.accessState.explanation)
                            .font(.subheadline)
                    }
                    if appState.eventKit.accessState != .granted {
                        Button("Разрешить доступ к календарю") {
                            Task {
                                _ = await appState.eventKit.requestAccess()
                                appState.loadEvents(mappings: mappings)
                            }
                        }
                    }
                } header: {
                    Text("Доступ")
                }

                if appState.eventKit.accessState == .granted {
                    Section {
                        ForEach(appState.eventKit.availableCalendars(), id: \.calendarIdentifier) { calendar in
                            HStack {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(calendar.title)
                                Spacer()
                                Picker("Контекст", selection: mappingBinding(for: calendar)) {
                                    Text("Работа").tag(ContextMode.work)
                                    Text("Личное").tag(ContextMode.personal)
                                }
                                .labelsHidden()
                            }
                        }
                    } header: {
                        Text("Календари")
                    } footer: {
                        Text("Pulse использует это разделение для фильтров и защиты личных названий.")
                    }
                }

                Section("Оформление") {
                    Picker("Тема", selection: $appState.colorSchemePreference) {
                        Text("Системная").tag(0)
                        Text("Светлая").tag(1)
                        Text("Тёмная").tag(2)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var accessIcon: String {
        appState.eventKit.accessState == .granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    private var accessColor: Color {
        appState.eventKit.accessState == .granted ? .green : .orange
    }

    private func mappingBinding(for calendar: EKCalendar) -> Binding<ContextMode> {
        Binding {
            mappings.first { $0.calendarIdentifier == calendar.calendarIdentifier }?.context
                ?? EventKitService.inferContext(from: calendar)
        } set: { context in
            if let mapping = mappings.first(where: { $0.calendarIdentifier == calendar.calendarIdentifier }) {
                mapping.context = context
            } else {
                modelContext.insert(CalendarMapping(
                    calendarIdentifier: calendar.calendarIdentifier,
                    calendarTitle: calendar.title,
                    context: context
                ))
            }
            try? modelContext.save()
            HapticManager.selection()
        }
    }
}

