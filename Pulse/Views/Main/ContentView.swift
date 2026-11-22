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
            PulseTheme.background(for: colorScheme).ignoresSafeArea()
            ambientBackground

            VStack(spacing: 0) {
                HeaderContextBar(
                    scheduledMinutes: visibleTimelineItems.reduce(0) { $0 + max(0, Int($1.duration / 60)) },
                    itemCount: visibleTimelineItems.count,
                    inboxCount: inboxTasks.count
                )

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

    private var timelineItems: [PulseItem] {
        (appState.systemEvents + tasks.compactMap(\.asPulseItem))
            .filter { Calendar.current.isDate($0.start, inSameDayAs: appState.selectedDate) }
            .sorted { $0.start < $1.start }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter { $0.scheduledStart == nil && !$0.isCompleted }
    }

    private var visibleTimelineItems: [PulseItem] {
        timelineItems.filter { appState.contextMode.includes($0.context) }
    }

    private var ambientBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(PulseTheme.work.opacity(colorScheme == .dark ? 0.09 : 0.055))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.35, y: -proxy.size.height * 0.32)
                Circle()
                    .fill(PulseTheme.personal.opacity(colorScheme == .dark ? 0.055 : 0.04))
                    .frame(width: proxy.size.width * 0.75)
                    .blur(radius: 80)
                    .offset(x: -proxy.size.width * 0.42, y: proxy.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var inboxDock: some View {
        HStack(spacing: 11) {
            Button {
                appState.isInboxPresented = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "tray.full.fill")
                    Text("\(inboxTasks.count)").monospacedDigit()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(inboxTasks.isEmpty ? Color.secondary : PulseTheme.work)
                .padding(.horizontal, 11).padding(.vertical, 9)
                .background(PulseTheme.work.opacity(inboxTasks.isEmpty ? 0.04 : 0.11), in: Capsule())
            }
            .buttonStyle(.plain)

            if inboxTasks.isEmpty {
                Text("Инбокс разобран")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(inboxTasks.prefix(4)) { task in
                            Text(task.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(PulseTheme.accent(for: task.context).opacity(0.12), in: Capsule())
                                .draggable(task.id.uuidString)
                        }
                    }
                }
            }
        }
        .padding(7)
        .background(PulseTheme.surface(for: colorScheme).opacity(0.94), in: .rect(cornerRadius: 19, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(.primary.opacity(0.055), lineWidth: 0.7) }
        .padding(.horizontal, 14)
        .padding(.top, 3)
    }

    private var accessBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(PulseTheme.amber.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: "calendar.badge.exclamationmark").font(.caption.bold()).foregroundStyle(PulseTheme.amber)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Календарь не подключён").font(.caption.weight(.bold))
                Text("Можно продолжить с демо-данными").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Демо") {
                seedDemoTasksIfNeeded()
                appState.enableDemo()
            }
            .font(.caption.weight(.bold)).buttonStyle(.bordered).tint(PulseTheme.work)
            Button { appState.isSettingsPresented = true } label: { Image(systemName: "arrow.right") }
                .buttonStyle(.plain).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(PulseTheme.surface(for: colorScheme), in: .rect(cornerRadius: 17, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(PulseTheme.amber.opacity(0.18), lineWidth: 0.8) }
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
