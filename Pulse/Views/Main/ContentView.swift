import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query private var mappings: [CalendarMapping]

    @State private var input = ""
    @State private var speech = SpeechRecognizerService()
    private let parser = NLPParserService()

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            PulseTheme.lightBackground
                .opacity(colorSchemeIsDark ? 0 : 1)
                .ignoresSafeArea()
            Color.black
                .opacity(colorSchemeIsDark ? 1 : 0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderContextBar()

                if appState.eventKit.accessState != .granted, !appState.isDemoMode {
                    accessBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                }

                TimelineView(
                    date: appState.selectedDate,
                    items: timelineItems,
                    mode: appState.contextMode,
                    privacyShieldEnabled: appState.privacyShieldEnabled,
                    onDropTask: scheduleTask,
                    onAddBuffer: addBuffer
                )

                inboxDock

                MagicInputBar(
                    text: $input,
                    isRecording: speech.isRecording,
                    onSubmit: submitInput,
                    onMicrophone: {
                        Task { await speech.toggle() }
                    }
                )
            }
        }
        .task { appState.loadEvents(mappings: mappings) }
        .onChange(of: appState.selectedDate) { _, _ in appState.loadEvents(mappings: mappings) }
        .onChange(of: appState.isDemoMode) { _, _ in appState.loadEvents(mappings: mappings) }
        .onChange(of: speech.transcript) { _, transcript in
            guard !transcript.isEmpty else { return }
            input = transcript
        }
        .sheet(isPresented: $appState.isInboxPresented) {
            TaskInboxSheet(tasks: inboxTasks, onComplete: completeTask, onDelete: deleteTask)
        }
        .sheet(isPresented: $appState.isSettingsPresented, onDismiss: {
            appState.loadEvents(mappings: mappings)
        }) {
            CalendarSetupView()
        }
        .alert("Не удалось выполнить действие", isPresented: errorBinding) {
            Button("Понятно", role: .cancel) { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "Неизвестная ошибка")
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    private var colorSchemeIsDark: Bool { colorScheme == .dark }

    private var timelineItems: [PulseItem] {
        (appState.systemEvents + tasks.compactMap(\.asPulseItem))
            .filter { Calendar.current.isDate($0.start, inSameDayAs: appState.selectedDate) }
            .sorted { $0.start < $1.start }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter { $0.scheduledStart == nil && !$0.isCompleted }
    }

    private var inboxDock: some View {
        HStack(spacing: 10) {
            Button {
                appState.isInboxPresented = true
            } label: {
                Label("Инбокс", systemImage: "tray.full.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            if inboxTasks.isEmpty {
                Text("Нет задач без времени")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(inboxTasks.prefix(4)) { task in
                            Text(task.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(PulseTheme.accent(for: task.context).opacity(0.12), in: Capsule())
                                .draggable(task.id.uuidString)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var accessBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .foregroundStyle(.orange)
            Text(appState.eventKit.accessState.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Подключить") { appState.isSettingsPresented = true }
                .font(.caption.weight(.semibold))
            Button("Демо") {
                seedDemoTasksIfNeeded()
                appState.enableDemo()
            }
            .font(.caption.weight(.semibold))
        }
        .padding(12)
        .background(.orange.opacity(0.1), in: .rect(cornerRadius: 14, style: .continuous))
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )
    }

    private func submitInput() {
        let source = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return }
        let parsed = parser.parse(source)
        input = ""
        speech.stop()

        if parsed.kind == .event, let start = parsed.start, appState.eventKit.accessState == .granted {
            do {
                let calendarID = mappings.first { $0.context == parsed.context }?.calendarIdentifier
                try appState.eventKit.createEvent(
                    title: parsed.title,
                    notes: source,
                    start: start,
                    durationMinutes: parsed.durationMinutes,
                    preferredCalendarIdentifier: calendarID
                )
                appState.selectedDate = start
                appState.loadEvents(mappings: mappings)
                HapticManager.success()
            } catch {
                appState.report(error)
            }
        } else {
            let task = TaskItem(
                title: parsed.title,
                details: source,
                durationMinutes: parsed.durationMinutes,
                context: parsed.context,
                scheduledStart: parsed.start
            )
            modelContext.insert(task)
            try? modelContext.save()
            if let start = parsed.start { appState.selectedDate = start }
            HapticManager.success()
        }
    }

    private func scheduleTask(id: UUID, at date: Date) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        task.scheduledStart = date
        try? modelContext.save()
    }

    private func completeTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        try? modelContext.save()
        HapticManager.success()
    }

    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func addBuffer(to item: PulseItem) {
        do {
            if item.source == .eventKit {
                try appState.eventKit.addBuffer(before: item)
                appState.loadEvents(mappings: mappings)
            } else if let task = tasks.first(where: { $0.id.uuidString == item.id }), let start = task.scheduledStart {
                task.scheduledStart = start.addingTimeInterval(10 * 60)
                try modelContext.save()
            }
            HapticManager.success()
        } catch {
            appState.report(error)
        }
    }

    private func seedDemoTasksIfNeeded() {
        guard tasks.isEmpty else { return }
        for (title, duration, context) in DemoData.inbox {
            modelContext.insert(TaskItem(title: title, durationMinutes: duration, context: context))
        }
        try? modelContext.save()
    }
}
